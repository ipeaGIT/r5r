package org.ipea.r5r;

import com.conveyal.gtfs.model.Service;
import com.conveyal.r5.analyst.Grid;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.decay.*;
import com.conveyal.r5.point_to_point.builder.TNBuilderConfig;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.EdgeTraversalTimes;
import com.conveyal.r5.transit.TransferFinder;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.Utils.ElevationUtils;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

public class R5RCore {

    private int numberOfThreads;
    private ForkJoinPool r5rThreadPool;

    private final RoutingProperties routingProperties = new RoutingProperties();

    public double getWalkSpeed() {
        return this.routingProperties.walkSpeed;
    }

    public void setWalkSpeed(double walkSpeed) {
        this.routingProperties.walkSpeed = walkSpeed;
    }

    public double getBikeSpeed() {
        return this.routingProperties.bikeSpeed;
    }

    public void setBikeSpeed(double bikeSpeed) {
        this.routingProperties.bikeSpeed = bikeSpeed;
    }


    public int getMaxLevelTrafficStress() {
        return this.routingProperties.maxLevelTrafficStress;
    }

    public void setMaxLevelTrafficStress(int maxLevelTrafficStress) {
        this.routingProperties.maxLevelTrafficStress = maxLevelTrafficStress;
    }

    public int getSuboptimalMinutes() {
        return this.routingProperties.suboptimalMinutes;
    }

    public void setSuboptimalMinutes(int suboptimalMinutes) {
        this.routingProperties.suboptimalMinutes = suboptimalMinutes;
    }

    public int getTimeWindowSize() {
        return this.routingProperties.timeWindowSize;
    }

    public void setTimeWindowSize(int timeWindowSize) {
        this.routingProperties.timeWindowSize = timeWindowSize;
    }

    public int getNumberOfMonteCarloDraws() {
        return this.routingProperties.numberOfMonteCarloDraws;
    }

    public void setNumberOfMonteCarloDraws(int numberOfMonteCarloDraws) {
        this.routingProperties.numberOfMonteCarloDraws = numberOfMonteCarloDraws;
    }

    public void setPercentiles(int[] percentiles) {
        this.routingProperties.percentiles = percentiles;
    }

    public void setPercentiles(int percentile) {
        this.routingProperties.percentiles = new int[1];
        this.routingProperties.percentiles[0] = percentile;
    }

    public void setCutoffs(int[] cutoffs) {
        this.routingProperties.cutoffs = cutoffs;
    }

    public void setCutoffs(int cutoff) {
        this.routingProperties.cutoffs = new int[1];
        this.routingProperties.cutoffs[0] = cutoff;
    }

    public int getMaxRides() {
        return this.routingProperties.maxRides;
    }

    public void setMaxRides(int maxRides) {
        this.routingProperties.maxRides = maxRides;
    }

    public void setTravelTimesBreakdown(boolean detailedTravelTimes) {
        this.routingProperties.travelTimesBreakdown = detailedTravelTimes;
    }

    public boolean getTravelTimesBreakdown() {
        return this.routingProperties.travelTimesBreakdown;
    }

    public void setTravelTimesBreakdownStat(String stat) {
        stat = stat.toUpperCase();
        if (stat.equals("MIN") | stat.equals("MINIMUM")) {
            this.routingProperties.travelTimesBreakdownStat = PathResult.Stat.MINIMUM;
        }
        if (stat.equals("MEAN") | stat.equals("AVG") | stat.equals("AVERAGE")) {
            this.routingProperties.travelTimesBreakdownStat = PathResult.Stat.MINIMUM;
        }
    }

    public String getTravelTimesBreakdownStat() {
        return this.routingProperties.travelTimesBreakdownStat.toString();
    }

    public int getNumberOfThreads() {
        return this.numberOfThreads;
    }

    public void setNumberOfThreads(int numberOfThreads) {
        this.numberOfThreads = numberOfThreads;
        r5rThreadPool = new ForkJoinPool(numberOfThreads);
    }

    public void setNumberOfThreadsToMax() {
        r5rThreadPool = ForkJoinPool.commonPool();
        numberOfThreads = ForkJoinPool.commonPool().getParallelism();
    }

    public void silentMode() {
        Utils.setLogMode("ERROR", false);
    }

    public void verboseMode() {
        Utils.setLogMode("ALL", true);
    }

    public void setProgress(boolean progress) {
        Utils.progress = progress;
    }

    public void setBenchmark(boolean benchmark) {
        Utils.benchmark = benchmark;
    }

    private final TransportNetwork transportNetwork;

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(R5RCore.class);

    public R5RCore(String dataFolder) throws Exception {
        this(dataFolder, true);
    }

    public R5RCore(String dataFolder, boolean verbose) throws Exception {
        if (verbose) {
            verboseMode();
        } else {
            silentMode();
        }

        setNumberOfThreadsToMax();

        this.transportNetwork = R5Network.checkAndLoadR5Network(dataFolder);
    }


    public void buildDistanceTables() {
        this.transportNetwork.transitLayer.buildDistanceTables(null);
        new TransferFinder(transportNetwork).findTransfers();
    }

    // ---------------------------------------------------------------------------------------------------
    //                                      MAIN R5R FUNCTIONS
    // ---------------------------------------------------------------------------------------------------

    // ----------------------------------  DETAILED ITINERARIES  -----------------------------------------

    public RDataFrame detailedItineraries(String fromId, double fromLat, double fromLon, String toId, double toLat, double toLon,
                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                   String date, String departureTime, int maxWalkTime, int maxBikeTime,  int maxTripDuration,
                                                                   boolean dropItineraryGeometry) throws ParseException, ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};
        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return detailedItineraries(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration, dropItineraryGeometry);

    }

    public RDataFrame detailedItineraries(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                            String[] toIds, double[] toLats, double[] toLons,
                                                                            String directModes, String transitModes, String accessModes, String egressModes,
                                                                            String date, String departureTime, int maxWalkTime, int maxBikeTime, int maxTripDuration,
                                                                            boolean dropItineraryGeometry) throws ExecutionException, InterruptedException {

        DetailedItineraryPlanner detailedItineraryPlanner = new DetailedItineraryPlanner(this.r5rThreadPool, this.transportNetwork, this.routingProperties);
        detailedItineraryPlanner.setOrigins(fromIds, fromLats, fromLons);
        detailedItineraryPlanner.setDestinations(toIds, toLats, toLons);
        detailedItineraryPlanner.setModes(directModes, accessModes, transitModes, egressModes);
        detailedItineraryPlanner.setDepartureDateTime(date, departureTime);
        detailedItineraryPlanner.setTripDuration(maxWalkTime, maxBikeTime, maxTripDuration);
        if (dropItineraryGeometry) { detailedItineraryPlanner.dropItineraryGeometry(); }

        return detailedItineraryPlanner.run();
    }





    // ----------------------------------  TRAVEL TIME MATRIX  -----------------------------------------

    public RDataFrame travelTimeMatrix(String fromId, double fromLat, double fromLon,
                                                                           String[] toIds, double[] toLats, double[] toLons,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        return travelTimeMatrix(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame travelTimeMatrix(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                           String toId, double toLat, double toLon,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return travelTimeMatrix(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame travelTimeMatrix(String fromId, double fromLat, double fromLon,
                                                                           String toId, double toLat, double toLon,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return travelTimeMatrix(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame travelTimeMatrix(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                           String[] toIds, double[] toLats, double[] toLons,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        TravelTimeMatrixComputer travelTimeMatrixComputer = new TravelTimeMatrixComputer(this.r5rThreadPool, this.transportNetwork, this.routingProperties);
        travelTimeMatrixComputer.setOrigins(fromIds, fromLats, fromLons);
        travelTimeMatrixComputer.setDestinations(toIds, toLats, toLons);
        travelTimeMatrixComputer.setModes(directModes, accessModes, transitModes, egressModes);
        travelTimeMatrixComputer.setDepartureDateTime(date, departureTime);
        travelTimeMatrixComputer.setTripDuration(maxWalkTime, maxBikeTime, maxTripDuration);

        return travelTimeMatrixComputer.run();
    }

    // --------------------------------------  ACCESSIBILITY  ----------------------------------------------

    public RDataFrame accessibility(String fromId, double fromLat, double fromLon,
                                                                           String[] toIds, double[] toLats, double[] toLons, int[] opportunities,
                                                                           String decayFunction, double decayValue,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        return accessibility(fromIds, fromLats, fromLons, toIds, toLats, toLons, opportunities, decayFunction, decayValue,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame accessibility(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                           String toId, double toLat, double toLon,  int opportunities,
                                                                        String decayFunction, double decayValue,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};
        int[] opportunitiesVector = {opportunities};

        return accessibility(fromIds, fromLats, fromLons, toIds, toLats, toLons, opportunitiesVector, decayFunction, decayValue,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame accessibility(String fromId, double fromLat, double fromLon,
                                                                           String toId, double toLat, double toLon, int opportunities,
                                                                        String decayFunction, double decayValue,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};
        int[] opportunitiesVector = {opportunities};

        return accessibility(fromIds, fromLats, fromLons, toIds, toLats, toLons, opportunitiesVector, decayFunction, decayValue,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime,  maxBikeTime, maxTripDuration);

    }

    public RDataFrame accessibility(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                        String[] toIds, double[] toLats, double[] toLons, int[] opportunities,
                                                                        String decayFunction, double decayValue,
                                                                        String directModes, String transitModes, String accessModes, String egressModes,
                                                                        String date, String departureTime,
                                                                        int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ExecutionException, InterruptedException {


        AccessibilityEstimator accessibilityEstimator = new AccessibilityEstimator(this.r5rThreadPool, this.transportNetwork, this.routingProperties);
        accessibilityEstimator.setOrigins(fromIds, fromLats, fromLons);
        accessibilityEstimator.setDestinations(toIds, toLats, toLons, opportunities);
        accessibilityEstimator.setDecayFunction(decayFunction, decayValue);
        accessibilityEstimator.setModes(directModes, accessModes, transitModes, egressModes);
        accessibilityEstimator.setDepartureDateTime(date, departureTime);
        accessibilityEstimator.setTripDuration(maxWalkTime, maxBikeTime, maxTripDuration);

        return accessibilityEstimator.run();
    }

    // ----------------------------------  ISOCHRONES  -----------------------------------------

    public RDataFrame isochrones(String[] fromId, double[] fromLat, double[] fromLon, int cutoffs, int zoom,
                                                                     String directModes, String transitModes, String accessModes, String egressModes,
                                                                     String date, String departureTime, int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {
        int[] cutoffTimes = {cutoffs};

        return isochrones(fromId, fromLat, fromLon, cutoffTimes, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime,maxBikeTime, maxTripDuration);
    }

    public RDataFrame isochrones(String fromId, double fromLat, double fromLon, int cutoffs, int zoom,
                                                                     String directModes, String transitModes, String accessModes, String egressModes,
                                                                     String date, String departureTime, int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};
        int[] cutoffTimes = {cutoffs};

        return isochrones(fromIds, fromLats, fromLons, cutoffTimes, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame isochrones(String fromId, double fromLat, double fromLon, int[] cutoffs, int zoom,
                                                                     String directModes, String transitModes, String accessModes, String egressModes,
                                                                     String date, String departureTime, int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        return isochrones(fromIds, fromLats, fromLons, cutoffs, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxBikeTime, maxTripDuration);

    }

    public RDataFrame isochrones(String[] fromId, double[] fromLat, double[] fromLon, int[] cutoffs, int zoom,
                                                                     String directModes, String transitModes, String accessModes, String egressModes,
                                                                     String date, String departureTime, int maxWalkTime, int maxBikeTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        // Instantiate IsochroneBuilder object and set properties
        IsochroneBuilder isochroneBuilder = new IsochroneBuilder(r5rThreadPool, this.transportNetwork, this.routingProperties);
        isochroneBuilder.setOrigins(fromId, fromLat, fromLon);
        isochroneBuilder.setModes(directModes, accessModes, transitModes, egressModes);
        isochroneBuilder.setDepartureDateTime(date, departureTime);
        isochroneBuilder.setTripDuration(maxWalkTime, maxBikeTime, maxTripDuration);
        isochroneBuilder.setCutoffs(cutoffs);
        isochroneBuilder.setResolution(zoom);

        // Build isochrones and return data to R as a list of data.frames
        return isochroneBuilder.run();
    }

    // ----------------------------------  FIND SNAP POINTS  -----------------------------------------
    public RDataFrame findSnapPoints(String fromId, double fromLat, double fromLon, String mode) throws ExecutionException, InterruptedException {
        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        return findSnapPoints(fromIds, fromLats, fromLons, mode);
    }

    public RDataFrame findSnapPoints(String[] fromId, double[] fromLat, double[] fromLon, String mode) throws ExecutionException, InterruptedException {
        SnapFinder snapFinder = new SnapFinder(r5rThreadPool, this.transportNetwork);
        snapFinder.setOrigins(fromId, fromLat, fromLon);
        snapFinder.setMode(mode);
        return snapFinder.run();
    }

    public RDataFrame getGrid(int resolution) {
        return getGrid(resolution, true);
    }

    public RDataFrame getGrid(int resolution, boolean dropGeometry) {
        Grid gridPointSet = new Grid(resolution, this.transportNetwork.getEnvelope());

        RDataFrame gridTable = new RDataFrame(gridPointSet.featureCount());
        gridTable.addStringColumn("id", "");
        gridTable.addDoubleColumn("lat", 0.0);
        gridTable.addDoubleColumn("lon", 0.0);
        if (!dropGeometry) { gridTable.addStringColumn("geometry", ""); }

        for (int index = 0; index < gridPointSet.featureCount(); index++) {
            int x = index % gridPointSet.width;
            int y = index / gridPointSet.width;

            gridTable.append();
            gridTable.set("id", String.valueOf(index));
            gridTable.set("lat", Grid.pixelToCenterLat(y + gridPointSet.north, resolution));
            gridTable.set("lon", Grid.pixelToCenterLon(x + gridPointSet.west, resolution));

            if (!dropGeometry) {
                gridTable.set("geometry", Grid.getPixelGeometry(x + gridPointSet.west, y + gridPointSet.north, resolution).toString());
            }
        }

        return gridTable;
    }



    // ---------------------------------------------------------------------------------------------------
    //                                    UTILITY FUNCTIONS
    // ---------------------------------------------------------------------------------------------------


    public List<RDataFrame> getStreetNetwork() {
        // Convert R5's road network to Simple Features objects
        StreetNetwork streetNetwork = new StreetNetwork(this.transportNetwork);

        // Return a list of dataframes
        List<RDataFrame> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(streetNetwork.verticesTable);
        transportNetworkList.add(streetNetwork.edgesTable);

        return transportNetworkList;
    }

    public List<RDataFrame> getTransitNetwork() {
        // Convert R5's transit network to Simple Features objects
        TransitNetwork transitNetwork = new TransitNetwork(this.transportNetwork);

        // Return a list of dataframes
        List<RDataFrame> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(transitNetwork.routesTable);
        transportNetworkList.add(transitNetwork.stopsTable);

        return transportNetworkList;
    }

    // ----------------------------------  ELEVATION  -----------------------------------------

    public RDataFrame getEdges() {
        // Build edges return table
        RDataFrame edgesTable = new RDataFrame();
        edgesTable.addIntegerColumn("edge_index", 0);
        edgesTable.addDoubleColumn("length", 0.0);
        edgesTable.addDoubleColumn("start_lat", 0.0);
        edgesTable.addDoubleColumn("start_lon", 0.0);
        edgesTable.addDoubleColumn("end_lat", 0.0);
        edgesTable.addDoubleColumn("end_lon", 0.0);
        edgesTable.addStringColumn("geometry", "");

        EdgeStore edges = transportNetwork.streetLayer.edgeStore;

        EdgeStore.Edge edgeCursor = edges.getCursor();
        while (edgeCursor.advance()) {
            edgesTable.append();
            edgesTable.set("edge_index", edgeCursor.getEdgeIndex());
            edgesTable.set("length", edgeCursor.getLengthM());
            edgesTable.set("start_lat", edgeCursor.getGeometry().getStartPoint().getY());
            edgesTable.set("start_lon", edgeCursor.getGeometry().getStartPoint().getX());
            edgesTable.set("end_lat", edgeCursor.getGeometry().getEndPoint().getY());
            edgesTable.set("end_lon", edgeCursor.getGeometry().getEndPoint().getX());
            edgesTable.set("geometry", edgeCursor.getGeometry().toString());
        }

        return edgesTable;
    }

    public void updateEdges(int[] edgeIndices, double[] walkTimeFactor, double[] bikeTimeFactor) {
        EdgeStore edges = transportNetwork.streetLayer.edgeStore;
        EdgeStore.Edge edgeCursor = edges.getCursor();

        buildEdgeTraversalTimes(edges);

        for (int i = 0; i < edgeIndices.length; i++) {
            edgeCursor.seek(edgeIndices[i]);

            edgeCursor.setWalkTimeFactor(walkTimeFactor[i]);
            edgeCursor.setBikeTimeFactor(bikeTimeFactor[i]);
        }
    }

    public void resetEdges() {
        EdgeStore edges = transportNetwork.streetLayer.edgeStore;
        EdgeStore.Edge edgeCursor = edges.getCursor();

        buildEdgeTraversalTimes(edges);

        while (edgeCursor.advance()) {
            edgeCursor.setWalkTimeFactor(1.0);
            edgeCursor.setBikeTimeFactor(1.0);
        }
    }

    public void dropElevation() {
        resetEdges();
        buildDistanceTables();
    }

    private void buildEdgeTraversalTimes(EdgeStore edges) {
        if (edges.edgeTraversalTimes == null) {
            edges.edgeTraversalTimes = new EdgeTraversalTimes(edges);

            for (int edge = 0; edge < edges.nEdges(); edge++) {
                edges.edgeTraversalTimes.addOneEdge();
            }
        }
    }


    public static double[] bikeSpeedCoefficientOTP(double[] slope, double[] altitude) {
        double[] results = new double[slope.length];

        int[] indices = new int[slope.length];
        for (int i = 0; i < slope.length; i++) { indices[i] = i; }

        Arrays.stream(indices).parallel().forEach(index -> {
            results[index] = bikeSpeedCoefficientOTP(slope[index], altitude[index]);
        });

        return results;
    }

    public static double bikeSpeedCoefficientOTP(double slope, double altitude) {
        return ElevationUtils.bikeSpeedCoefficientOTP(slope, altitude);
    }

    // Returns list of public transport services active on a given date
    public RDataFrame getTransitServicesByDate(String date) {
        RDataFrame servicesTable = new RDataFrame();
        servicesTable.addStringColumn("service_id", "");
        servicesTable.addStringColumn("start_date", "");
        servicesTable.addStringColumn("end_date", "");
        servicesTable.addBooleanColumn("active_on_date", false);

        for (Service service : transportNetwork.transitLayer.services) {
            servicesTable.append();
            servicesTable.set("service_id", service.service_id);

            if (service.calendar != null) {
                servicesTable.set("start_date", String.valueOf(service.calendar.start_date));
                servicesTable.set("end_date", String.valueOf(service.calendar.end_date));
            }

            servicesTable.set("active_on_date", service.activeOn(LocalDate.parse(date)));
        }

        return servicesTable;
    }

    public double[] testDecay(String decayFunctionName, double decayValue) {
        DecayFunction decayFunction = null;
        decayFunctionName = decayFunctionName.toUpperCase();
        if (decayFunctionName.equals("STEP")) { decayFunction = new StepDecayFunction(); }
        if (decayFunctionName.equals("EXPONENTIAL")) { decayFunction = new ExponentialDecayFunction(); }

        if (decayFunctionName.equals("FIXED_EXPONENTIAL")) {
            decayFunction = new FixedExponentialDecayFunction();
            ((FixedExponentialDecayFunction) decayFunction).decayConstant = decayValue;
        }
        if (decayFunctionName.equals("LINEAR")) {
            decayFunction = new LinearDecayFunction();
            ((LinearDecayFunction) decayFunction).widthMinutes = (int) decayValue;
        }
        if (decayFunctionName.equals("LOGISTIC")) {
            decayFunction = new LogisticDecayFunction();
            ((LogisticDecayFunction) decayFunction).standardDeviationMinutes = decayValue;
        }

        if (decayFunction != null) {
            decayFunction.prepare();
            double[] decay = new double [3600];
            for (int i = 0; i < 3600; i++) {
                decay[i] = decayFunction.computeWeight(1800, i+1);
            }
            return decay;
            
        } else {
            return null;
        }

    }

    public String defaultBuildConfig() {
        TNBuilderConfig builderConfig = TNBuilderConfig.defaultConfig();

        return builderConfig.toString();
    }

}
