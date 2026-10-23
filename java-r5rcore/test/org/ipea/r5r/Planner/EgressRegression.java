package org.ipea.r5r.Planner;

import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.StreetSegment;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.profile.StreetPath;
import com.conveyal.r5.streets.*;
import com.conveyal.r5.transit.TransportNetwork;
import org.locationtech.jts.geom.Coordinate;

/** Physical fixtures independent of the POA regression outputs; run only in CI. */
public class EgressRegression {
    private static int checks;
    private static int failures;
    private static boolean baseline;

    private static void check(boolean condition, String message) {
        checks++;
        if (!condition) {
            failures++;
            System.err.println("FAIL: " + message);
        }
    }

    private static class Fixture extends StreetLayer {
        final Split split = new Split();
        final double destinationLat = 0.00009;
        final double destinationLon = 0.00891;
        Fixture() {
            vertexStore.addVertex(0, 0);
            vertexStore.addVertex(0, 0.009);
            vertexStore.addVertex(0.000036, 0.009);
            edgeStore.addStreetPair(0, 1, 1000000, 101);
            edgeStore.addStreetPair(1, 2, 4000, 102);
            for (int e = 0; e < 4; e++) {
                EdgeStore.Edge edge = edgeStore.getCursor(e);
                edge.setGeometry(new int[0]);
                edge.allowStreetMode(StreetMode.WALK);
                edge.allowStreetMode(StreetMode.CAR);
                edge.setFlag(EdgeStore.EdgeFlag.ALLOWS_WHEELCHAIR);
                edge.setSpeedKph(36);
            }
            buildEdgeLists();
            split.edge = 0; split.vertex0 = 0; split.vertex1 = 1;
            split.distance0_mm = 990000; split.distance1_mm = 10000;
            split.distanceToEdge_mm = 10000;
            split.fixedLat = 0;
            split.fixedLon = VertexStore.floatingDegreesToFixed(destinationLon);
            split.seg = 0; split.frac = 0.99;
        }
        @Override
        public Split findSplit(double lat, double lon, double radius, StreetMode mode) {
            return split;
        }
    }

    private static StreetRouter router(Fixture fixture, boolean asymmetric) {
        StreetRouter router = baseline ? new StreetRouter(fixture) : new R5REgressRouter(fixture);
        router.profileRequest.reverseSearch = true;
        router.profileRequest.walkSpeed = 1;
        router.streetMode = StreetMode.WALK;
        router.timeLimitSeconds = 2000;
        if (asymmetric) {
            router.timeCalculator = new BasicTraversalTimeCalculator(fixture, true) {
                @Override
                public int traversalTimeSeconds(EdgeStore.Edge edge, StreetMode mode,
                                                com.conveyal.r5.profile.ProfileRequest request) {
                    return (int) (edge.getLengthMm() / 1000) * (edge.getEdgeIndex() == 1 ? 2 : 1);
                }
            };
        }
        check(router.setOrigin(fixture.destinationLat, fixture.destinationLon), "origin linked");
        return router;
    }

    private static StreetSegment segment(StreetRouter router, StreetRouter.State state, Fixture fixture) {
        if (!baseline) return EgressPath.build(router, state, LegMode.WALK,
                fixture.destinationLat, fixture.destinationLon);
        TransportNetwork network = new TransportNetwork();
        network.streetLayer = fixture;
        return new StreetSegment(new StreetPath(state, network, true), LegMode.WALK, fixture);
    }

    private static void physicalCase(boolean asymmetric) {
        Fixture fixture = new Fixture();
        StreetRouter router = router(fixture, asymmetric);
        int expectedSeed = asymmetric ? 30 : 20;
        check(router.getStateAtVertex(1).getDurationSeconds() == expectedSeed,
                "near endpoint gets its own directed 10m partial and 10m off-street cost");
        check(router.getStateAtVertex(0).getDurationSeconds() == 1000,
                "far endpoint retains 990m plus 10m cost");
        router.route();
        StreetRouter.State state = router.getStateAtVertex(2);
        StreetSegment segment = segment(router, state, fixture);
        check(segment.duration == expectedSeed + 4, "known final leg is 24s (34s asymmetric)");
        check(segment.duration == state.getDurationSeconds(), "search and reconstructed cost agree");
        check(segment.distance == 24000, "complete final distance includes 4+10+10m");
        Coordinate end = segment.geometry.getCoordinateN(segment.geometry.getNumPoints() - 1);
        check(end.equals2D(new Coordinate(fixture.destinationLon, fixture.destinationLat)),
                "final geometry reaches requested destination");
        if (!baseline) {
            check(segment.streetEdges.size() == 2, "full approach edge and clipped terminal edge retained");
            check(segment.streetEdges.get(1).distance == 10000, "terminal edge distance clipped to 10m");
            check(segment.streetEdges.get(1).edgeId == 1, "terminal edge has actual travel direction");
        }
    }

    private static void limitsAndPermissions() {
        Fixture fixture = new Fixture();
        R5REgressRouter router = new R5REgressRouter(fixture);
        router.profileRequest.reverseSearch = true;
        router.profileRequest.walkSpeed = 1;
        router.timeLimitSeconds = 19;
        check(!router.setOrigin(fixture.destinationLat, fixture.destinationLon),
                "origin seeds over the complete walking limit are discarded");
        router.timeLimitSeconds = 20;
        check(router.setOrigin(fixture.destinationLat, fixture.destinationLon), "exact walking limit admitted");
        check(router.getStateAtVertex(1).getDurationSeconds() == 20, "exact limit seed cost");
        fixture.edgeStore.getCursor(1).clearFlag(EdgeStore.EdgeFlag.ALLOWS_PEDESTRIAN);
        router.timeLimitSeconds = 2000;
        check(router.setOrigin(fixture.destinationLat, fixture.destinationLon), "permitted far endpoint remains");
        check(router.getStateAtVertex(1) == null, "disallowed directed partial is not seeded");
    }

    private static void zeroAndCurvedPartials() {
        Fixture fixture = new Fixture();
        fixture.split.distance0_mm = 1000000;
        fixture.split.distance1_mm = 0;
        fixture.split.distanceToEdge_mm = 0;
        fixture.split.fixedLon = VertexStore.floatingDegreesToFixed(0.009);
        fixture.split.frac = 1;
        StreetRouter router = router(fixture, false);
        StreetSegment segment = EgressPath.build(router, router.getStateAtVertex(1), LegMode.WALK, 0, 0.009);
        check(segment.duration == 0 && segment.distance == 0, "point exactly at vertex has zero connection cost");
        check(segment.geometry.getNumPoints() == 2, "zero connection remains a valid LINESTRING");

        fixture = new Fixture();
        fixture.edgeStore.getCursor(0).setGeometry(new int[]{
                VertexStore.floatingDegreesToFixed(0.001), VertexStore.floatingDegreesToFixed(0.004)});
        fixture.split.seg = 1;
        router = router(fixture, false);
        segment = EgressPath.build(router, router.getStateAtVertex(0), LegMode.WALK,
                fixture.destinationLat, fixture.destinationLon);
        check(segment.geometry.getNumPoints() == 4, "curved partial retains intermediate point and off-street link");
        check(segment.streetEdges.get(0).distance == 990000, "far-end partial uses its own length");
        check(segment.streetEdges.get(0).geometry.getNumPoints() == 3, "partial geometry clipped at split");
    }

    public static void main(String[] args) {
        baseline = args.length > 0 && args[0].equals("--baseline");
        physicalCase(false);
        physicalCase(true);
        if (!baseline) {
            limitsAndPermissions();
            zeroAndCurvedPartials();
        }
        System.out.printf("EGRESS_REGRESSION checks=%d failures=%d baseline=%s%n", checks, failures, baseline);
        if (failures > 0) throw new AssertionError("Incomplete or incorrectly costed egress path");
    }
}
