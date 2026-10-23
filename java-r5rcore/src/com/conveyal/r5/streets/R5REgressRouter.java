package com.conveyal.r5.streets;

/**
 * Point-origin reverse search for detailed itineraries, pending an upstream R5 correction.
 * This deliberately lives in R5's streets package to initialize its package-private queue
 * and best-state map, without reflection or replacing any upstream class. Recheck on R5 upgrades.
 * Only single-mode point-seeded egress uses this adapter; chained-mode searches are unchanged.
 */
public final class R5REgressRouter extends StreetRouter {
    public R5REgressRouter(StreetLayer layer) {
        super(layer);
    }

    @Override
    public boolean setOrigin(double lat, double lon) {
        if (!profileRequest.reverseSearch) {
            throw new IllegalStateException("R5REgressRouter requires a reverse search");
        }
        // Keep R5's snapping, origin coordinates and heuristic initialization.
        if (!super.setOrigin(lat, lon)) return false;
        Split split = getOriginSplit();
        queue.clear();
        bestStatesAtEdge.clear();
        seed(split.vertex0, split.edge, split.distance0_mm, split.distanceToEdge_mm);
        seed(split.vertex1, split.edge + 1, split.distance1_mm, split.distanceToEdge_mm);
        return !queue.isEmpty();
    }

    private void seed(int vertex, int edgeId, int partialMm, int offStreetMm) {
        EdgeStore.Edge edge = streetLayer.edgeStore.getCursor(edgeId);
        // Probe a complete traversal to apply the same directional permissions, wheelchair
        // rules, bike-walking fallback and cost calculator as ordinary street traversal.
        State probe = edge.traverse(new State(edge.getToVertex(), -1, streetMode),
                streetMode, profileRequest, timeCalculator);
        if (probe == null) return;
        State seed = new State(vertex, edgeId, probe.streetMode);
        // R5 v7.6 represents elevation/raster adjustments as an average factor per directed
        // edge, and TraversalTimeCalculator documents scaling full-edge times for splits.
        // This preserves that model; it does not integrate a new partial elevation profile.
        int partialSeconds = partialMm == 0 ? 0 : (int) Math.ceil(
                probe.getDurationSeconds() * (partialMm / (double) edge.getLengthMm()));
        int offStreetSeconds = (int) Math.ceil(offStreetMm / (1000d * profileRequest.walkSpeed));
        seed.incrementTimeInSeconds((long) partialSeconds + offStreetSeconds);
        seed.distance = partialMm + offStreetMm;
        if (timeLimitSeconds > 0 && seed.getDurationSeconds() > timeLimitSeconds) return;
        streetLayer.edgeStore.startTurnRestriction(seed.streetMode, true, seed);
        queue.add(seed);
        bestStatesAtEdge.put(edgeId, seed);
    }
}
