package org.ipea.r5r.Process;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.cluster.TravelTimeResult;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.path.RouteSequence;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Multimap;
import org.ipea.r5r.R5.R5TravelTimeComputer;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Field;
import java.text.ParseException;
import java.util.*;
import java.util.concurrent.ForkJoinPool;

import static com.google.common.base.Preconditions.checkState;

public class TravelTimeMatrixComputer extends R5Process {

    class PathBreakdown {
        String departureTime;

        public double roundTo1Place(double value) {
            return Math.round(value * 10.0) / 10.0;
        }

        public double getAccessTime() {
            return roundTo1Place(accessTime);
        }

        public double getWaitTime() {
            return roundTo1Place(waitTime);
        }

        public double getRideTime() {
            return roundTo1Place(rideTime);
        }

        public double getTransferTime() {
            return roundTo1Place(transferTime);
        }

        public double getEgressTime() {
            return roundTo1Place(egressTime);
        }

        public double getTotalTime() {
            return roundTo1Place(totalTime);
        }

        public double getCombinedTravelTime() {
            return roundTo1Place(getAccessTime() + getWaitTime() + getRideTime() + getTransferTime() + getEgressTime());
        }

        double accessTime;
        double waitTime;
        double rideTime;
        double transferTime;
        double egressTime;
        double totalTime;

        String routes;
        int nRides;

        public void unreachable() {
            this.departureTime = "";

            this.accessTime = 0;
            this.waitTime = 0;
            this.rideTime = 0;
            this.transferTime = 0;
            this.egressTime = 0;
            this.totalTime = Integer.MAX_VALUE;

            this.routes = directModes.toString();
            this.nRides = 0;
        }
    }

    private static final Logger LOG = LoggerFactory.getLogger(TravelTimeMatrixComputer.class);

    @Override
    protected boolean isOneToOne() {
        return false;
    }

    public TravelTimeMatrixComputer(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        TravelTimeComputer computer = new R5TravelTimeComputer(request, transportNetwork);
        OneOriginResult travelTimeResults = computer.computeTravelTimes();
        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index], 10);
        populateDataFrame(travelTimeResults, travelTimesTable);

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable;
        } else {
            return null;
        }
    }

    private void populateDataFrame(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        if (this.routingProperties.expandedTravelTimes) {
            populateExpandedResults(travelTimeResults, travelTimesTable);
        } else {
            populateRegularResults(travelTimeResults, travelTimesTable);
        }
    }

    private void populateRegularResults(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            if (travelTimeResults.travelTimes.getValues()[0][destination] <= maxTripDuration) {

                // add new row to data frame
                travelTimesTable.append();

                // set destination id
                travelTimesTable.set("to_id", toIds[destination]);

                // set percentiles
                for (int p = 0; p < this.routingProperties.percentiles.length; p++) {
                    int tt = travelTimeResults.travelTimes.getValues()[p][destination];
                    String ps = String.format("%02d", this.routingProperties.percentiles[p]);
                    if (tt <= maxTripDuration) {
                        travelTimesTable.set("travel_time_p" + ps, tt);
                    }
                }
            }
        }
    }

    private void populateExpandedResults(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        // extract travel paths, if required
        Multimap<Integer, PathBreakdown>[] pathBreakdown = extractPathResults(travelTimeResults.paths, travelTimeResults.travelTimes);

        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            // fill travel details for destination
            populateTravelTimesBreakdown(travelTimesTable, pathBreakdown, destination);
        }
    }

    private Multimap<Integer, PathBreakdown>[] extractPathResults(PathResult paths, TravelTimeResult travelTimes) {
        try {
            // Create Field object
            Field privateField = PathResult.class.getDeclaredField("iterationsForPathTemplates");
            // Set the accessibility as true
            privateField.setAccessible(true);
            // Store the value of private field in variable
            Multimap<RouteSequence, PathResult.Iteration>[] iterationMaps = (Multimap<RouteSequence, PathResult.Iteration>[])privateField.get(paths);

            Multimap<Integer, PathBreakdown>[] pathResults = new Multimap[nDestinations];

            for (int d = 0; d < nDestinations; d++) {
                pathResults[d] = ArrayListMultimap.create();

                Multimap<RouteSequence, PathResult.Iteration> iterationMap = iterationMaps[d];
                if (iterationMap != null) {

                    for (RouteSequence routeSequence : iterationMap.keySet()) {
                        Collection<PathResult.Iteration> iterations = iterationMap.get(routeSequence);
                        int nIterations = iterations.size();
                        checkState(nIterations > 0, "A path was stored without any iterations");

                        // extract the route id's
                        String[] path = routeSequence.detailsWithGtfsIds(this.transportNetwork.transitLayer);

                        for (PathResult.Iteration iteration : iterations) {
                            PathBreakdown breakdown = new PathBreakdown();
                            breakdown.departureTime = Utils.getTimeFromSeconds(iteration.departureTime);
                            breakdown.accessTime = routeSequence.stopSequence.access == null ? 0 : routeSequence.stopSequence.access.time / 60.0f;
                            breakdown.waitTime = iteration.waitTimes.sum() / 60.0f;
                            breakdown.rideTime = routeSequence.stopSequence.rideTimesSeconds == null ? 0 : routeSequence.stopSequence.rideTimesSeconds.sum() / 60.0f;
                            breakdown.transferTime = routeSequence.stopSequence.transferTime(iteration) / 60f;
                            breakdown.egressTime = routeSequence.stopSequence.egress == null ? 0 : routeSequence.stopSequence.egress.time / 60.0f;
                            breakdown.totalTime = iteration.totalTime / 60.0f;

                            breakdown.routes = path[0];
                            breakdown.nRides = routeSequence.stopSequence.rideTimesSeconds == null ? 0 : routeSequence.stopSequence.rideTimesSeconds.size();

                            if (iteration.departureTime == 0) {
                                breakdown.departureTime = "";
                                breakdown.routes = this.directModes.toString();
                            }

                            pathResults[d].put(iteration.departureTime, breakdown);
                        }
                    }
                } else {
                    // if iteration map for this destination is null, add possible direct route if shorter than max trip duration
                    if (travelTimes.getValues()[0][d] <= this.maxTripDuration) {
                        PathBreakdown breakdown = new PathBreakdown();
                        breakdown.departureTime = "";
                        breakdown.routes = this.directModes.toString();
                        breakdown.totalTime = travelTimes.getValues()[0][d];
                        pathResults[d].put(0, breakdown);
                    }
                }
            }

            return pathResults;

        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
            return null;
        }
    }

    private void populateTravelTimesBreakdown(RDataFrame travelTimesTable, Multimap<Integer, PathBreakdown>[] pathBreakdown, int destination) {
        if (this.routingProperties.expandedTravelTimes & pathBreakdown != null) {
            if (!pathBreakdown[destination].isEmpty()) {
                for (int departure = secondsFromMidnight;
                     departure < secondsFromMidnight + (routingProperties.timeWindowSize * 60);
                     departure += 60) {

                    // get recorded paths
                    Collection<PathBreakdown> pathCollection = pathBreakdown[destination].get(departure);

                    int monteCarloDrawsForPath = 0;
                    for (PathBreakdown path : pathCollection) {
                        monteCarloDrawsForPath++;
                        addPathToDataframe(travelTimesTable, destination, monteCarloDrawsForPath, path);
                    }

                    int monteCarloDrawsPerMinute;
                    if (this.transportNetwork.transitLayer.hasFrequencies) {
                        monteCarloDrawsPerMinute = routingProperties.numberOfMonteCarloDraws / routingProperties.timeWindowSize;
                    } else {
                        monteCarloDrawsPerMinute = 1;
                    }

                    if (monteCarloDrawsForPath < monteCarloDrawsPerMinute) {
                        Collection<PathBreakdown> directPaths = pathBreakdown[destination].get(0);

                        PathBreakdown directPath;
                        if (!directPaths.isEmpty()) {
                            directPath = directPaths.iterator().next();
                        } else {
                            directPath = new PathBreakdown();
                            directPath.unreachable();
                        }

                        for (int mc = monteCarloDrawsForPath + 1; mc <= monteCarloDrawsPerMinute; mc++) {
                            directPath.departureTime = Utils.getTimeFromSeconds(departure);
                            addPathToDataframe(travelTimesTable, destination, mc, directPath);
                        }
                    }
                }
            }
        }
    }

    private void addPathToDataframe(RDataFrame travelTimesTable, int destination, int monteCarloDrawsForPath, PathBreakdown path) {
        travelTimesTable.append();

        // set destination id
        travelTimesTable.set("to_id", toIds[destination]);
        travelTimesTable.set("draw_number", monteCarloDrawsForPath);

        travelTimesTable.set("departure_time", path.departureTime);
        travelTimesTable.set("routes", path.routes);
        travelTimesTable.set("total_time", path.getCombinedTravelTime() > 0 ? path.getCombinedTravelTime() : path.getTotalTime());

        if (routingProperties.travelTimesBreakdown) {
            travelTimesTable.set("access_time", path.getAccessTime());
            travelTimesTable.set("wait_time", path.getWaitTime());
            travelTimesTable.set("ride_time", path.getRideTime());
            travelTimesTable.set("transfer_time", path.getTransferTime());
            travelTimesTable.set("egress_time", path.getEgressTime());
            travelTimesTable.set("n_rides", path.nRides);
        }
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // Build return table
        RDataFrame travelTimesTable = new RDataFrame(nRows);
        travelTimesTable.addStringColumn("from_id", fromId);
        travelTimesTable.addStringColumn("to_id", "");

        if (!this.routingProperties.expandedTravelTimes) {
            // regular travel time matrix, with percentiles
            for (int p : this.routingProperties.percentiles) {
                String ps = String.format("%02d", p);
                travelTimesTable.addIntegerColumn("travel_time_p" + ps, Integer.MAX_VALUE);
            }
        } else {
            // expanded travel time matrix, with minute by minute route information
            travelTimesTable.addStringColumn("departure_time", "");
            travelTimesTable.addIntegerColumn("draw_number", 0);

            // if breakdown == true, return additional travel time information
            if (this.routingProperties.travelTimesBreakdown) {
                travelTimesTable.addDoubleColumn("access_time", 0.0);
                travelTimesTable.addDoubleColumn("wait_time", 0.0);
                travelTimesTable.addDoubleColumn("ride_time", 0.0);
                travelTimesTable.addDoubleColumn("transfer_time", 0.0);
                travelTimesTable.addDoubleColumn("egress_time", 0.0);
            }

            travelTimesTable.addStringColumn("routes", "");

            if (this.routingProperties.travelTimesBreakdown) {
                travelTimesTable.addIntegerColumn("n_rides", 0);
            }

            travelTimesTable.addDoubleColumn("total_time", 0.0);
        }

        return travelTimesTable;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.percentiles = this.routingProperties.percentiles;
        request.includePathResults = this.routingProperties.expandedTravelTimes;

        request.destinationPointSetKeys = this.opportunities;
        request.destinationPointSets = this.destinationPoints;

        return request;
    }

}
