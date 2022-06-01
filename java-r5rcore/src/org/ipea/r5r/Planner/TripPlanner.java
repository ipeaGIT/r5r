package org.ipea.r5r.Planner;

import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.StreetSegment;
import com.conveyal.r5.profile.*;
import com.conveyal.r5.streets.StreetRouter;
import com.conveyal.r5.transit.TransportNetwork;
import gnu.trove.iterator.TIntObjectIterator;
import gnu.trove.map.TIntIntMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Point to point trip planner, based on Conveyal's PointToPointQuery and ParetoServer
 */
public class TripPlanner {
    private static final Logger LOG = LoggerFactory.getLogger(TripPlanner.class);

    private String fromId;
    private String toId;

    private final TransportNetwork transportNetwork;
    private final ProfileRequest request;

    public void setOD(String fromId, String toId) {
        this.fromId = fromId;
        this.toId = toId;
    }

    public TripPlanner(TransportNetwork transportNetwork, ProfileRequest request) {
        this.transportNetwork = transportNetwork;
        this.request = request;
    }

    //Does point to point routing with data from request
    public List<Trip> plan() {

        // find direct paths
        Map<String, Trip> trips = new HashMap<>();

        findDirectPaths(request, trips);

        if (request.hasTransit()) {
            // Find access paths and times
            Map<LegMode, StreetRouter> accessRouter = findAccessPaths(request);
            Map<LegMode, StreetRouter> egressRouter = findEgressPaths(request);

            Map<LegMode, TIntIntMap> accessTimes = accessRouter.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().getReachedStops()));
            Map<LegMode, TIntIntMap> egressTimes = egressRouter.entrySet().stream()
                    .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().getReachedStops()));

            // Build RAPTOR router
            McRaptorSuboptimalPathProfileRouter router = new McRaptorSuboptimalPathProfileRouter(transportNetwork,
                    request, accessTimes, egressTimes, (t)->new SuboptimalDominatingList(request.suboptimalMinutes),
                    null, true);

            router.route();

            for (TIntObjectIterator<Collection<McRaptorSuboptimalPathProfileRouter.McRaptorState>> it =
                 router.finalStatesByDepartureTime.iterator(); it.hasNext();) {
                it.advance();

                int departureTime = it.key();

                for (McRaptorSuboptimalPathProfileRouter.McRaptorState state : it.value()) {
                    Trip newTrip = new Trip(state, departureTime, transportNetwork, request);
                    newTrip.setOD(fromId, toId, request);

                    if (!trips.containsKey(newTrip.getKey()) ||
                            trips.get(newTrip.getKey()).getTotalDurationSeconds() > newTrip.getTotalDurationSeconds()) {
                        trips.put(newTrip.getKey(), newTrip);
                    }
                }
            }

            for (Trip trip : trips.values()) {
                trip.augment(accessRouter, egressRouter, transportNetwork, request);
            }
        }

        return new ArrayList<>(trips.values());
    }


    /**
     * Finds direct paths between from and to coordinates in request and adds them to option
     */
    private void findDirectPaths(ProfileRequest request, Map<String, Trip> trips) {
        request.reverseSearch = false;
        //For direct modes
        for(LegMode mode: request.directModes) {
            StreetRouter streetRouter = new StreetRouter(transportNetwork.streetLayer);
            StreetPath streetPath;
            streetRouter.profileRequest = request;
            streetRouter.streetMode = StreetMode.valueOf(mode.toString());
            streetRouter.timeLimitSeconds = request.streetTime * 60;
            if(streetRouter.setOrigin(request.fromLat, request.fromLon)) {
                if(!streetRouter.setDestination(request.toLat, request.toLon)) {
                    LOG.warn("Direct mode {} destination wasn't found!", mode);
                    continue;
                }
                streetRouter.route();
                StreetRouter.State lastState = streetRouter.getState(streetRouter.getDestinationSplit());
                if (lastState == null) {
                    LOG.warn("Direct mode {} last state wasn't found", mode);
                    continue;
                }
                streetPath = new StreetPath(lastState, transportNetwork, false);
            } else {
                LOG.warn("Direct mode {} origin wasn't found!", mode);
                continue;
            }

            StreetSegment streetSegment = new StreetSegment(streetPath, mode,
                    transportNetwork.streetLayer);

            LOG.info("adding direct mode {}", mode);
            Trip trip = Trip.newDirectTrip(request.fromTime, mode.toString(), streetSegment);
            trip.setOD(fromId, toId, request);
            // the key for a direct trip is the name of the mode
            trips.put(mode.toString(), trip);
        }
    }

    /**
     * Finds access paths from from coordinate in request and adds all routers with paths to accessRouter map
     * @param request
     */
    private HashMap<LegMode, StreetRouter> findAccessPaths(ProfileRequest request) {
        request.reverseSearch = false;
        // Routes all access modes
        HashMap<LegMode, StreetRouter> accessRouter = new HashMap<>();
        for(LegMode mode: request.accessModes) {
            StreetRouter streetRouter = new StreetRouter(transportNetwork.streetLayer);
            streetRouter.profileRequest = request;
            streetRouter.streetMode = StreetMode.valueOf(mode.toString());

            //Gets correct maxCar/Bike/Walk time in seconds for access leg based on mode since it depends on the mode
            streetRouter.timeLimitSeconds = request.getMaxTimeSeconds(mode);
            streetRouter.transitStopSearch = true;
            streetRouter.quantityToMinimize = StreetRouter.State.RoutingVariable.DURATION_SECONDS;

            if(streetRouter.setOrigin(request.fromLat, request.fromLon)) {
                streetRouter.route();
                //Searching for access paths
                accessRouter.put(mode, streetRouter);
            } else {
                LOG.warn("MODE:{}, Edge near the origin coordinate wasn't found. Routing didn't start!", mode);
            }
        }

        return accessRouter;
    }

    /**
     * Finds all egress paths from to coordinate to end stop and adds routers to egressRouter
     * @param request
     */
    private Map<LegMode, StreetRouter> findEgressPaths(ProfileRequest request) {
        Map<LegMode, StreetRouter> egressRouter = new HashMap<>();
        //For egress
        //TODO: this must be reverse search
        request.reverseSearch = true;
        for(LegMode mode: request.egressModes) {
            StreetRouter streetRouter = new StreetRouter(transportNetwork.streetLayer);
            streetRouter.transitStopSearch = true;
            streetRouter.quantityToMinimize = StreetRouter.State.RoutingVariable.DURATION_SECONDS;

            //TODO: add support for bike sharing
            streetRouter.streetMode = StreetMode.valueOf(mode.toString());
            streetRouter.profileRequest = request;
            streetRouter.timeLimitSeconds = request.getMaxTimeSeconds(mode);
            if(streetRouter.setOrigin(request.toLat, request.toLon)) {
                streetRouter.route();
                TIntIntMap stops = streetRouter.getReachedStops();
                egressRouter.put(mode, streetRouter);
                LOG.info("Added {} egress stops for mode {}",stops.size(), mode);

            } else {
                LOG.warn("MODE:{}, Edge near the origin coordinate wasn't found. Routing didn't start!", mode);
            }
        }

        return egressRouter;
    }

}
