package org.ipea.r5r.Process;

import com.conveyal.analysis.models.CsvResultOptions;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.cluster.TravelTimeResult;
import com.conveyal.r5.api.util.SearchType;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.path.RouteSequence;
import com.google.common.collect.ArrayListMultimap;
import com.google.common.collect.Multimap;
import org.apache.arrow.memory.BufferAllocator;
import org.apache.arrow.vector.IntVector;
import org.apache.arrow.vector.VarCharVector;
import org.apache.arrow.vector.VectorSchemaRoot;
import org.apache.arrow.vector.VectorUnloader;
import org.apache.arrow.vector.ipc.message.ArrowRecordBatch;
import org.apache.arrow.vector.types.FloatingPointPrecision;
import org.apache.arrow.vector.types.pojo.ArrowType;
import org.apache.arrow.vector.types.pojo.Field;
import org.apache.arrow.vector.types.pojo.FieldType;
import org.apache.arrow.vector.types.pojo.Schema;
import org.ipea.r5r.R5.R5TravelTimeComputer;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.charset.StandardCharsets;
import java.text.ParseException;
import java.util.*;
import java.util.concurrent.ForkJoinPool;

import static com.google.common.base.Preconditions.checkState;

public class TravelTimeMatrixComputer extends ArrowR5Process {

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

    private final CsvResultOptions csvOptions;

    private int monteCarloDrawsPerMinute;

    @Override
    protected boolean isOneToOne() {
        return false;
    }

    public TravelTimeMatrixComputer(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
        this.csvOptions = new CsvResultOptions();
    }

    @Override
    protected BatchWithSeq runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);
        TravelTimeComputer computer = new R5TravelTimeComputer(request, transportNetwork);
        OneOriginResult travelTimeResults = computer.computeTravelTimes();
        return populateDataFrame(travelTimeResults, index);

        // TODO check schema nonempty
/*        if (nextRow > 0) {
            return root;
        } else {
            return null;
        }*/
    }

    private BatchWithSeq populateDataFrame(OneOriginResult travelTimeResults, int originIndex) {
        if (this.routingProperties.expandedTravelTimes) {
            // populateExpandedResults(travelTimeResults, travelTimesTable);
            return null;
        } else {
            return populateRegularResults(travelTimeResults, originIndex);
        }
    }

    private BatchWithSeq populateRegularResults(OneOriginResult travelTimeResults, int originIndex) {
        BufferAllocator allocator = parentAllocator.newChildAllocator("worker"+originIndex, 0, Long.MAX_VALUE);
        VectorSchemaRoot root = VectorSchemaRoot.create(schema, allocator);
        try {
            // Get Arrow Schema components
            VarCharVector from_id = (VarCharVector) root.getVector("from_id");
            VarCharVector to_id = (VarCharVector) root.getVector("to_id");

            final ArrayList<IntVector> travel_time_p = new ArrayList<>();
            for (int p : this.routingProperties.percentiles) {
                String ps = String.format("%02d", p);
                travel_time_p.add((IntVector) root.getVector("travel_time_p" + ps));
            }

            // allocate initial capacity
            final int nRows = travelTimeResults.travelTimes.nPoints;
            from_id.setInitialCapacity(nRows); from_id.allocateNew();
            to_id.setInitialCapacity(nRows); to_id.allocateNew();
            for (IntVector v : travel_time_p) { v.setInitialCapacity(nRows); v.allocateNew(); }

            final byte[] fromBytes = fromIds[originIndex].getBytes(StandardCharsets.UTF_8);

            for (int d = 0; d < nRows; d++) {
                from_id.setSafe(d, fromBytes);
                to_id.setSafe(d, toIds[d].getBytes(StandardCharsets.UTF_8));

                // set percentiles
                for (int p = 0; p < travel_time_p.size(); p++) {
                    int tt = travelTimeResults.travelTimes.getValues()[p][d];
                    if (tt <= maxTripDuration) {
                        travel_time_p.get(p).setSafe(d, tt);
                    }
                    else travel_time_p.get(p).setNull(d);

                }
            }

            root.setRowCount(nRows);

            ArrowRecordBatch batch = new VectorUnloader(root).getRecordBatch();

            root.close(); root = null;

            return new BatchWithSeq(originIndex, batch, allocator);
        } catch (Throwable t) {
            try { if (root != null) root.close(); } finally { allocator.close(); }
            LOG.error(String.valueOf(t));
            throw t;
        }
    }

    private void populateExpandedResults(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        // extract travel paths, if required
        Multimap<Integer, PathBreakdown>[] pathBreakdown = extractPathResults(travelTimeResults.paths, travelTimeResults.travelTimes);

        // set expected monteCarloDrawsPerMinute to later use to count if every path was accounted for in routing
        monteCarloDrawsPerMinute = transportNetwork.transitLayer.hasFrequencies
                ? routingProperties.numberOfMonteCarloDraws / routingProperties.timeWindowSize
                : 1;


        if (routingProperties.searchType == SearchType.ARRIVE_BY) {
            for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
                // fill travel details for destination
                filterLatestBeforeArrivalTime(travelTimesTable, pathBreakdown, destination);
            }
        } else {
            for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
                // fill travel details for destination
                populateTravelTimesBreakdown(travelTimesTable, pathBreakdown, destination);
            }
        }
    }

    private void filterLatestBeforeArrivalTime(RDataFrame travelTimesTable, Multimap<Integer, PathBreakdown>[] pathBreakdown, int destination) {
        if (this.routingProperties.expandedTravelTimes & pathBreakdown != null) {
            if (!pathBreakdown[destination].isEmpty()) {
                // for this destination return the latest departing trip that still arrives before the arrival time
                int desiredArrivalTime = secondsFromMidnight + maxTripDuration * 60; // convert trip duration to seconds

                for (int departureTime = secondsFromMidnight + (routingProperties.timeWindowSize - 1) * 60;
                     departureTime >= secondsFromMidnight;
                     departureTime -= 60) {
                    Collection<PathBreakdown> pbs = pathBreakdown[destination].get(departureTime);

                    int monteCarloDrawsForPath = 0;
                    for (PathBreakdown path : pbs) {
                        int arrivalTime = departureTime + (int) (path.getTotalTime() * 60);
                        monteCarloDrawsForPath++;
                        if (arrivalTime <= desiredArrivalTime) {
                            addPathToDataframe(travelTimesTable, destination, monteCarloDrawsForPath, path);
                            return; // only return the first trip per destination that arrives before the desiredArrivalTime cutoff
                            // since we are searching in descending order of departure times it will be the lastest
                            // departure arriving before our desired time
                        }
                    }

                    // if there are less routes than expected check direct paths
                    if (monteCarloDrawsForPath < monteCarloDrawsPerMinute) {
                        Collection<PathBreakdown> directPaths = pathBreakdown[destination].get(0);

                        PathBreakdown directPath;
                        if (!directPaths.isEmpty()) {
                            directPath = directPaths.iterator().next();
                        } else {
                            return; // if path is unreachable there is no point seeing if it arrives in time
                        }

                        monteCarloDrawsForPath = 1; // artificial "first draw" for direct path
                        int arrivalTime = departureTime + (int) (directPath.getTotalTime() * 60);

                        if (arrivalTime <= desiredArrivalTime) {
                            directPath.departureTime = Utils.getTimeFromSeconds(departureTime);
                            addPathToDataframe(travelTimesTable, destination, monteCarloDrawsForPath, directPath);
                            return; // only return the first trip per destination that arrives before the desiredArrivalTime cutoff
                            // since we are searching in descending order of departure times it will be the lastest
                            // departure arriving before our desired time
                        }
                    }
                }
            }
        }
    }

    private Multimap<Integer, PathBreakdown>[] extractPathResults(PathResult paths, TravelTimeResult travelTimes) {
        Multimap<Integer, PathBreakdown>[] pathResults = new Multimap[nDestinations];

        for (int d = 0; d < nDestinations; d++) {
            pathResults[d] = ArrayListMultimap.create();

            Multimap<RouteSequence, PathResult.Iteration> iterationMap = paths.iterationsForPathTemplates[d];
            if (iterationMap != null) {

                for (RouteSequence routeSequence : iterationMap.keySet()) {
                    Collection<PathResult.Iteration> iterations = iterationMap.get(routeSequence);
                    int nIterations = iterations.size();
                    checkState(nIterations > 0, "A path was stored without any iterations");

                    // extract the route id's
                    String[] path = routeSequence.detailsWithGtfsIds(this.transportNetwork.transitLayer, csvOptions);

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

                    // if there are less routes than expected check direct paths
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

    protected void buildSchemaStructure() {
        List<Field> ttmColumns = new ArrayList<>();
        ttmColumns.add(new Field("from_id", FieldType.notNullable(new ArrowType.Utf8()), null)); // default value fromId
        ttmColumns.add(new Field("to_id", FieldType.notNullable(new ArrowType.Utf8()), null));
        if (this.routingProperties.expandedTravelTimes) {
            ttmColumns.add(new Field("departure_time", FieldType.notNullable(new ArrowType.Utf8()), null)); // default value ""
            ttmColumns.add(new Field("draw_number", FieldType.notNullable(new ArrowType.Int(32, true)), null)); // default value 0
            if (this.routingProperties.travelTimesBreakdown) {
                ttmColumns.add(new Field("access_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
                ttmColumns.add(new Field("wait_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
                ttmColumns.add(new Field("ride_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
                ttmColumns.add(new Field("transfer_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
                ttmColumns.add(new Field("egress_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
            }
            ttmColumns.add(new Field("routes", FieldType.notNullable(new ArrowType.Utf8()), null)); // default value ""
            if (this.routingProperties.travelTimesBreakdown) {
                ttmColumns.add(new Field("n_rides", FieldType.notNullable(new ArrowType.Int(32, true)), null)); // default value 0
            }
            ttmColumns.add(new Field("total_time", FieldType.notNullable(new ArrowType.FloatingPoint(FloatingPointPrecision.DOUBLE)), null)); // default value 0.0
        } else {
            // regular travel time matrix, with percentiles
            for (int p : this.routingProperties.percentiles) {
                String ps = String.format("%02d", p);
                ttmColumns.add(new Field("travel_time_p" + ps, FieldType.nullable(new ArrowType.Int(32, true)), null)); // default value Integer.MAX_VALUE
            }
        }

        schema = new Schema(ttmColumns, null);
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


final class BatchWithSeq implements AutoCloseable {
    final int seq;
    final ArrowRecordBatch batch;
    final BufferAllocator allocator;

    BatchWithSeq(int seq, ArrowRecordBatch batch, BufferAllocator allocator) {
        this.seq = seq;
        this.batch = batch;
        this.allocator = allocator;
    }

    @Override public void close() {
        try {
            batch.close();
        } finally {
            allocator.close();
        }
    }
}