package org.ipea.r5r.Planner;

import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.ProfileOption;
import com.conveyal.r5.api.util.StreetSegment;
import com.conveyal.r5.api.util.Transfer;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.profile.ProfileRequest;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.profile.StreetPath;
import com.conveyal.r5.streets.StreetRouter;
import com.conveyal.r5.streets.VertexStore;
import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import org.apache.commons.collections4.map.MultiKeyMap;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.LineString;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.function.Predicate;
import java.util.stream.Collectors;

import static com.conveyal.r5.transit.TransitLayer.TRANSFER_DISTANCE_LIMIT_METERS;

public class Trip {
    private static final Logger LOG = LoggerFactory.getLogger(Trip.class);

    private boolean isDirect = false;

    // origin-destination
    private String fromId;
    private double fromLat;

    public int getDepartureTime() {
        return departureTime;
    }

    public int getTotalDurationSeconds() {
        return totalDurationSeconds;
    }

    public double getTotalDistance() {
        return totalDistance;
    }

    public int getTotalFare() {
        return totalFare;
    }

    public List<TripLeg> getLegs() {
        return legs;
    }

    private double fromLon;

    private String toId;
    private double toLat;
    private double toLon;

    public void setOD(String fromId, String toId, ProfileRequest request) {
        this.fromId = fromId;
        this.fromLat = request.fromLat;
        this.fromLon = request.fromLon;

        this.toId = toId;
        this.toLat = request.toLat;
        this.toLon = request.toLon;
    }

    private int departureTime;
    private int totalDurationSeconds;
    private double totalDistance;
    private int totalFare;

    private final List<TripLeg> legs;

    public String getKey() {
        if (isDirect) {
            return legs.iterator().next().getMode();
        } else {
            return legs.stream().map(TripLeg::getRoute).
                    filter(Predicate.not(String::isEmpty)).
                    collect(Collectors.joining(", "));
        }
    }

    public Trip() {
        legs = new ArrayList<>();
    }

    public void addLeg(TripLeg leg) {
        legs.add(leg);
    }

    public static Trip newDirectTrip(int departureTime, String mode, StreetSegment streetSegment) {
        Trip trip = new Trip();
        trip.isDirect = true;
        trip.departureTime = departureTime;
        trip.totalDurationSeconds = streetSegment.duration;
        trip.totalDistance = streetSegment.distance;
        trip.totalFare = 0;

        trip.addLeg(TripLeg.newDirectLeg(mode, streetSegment));

        return trip;
    }

    public Trip(McRaptorSuboptimalPathProfileRouter.McRaptorState state,
                int departureTime, TransportNetwork network, ProfileRequest request) {
        this.departureTime = departureTime;
        this.totalDurationSeconds = state.time - departureTime;
        this.totalFare = state.fare != null ? state.fare.cumulativeFarePaid : 0;

        legs = new ArrayList<>();

        try {
            loadTransitLegs(state, network, request);
            Collections.reverse(legs);
        } catch (Exception e) {
            LOG.error("error loading legs");
            e.printStackTrace();
        }
    }

    public void augment(Map<LegMode, StreetRouter> accessRouter, Map<LegMode, StreetRouter> egressRouter,
                        TransportNetwork network, ProfileRequest request) {

        Map<Integer, StreetSegment> accessPaths = new HashMap<>();
        Map<Integer, StreetSegment> egressPaths = new HashMap<>();
        MultiKeyMap<Integer, StreetSegment> transferPaths = new MultiKeyMap<>();


        if (!isDirect) {
            // add access and egress legs
            addAccessPath(accessRouter, accessPaths, network, request);
            addEgressPath(egressRouter, egressPaths, network, request);

            for (TripLeg leg : legs) {
                leg.augmentTransitLeg(transferPaths, network, request);
            }
//        addTransferPath();
        }
    }



    private void loadTransitLegs(McRaptorSuboptimalPathProfileRouter.McRaptorState state,
                                 TransportNetwork network, ProfileRequest request) {
        while (state != null) {
            if (state.stop != -1 && (state.pattern != -1 || state.back != null)) {
                if (state.pattern == -1) {

                    int originTime = state.back.time;
                    int destTime = state.time;
                    int fare = state.fare != null ? state.fare.cumulativeFarePaid : 0;

                    int destStopIndex = state.stop;
                    int originStopIndex = state.back.stop;

                    LineString geom = GeometryUtils.geometryFactory.createLineString(new Coordinate[0]);

                    Coordinate originStopCoord = network.transitLayer.getCoordinateForStopFixed(originStopIndex);
                    Coordinate destStopCoord = network.transitLayer.getCoordinateForStopFixed(destStopIndex);

                    if (originStopIndex != destStopIndex & originStopCoord != null & destStopCoord != null) {
                        geom = GeometryUtils.geometryFactory.createLineString(new Coordinate[]{
                                new Coordinate(originStopCoord.getX() / VertexStore.FIXED_FACTOR, originStopCoord.getY() / VertexStore.FIXED_FACTOR),
                                new Coordinate(destStopCoord.getX() / VertexStore.FIXED_FACTOR, destStopCoord.getY() / VertexStore.FIXED_FACTOR),
                        });



                        //// FIND STREET PATH BETWEEN STOPS

                        //Groups transfers on alight stop so that StreetRouter is called only once per start stop
/*
                        //LOG.info("Filling middle paths");
                        boolean prevReverseSearch = request.reverseSearch;
                        request.reverseSearch = false;
                        StreetRouter streetRouter = new StreetRouter(network.streetLayer);
                        streetRouter.streetMode = StreetMode.WALK;
                        streetRouter.profileRequest = request;
                        //TODO: make configurable distanceLimitMeters in middle
                        streetRouter.distanceLimitMeters = TRANSFER_DISTANCE_LIMIT_METERS;

                        int stopVertexId = network.transitLayer.streetVertexForStop.get(originStopIndex);
                        streetRouter.setOrigin(stopVertexId);

//                        streetRouter.setOrigin(originStopCoord.getY() / VertexStore.FIXED_FACTOR,
//                                originStopCoord.getX() / VertexStore.FIXED_FACTOR);

                        streetRouter.setDestination(destStopCoord.getY() / VertexStore.FIXED_FACTOR,
                                destStopCoord.getX() / VertexStore.FIXED_FACTOR);

                        streetRouter.route();

                        stopVertexId = network.transitLayer.streetVertexForStop.get(destStopIndex);

                        StreetRouter.State lastState = streetRouter.getStateAtVertex(stopVertexId); //streetRouter.getState();
                        if (lastState != null) {
                            StreetPath streetPath = new StreetPath(lastState, network, false);
                            StreetSegment streetSegment = new StreetSegment(streetPath, LegMode.WALK, network.streetLayer);
                            geom = streetSegment.geometry;
                        }

                        request.reverseSearch = prevReverseSearch; */
                    }


                    TripLeg leg = TripLeg.newTransferLeg(StreetMode.WALK.toString(),destTime - originTime, fare, geom);

                    leg.setODStops(originStopIndex, destStopIndex);

                    legs.add(leg);

                } else {
                    TripPattern pattern = network.transitLayer.tripPatterns.get(state.pattern);

                    int boardStopIndex = pattern.stops[state.boardStopPosition];
                    int alightStopIndex = pattern.stops[state.alightStopPosition];

//                    List<Coordinate> coords = new ArrayList<>();
//                    List<LineString> hops = pattern.getHopGeometries(network.transitLayer);
//                    for (int i = state.boardStopPosition; i < state.alightStopPosition; i++) { // hop i is from stop i to i + 1, don't include last stop index
//                        LineString hop = hops.get(i);
//                        coords.addAll(Arrays.asList(hop.getCoordinates()));
//                    }
//                    LineString shape = GeometryUtils.geometryFactory.createLineString(coords.toArray(new Coordinate[0]));

                    RouteInfo route = network.transitLayer.routes.get(pattern.routeIndex);
                    String mode = TransitLayer.getTransitModes(route.route_type).toString();

                    int fare = state.fare != null ? state.fare.cumulativeFarePaid : 0;
                    TripLeg leg = TripLeg.newTransitLeg(mode, state.time - state.boardTime,
                            fare, 0, boardStopIndex, alightStopIndex, route.route_id);

                    leg.setPatternData(pattern, state.boardStopPosition, state.alightStopPosition);

                    legs.add(leg);
                }

            }
            state = state.back;
        }
    }

    private void addAccessPath(Map<LegMode, StreetRouter> accessRouter, Map<Integer, StreetSegment> accessPaths,
                               TransportNetwork network, ProfileRequest request) {
        TripLeg leg = legs.get(0);

        int startStopIndex = leg.getBoardStop();
        int startVertexStopIndex = network.transitLayer.streetVertexForStop.get(startStopIndex);

        //LOG.info("Filling response access paths:");
        //TODO: update this so that each stopIndex and mode pair is changed to streetpath only once
        LegMode accessMode = request.accessModes.iterator().next();
        if (accessMode != null) {

            StreetSegment streetSegment = accessPaths.get(startVertexStopIndex);
            if (streetSegment == null) {
//                int accessPathIndex = profileOption.getAccessIndex(accessMode, startVertexStopIndex);
//                if (accessPathIndex < 0) {
                //Here accessRouter needs to have this access mode since stopModeAccessMap is filled from accessRouter
                StreetRouter streetRouter = accessRouter.get(accessMode);
                //FIXME: Must we really update this on every streetrouter?
                streetRouter.profileRequest.reverseSearch = false;
                StreetRouter.State streetState = streetRouter.getStateAtVertex(startVertexStopIndex);
                if (streetState != null) {
                    StreetPath streetPath;

                    streetPath = new StreetPath(streetState, network, false);

                    streetSegment = new StreetSegment(streetPath, accessMode, network.streetLayer);

                    TripLeg accessLeg = TripLeg.newTransferLeg(accessMode.toString(),
                            streetSegment.duration, 0, streetSegment.geometry);
                    legs.add(0, accessLeg);

                    accessPaths.put(startVertexStopIndex, streetSegment);
                } else {
                    LOG.warn("Access: Last state not found for mode:{} stop:{}({})", accessMode, startVertexStopIndex, startStopIndex);
                }
            } else {
                TripLeg accessLeg = TripLeg.newTransferLeg(accessMode.toString(),
                        streetSegment.duration, 0, streetSegment.geometry);
                legs.add(0, accessLeg);

                accessPaths.put(startVertexStopIndex, streetSegment);
            }
//                        profileOption.addAccess(streetSegment, accessMode, startVertexStopIndex);
                //This should never happen since stopModeAccessMap is filled from reached stops in accessRouter
//                }
        } else {
            LOG.warn("Mode is not in stopModeAccessMap for start stop:{}({})", startVertexStopIndex, startStopIndex);
        }
    }

    private void addEgressPath(Map<LegMode, StreetRouter> egressRouter, Map<Integer, StreetSegment> egressPaths,
                               TransportNetwork network, ProfileRequest request) {
        TripLeg leg = legs.get(legs.size() - 1);

        int endStopIndex = leg.getAlightStop(); // currentTransitPath.alightStops[currentTransitPath.length-1];
        int endVertexStopIndex = network.transitLayer.streetVertexForStop.get(endStopIndex);

        //LOG.info("Filling response EGRESS paths:");
        LegMode egressMode = request.egressModes.iterator().next();
        if (egressMode != null) {
            //Here egressRouter needs to have this egress mode since stopModeEgressMap is filled from egressRouter
            StreetSegment streetSegment = egressPaths.get(endVertexStopIndex);
            if (streetSegment == null) {
                StreetRouter streetRouter = egressRouter.get(egressMode);
                //FIXME: Must we really update this on every streetrouter?
                streetRouter.profileRequest.reverseSearch = true;
                StreetRouter.State streetState = streetRouter.getStateAtVertex(endVertexStopIndex);
                if (streetState != null) {
                    StreetPath streetPath = new StreetPath(streetState, network, true);
                    streetSegment = new StreetSegment(streetPath, egressMode, network.streetLayer);
//                profileOption.addEgress(streetSegment, egressMode, endVertexStopIndex);
                    //This should never happen since stopModeEgressMap is filled from reached stops in egressRouter

                    TripLeg egressLeg = TripLeg.newTransferLeg(egressMode.toString(),
                            streetSegment.duration, 0, streetSegment.geometry);
                    legs.add(egressLeg);
                } else {
                    LOG.warn("EGRESS: Last state not found for mode:{} stop:{}({})", egressMode, endVertexStopIndex, endStopIndex);
                }
            } else {
                TripLeg egressLeg = TripLeg.newTransferLeg(egressMode.toString(),
                        streetSegment.duration, 0, streetSegment.geometry);
                legs.add(egressLeg);
                egressPaths.put(endVertexStopIndex, streetSegment);
            }

        } else {
            LOG.warn("Mode is not in stopModeEgressMap for END stop:{}({})", endVertexStopIndex, endStopIndex);
        }
    }

}

