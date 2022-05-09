package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.path.RouteSequence;
import com.google.common.collect.Multimap;
import org.apache.commons.lang3.ArrayUtils;
import org.ipea.r5r.R5.R5TravelTimeComputer;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Field;
import java.text.ParseException;
import java.util.*;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.IntStream;

import static com.google.common.base.Preconditions.checkState;

public class TravelTimeMatrixComputer extends R5Process {

    private static final int ROUTES_INDEX = 0;
    private static final int ACCESS_TIME_INDEX = 4;
    private static final int WAIT_TIME_INDEX = 7;
    private static final int RIDE_TIME_INDEX = 3;
    private static final int TRANSFER_TIME_INDEX = 6;
    private static final int EGRESS_TIME_INDEX = 5;
    private static final int COMBINED_TIME_INDEX = 8;
    private static final int N_ITERATIONS_INDEX = 9;


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
        // summarize travel paths, if required
        ArrayList<String[]>[] pathResults =  null;
        List<PathBreakdown>[] pathBreakdown = null;
        if (this.routingProperties.travelTimesBreakdown) {
//            pathResults = travelTimeResults.paths.summarizeIterations(this.routingProperties.travelTimesBreakdownStat);
            pathBreakdown = extractPathResults(travelTimeResults.paths);
        }

        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            if (travelTimeResults.travelTimes.getValues()[0][destination] <= maxTripDuration) {

                // add new row to data frame
                travelTimesTable.append();

                // set destination id
                travelTimesTable.set("to_id", toIds[destination]);

                // fill travel times for destination
                populateTravelTimes(travelTimeResults, travelTimesTable, destination);

                // fill travel details for destination
//                populateTravelTimesBreakdown(travelTimesTable, pathResults, destination);
                populateTravelTimesBreakdown(travelTimesTable, pathBreakdown, destination);
            }
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
                        boolean walkingRouteProcessed = false;

                        Collection<PathResult.Iteration> iterations = iterationMap.get(routeSequence);
                        int nIterations = iterations.size();
                        checkState(nIterations > 0, "A path was stored without any iterations");
//                        String waits = null, transfer = null, totalTime = null;
                        String[] path = routeSequence.detailsWithGtfsIds(this.transportNetwork.transitLayer);


//                        IntStream totalWaits = iterations.stream().mapToInt(i -> i.waitTimes.sum());
//                        if (stat == PathResult.Stat.MINIMUM) {
//                            targetValue = totalWaits.min().orElse(-1);
//                        } else if (stat == PathResult.Stat.MEAN) {
//                            targetValue = totalWaits.average().orElse(-1);
//                        } else {
//                            throw new RuntimeException("Unrecognized statistic for path summary");
//                        }
//                        double score = Double.MAX_VALUE;
                        for (PathResult.Iteration iteration : iterations) {
                            // TODO clean up, maybe re-using approaches from PathScore?
//                            double thisScore = Math.abs(targetValue - iteration.waitTimes.sum());
//                            if (thisScore < score) {

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

//                            if (iteration.departureTime == 0) {
//                                if (!walkingRouteProcessed) {
//                                    breakdown.departureTime = this.departureTime;
//                                    pathResults[d].add(breakdown);
//                                    walkingRouteProcessed = true;
//                                }
//                            } else {
                                pathResults[d].add(breakdown);
//                            }
//
//
//
//                                StringJoiner waitTimes = new StringJoiner("|");
//                                iteration.waitTimes.forEach(w -> {
//                                    waitTimes.add(String.format("%.1f", w / 60f));
//                                    return true;
//                                });
//                                waits = waitTimes.toString();
//                                transfer = String.format("%.1f", routeSequence.stopSequence.transferTime(iteration) / 60f);
//                                totalTime = String.format("%.1f", iteration.totalTime / 60f);
//                                if (thisScore == 0) break;
//                                score = thisScore;
//                            }
                        }
//                        String[] row = ArrayUtils.addAll(path, transfer, waits, totalTime, String.valueOf(nIterations));
//                        checkState(row.length == DATA_COLUMNS.length);
//                        summary[d].add(row);
                    }
                }

            }

            return pathResults;

        } catch (NoSuchFieldException | IllegalAccessException e) {
            e.printStackTrace();
            return null;
        }
    }

    private void populateTravelTimes(OneOriginResult travelTimeResults, RDataFrame travelTimesTable, int destination) {
        if (this.routingProperties.percentiles.length == 1) {
            travelTimesTable.set("travel_time", travelTimeResults.travelTimes.getValues()[0][destination]);
        } else {
            for (int p = 0; p < this.routingProperties.percentiles.length; p++) {
                int tt = travelTimeResults.travelTimes.getValues()[p][destination];
                String ps = String.format("%03d", this.routingProperties.percentiles[p]);
                if (tt < maxTripDuration) {
                    travelTimesTable.set("travel_time_p" + ps, tt);
                }
            }
        }
    }

    private void populateTravelTimesBreakdown(RDataFrame travelTimesTable, ArrayList<String[]>[] pathResults, int destination) {
        if (this.routingProperties.travelTimesBreakdown & pathResults != null) {
            if (!pathResults[destination].isEmpty()) {
                for (int i = 0; i < pathResults[destination].size(); i++) {
                    // add new row, populated by previous values
                    // used to repeat values added by populateTravelTimes()
                    if (i > 0) travelTimesTable.appendRepeat();

                    // get only first recorded path
                    String[] a = pathResults[destination].get(i);

                    String routes = a[ROUTES_INDEX];
                    travelTimesTable.set("routes", routes);

                    if (!routes.equals(""))
                        travelTimesTable.set("n_rides", routes.split("\\|").length);

                    travelTimesTable.set("access_time", parseAndSumTravelTimes(a[ACCESS_TIME_INDEX]));
                    travelTimesTable.set("wait_time", parseAndSumTravelTimes(a[WAIT_TIME_INDEX]));
                    travelTimesTable.set("ride_time", parseAndSumTravelTimes(a[RIDE_TIME_INDEX]));
                    travelTimesTable.set("transfer_time", parseAndSumTravelTimes(a[TRANSFER_TIME_INDEX]));
                    travelTimesTable.set("egress_time", parseAndSumTravelTimes(a[EGRESS_TIME_INDEX]));
                    travelTimesTable.set("combined_time", parseAndSumTravelTimes(a[COMBINED_TIME_INDEX]));
                    travelTimesTable.set("n_iterations", (int) parseAndSumTravelTimes(a[N_ITERATIONS_INDEX]));
                }
            }
        }
    }

    private void populateTravelTimesBreakdown(RDataFrame travelTimesTable, List<PathBreakdown>[] pathBreakdown, int destination) {
        if (this.routingProperties.travelTimesBreakdown & pathBreakdown != null) {
            if (!pathBreakdown[destination].isEmpty()) {
                for (int i = 0; i < pathBreakdown[destination].size(); i++) {
                    // add new row, populated by previous values
                    // used to repeat values added by populateTravelTimes()
                    if (i > 0) travelTimesTable.appendRepeat();

                    // get only first recorded path
                    PathBreakdown path = pathBreakdown[destination].get(i);

                    travelTimesTable.set("departure_time", path.departureTime);

                    travelTimesTable.set("routes", path.routes);
                    travelTimesTable.set("n_rides", path.nRides);

                    travelTimesTable.set("access_time", path.getAccessTime());
                    travelTimesTable.set("wait_time", path.getWaitTime());
                    travelTimesTable.set("ride_time", path.getRideTime());
                    travelTimesTable.set("transfer_time", path.getTransferTime());
                    travelTimesTable.set("egress_time", path.getEgressTime());
                    travelTimesTable.set("combined_time", path.getCombinedTravelTime() > 0 ? path.getCombinedTravelTime() : path.getTotalTime());
//                    travelTimesTable.set("n_iterations", 1);
                }
            }
        }
    }

    private double parseAndSumTravelTimes(String a) {
        if (a == null) return 0.0;
        if (a.equals("")) return 0.0;

        String[] b = a.split("\\|");

        return Arrays.stream(b).
                mapToDouble(
                        s -> Double.parseDouble(s.replaceAll(",","."))
                ).sum();
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // Build return table
        RDataFrame travelTimesTable = new RDataFrame(nRows);
        travelTimesTable.addStringColumn("from_id", fromId);
        travelTimesTable.addStringColumn("to_id", "");

        if (this.routingProperties.percentiles.length == 1) {
            travelTimesTable.addIntegerColumn("travel_time", Integer.MAX_VALUE);
        } else {
            for (int p : this.routingProperties.percentiles) {
                String ps = String.format("%03d", p);
                travelTimesTable.addIntegerColumn("travel_time_p" + ps, Integer.MAX_VALUE);
            }
        }

        if (this.routingProperties.travelTimesBreakdown) {
            travelTimesTable.addStringColumn("departure_time", "");
            travelTimesTable.addDoubleColumn("access_time", 0.0);
            travelTimesTable.addDoubleColumn("wait_time", 0.0);
            travelTimesTable.addDoubleColumn("ride_time", 0.0);
            travelTimesTable.addDoubleColumn("transfer_time", 0.0);
            travelTimesTable.addDoubleColumn("egress_time", 0.0);
            travelTimesTable.addDoubleColumn("combined_time", 0.0);

            travelTimesTable.addStringColumn("routes", "");
            travelTimesTable.addIntegerColumn("n_rides", 0);
//            travelTimesTable.addIntegerColumn("n_iterations", 0);
        }
        return travelTimesTable;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.percentiles = this.routingProperties.percentiles;
        request.includePathResults = this.routingProperties.travelTimesBreakdown;

        request.destinationPointSetKeys = this.opportunities;
        request.destinationPointSets = this.destinationPoints;

        return request;
    }

}
