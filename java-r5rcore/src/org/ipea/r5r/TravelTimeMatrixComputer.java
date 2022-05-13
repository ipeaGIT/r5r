package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.path.RouteSequence;
import com.google.common.collect.Multimap;
import org.ipea.r5r.R5.R5TravelTimeComputer;
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
    }

    private static final Logger LOG = LoggerFactory.getLogger(TravelTimeMatrixComputer.class);

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
        List<PathBreakdown>[] pathBreakdown = extractPathResults(travelTimeResults.paths);

        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            // fill travel details for destination
            populateTravelTimesBreakdown(travelTimesTable, pathBreakdown, destination);
        }
    }

    private List<PathBreakdown>[] extractPathResults(PathResult paths) {
        // Create Field object
        Field privateField = null;
        try {
            privateField = PathResult.class.getDeclaredField("iterationsForPathTemplates");
            // Set the accessibility as true
            privateField.setAccessible(true);

            // Store the value of private field in variable
            Multimap<RouteSequence, PathResult.Iteration>[] iterationMaps = (Multimap<RouteSequence, PathResult.Iteration>[])privateField.get(paths);

            ArrayList<PathBreakdown>[] pathResults = new ArrayList[nDestinations];

            for (int d = 0; d < nDestinations; d++) {
                pathResults[d] = new ArrayList<>();

                Multimap<RouteSequence, PathResult.Iteration> iterationMap = iterationMaps[d];
                if (iterationMap != null) {

                    for (RouteSequence routeSequence : iterationMap.keySet()) {
                        boolean directRouteProcessed = false;

                        Collection<PathResult.Iteration> iterations = iterationMap.get(routeSequence);
                        int nIterations = iterations.size();
                        checkState(nIterations > 0, "A path was stored without any iterations");
//                        String waits = null, transfer = null, totalTime = null;
                        String[] path = routeSequence.detailsWithGtfsIds(this.transportNetwork.transitLayer);

                        for (PathResult.Iteration iteration : iterations) {

//                            if (routeSequence.stopSequence == null) System.out.println("stop sequence is null");
//                            if (routeSequence.stopSequence.access == null) System.out.println("stop sequence access is null");
//                            if (routeSequence.stopSequence.egress == null) System.out.println("stop sequence egress is null");
//                            if (iteration.waitTimes == null) System.out.println("wait times is null");
//                            if (routeSequence.stopSequence.rideTimesSeconds == null) System.out.println("ride time is null");

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
                                if (!directRouteProcessed) {
                                    breakdown.departureTime = "";
                                    breakdown.routes = this.directModes.toString();
                                    pathResults[d].add(breakdown);
                                    directRouteProcessed = true;
                                }
                            } else {
                                pathResults[d].add(breakdown);
                            }
                        }
                    }
                }

            }

            return pathResults;

        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
            return null;
        }
    }

    private void populateTravelTimesBreakdown(RDataFrame travelTimesTable, List<PathBreakdown>[] pathBreakdown, int destination) {
        if (this.routingProperties.expandedTravelTimes & pathBreakdown != null) {
            if (!pathBreakdown[destination].isEmpty()) {
                for (int i = 0; i < pathBreakdown[destination].size(); i++) {
                    travelTimesTable.append();

                    // set destination id
                    travelTimesTable.set("to_id", toIds[destination]);

                    // get only first recorded path
                    PathBreakdown path = pathBreakdown[destination].get(i);

                    travelTimesTable.set("departure_time", path.departureTime);
                    travelTimesTable.set("routes", path.routes);
                    travelTimesTable.set("n_rides", path.nRides);
                    travelTimesTable.set("total_time", path.getCombinedTravelTime() > 0 ? path.getCombinedTravelTime() : path.getTotalTime());

                    if (routingProperties.travelTimesBreakdown) {
                        travelTimesTable.set("access_time", path.getAccessTime());
                        travelTimesTable.set("wait_time", path.getWaitTime());
                        travelTimesTable.set("ride_time", path.getRideTime());
                        travelTimesTable.set("transfer_time", path.getTransferTime());
                        travelTimesTable.set("egress_time", path.getEgressTime());
                    }
                }
            }
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

            // if breakdown == true, return additional travel time information
            if (this.routingProperties.travelTimesBreakdown) {
                travelTimesTable.addDoubleColumn("access_time", 0.0);
                travelTimesTable.addDoubleColumn("wait_time", 0.0);
                travelTimesTable.addDoubleColumn("ride_time", 0.0);
                travelTimesTable.addDoubleColumn("transfer_time", 0.0);
                travelTimesTable.addDoubleColumn("egress_time", 0.0);
            }

            travelTimesTable.addStringColumn("routes", "");
            travelTimesTable.addIntegerColumn("n_rides", 0);

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
