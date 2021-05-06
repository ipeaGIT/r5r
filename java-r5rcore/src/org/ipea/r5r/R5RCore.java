package org.ipea.r5r;

import com.conveyal.gtfs.model.Service;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.EdgeTraversalTimes;
import com.conveyal.r5.transit.*;
import org.ipea.r5r.Utils.ElevationUtils;
import org.ipea.r5r.Utils.Utils;
import org.locationtech.jts.geom.Coordinate;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.text.ParseException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.Collectors;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class R5RCore {

    private int numberOfThreads;
    ForkJoinPool r5rThreadPool;

    RoutingProperties routingProperties = new RoutingProperties();

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

    private int[] percentiles = {50};

    public void setPercentiles(int[] percentiles) {
        this.percentiles = percentiles;
    }

    public void setPercentiles(int percentile) {
        this.percentiles = new int[1];
        this.percentiles[0] = percentile;
    }


    public int getMaxRides() {
        return this.routingProperties.maxRides;
    }

    public void setMaxRides(int maxRides) {
        this.routingProperties.maxRides = maxRides;
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
        Utils.setLogMode("ERROR");
    }

    public void verboseMode() {
        Utils.setLogMode("ALL");
    }

    private TransportNetwork transportNetwork;

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(R5RCore.class);

    public R5RCore(String dataFolder) throws FileNotFoundException {
        this(dataFolder, true);
    }

    public R5RCore(String dataFolder, boolean verbose) throws FileNotFoundException {
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

    public List<LinkedHashMap<String, ArrayList<Object>>> detailedItineraries(String fromId, double fromLat, double fromLon, String toId, double toLat, double toLon,
                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                   String date, String departureTime, int maxWalkTime, int maxTripDuration,
                                                                   boolean dropItineraryGeometry) throws ParseException, ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};
        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return detailedItineraries(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxTripDuration, dropItineraryGeometry);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> detailedItineraries(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                            String[] toIds, double[] toLats, double[] toLons,
                                                                            String directModes, String transitModes, String accessModes, String egressModes,
                                                                            String date, String departureTime, int maxWalkTime, int maxTripDuration,
                                                                            boolean dropItineraryGeometry) throws ExecutionException, InterruptedException {

        DetailedItineraryPlanner detailedItineraryPlanner = new DetailedItineraryPlanner(this.r5rThreadPool, this.transportNetwork, this.routingProperties);
        detailedItineraryPlanner.setOrigins(fromIds, fromLats, fromLons);
        detailedItineraryPlanner.setDestinations(toIds, toLats, toLons);
        detailedItineraryPlanner.setModes(directModes, accessModes, transitModes, egressModes);
        detailedItineraryPlanner.setDepartureDateTime(date, departureTime);
        detailedItineraryPlanner.setTripDuration(maxWalkTime, maxTripDuration);
        if (dropItineraryGeometry) { detailedItineraryPlanner.dropItineraryGeometry(); }

        return detailedItineraryPlanner.run();
    }









    public List<LinkedHashMap<String, ArrayList<Object>>> travelTimeMatrixParallel(String fromId, double fromLat, double fromLon,
                                                                                   String[] toIds, double[] toLats, double[] toLons,
                                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                                   String date, String departureTime,
                                                                                   int maxWalkTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        return travelTimeMatrixParallel(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxTripDuration);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> travelTimeMatrixParallel(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                                   String toId, double toLat, double toLon,
                                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                                   String date, String departureTime,
                                                                                   int maxWalkTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return travelTimeMatrixParallel(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxTripDuration);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> travelTimeMatrixParallel(String fromId, double fromLat, double fromLon,
                                                                                   String toId, double toLat, double toLon,
                                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                                   String date, String departureTime,
                                                                                   int maxWalkTime, int maxTripDuration) throws ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};

        String[] toIds = {toId};
        double[] toLats = {toLat};
        double[] toLons = {toLon};

        return travelTimeMatrixParallel(fromIds, fromLats, fromLons, toIds, toLats, toLons,
                directModes, transitModes, accessModes, egressModes, date, departureTime, maxWalkTime, maxTripDuration);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> travelTimeMatrixParallel(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                                   String[] toIds, double[] toLats, double[] toLons,
                                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                                   String date, String departureTime,
                                                                                   int maxWalkTime, int maxTripDuration) throws ExecutionException, InterruptedException {
        int[] originIndices = new int[fromIds.length];
        for (int i = 0; i < fromIds.length; i++) originIndices[i] = i;

        ByteArrayOutputStream dataStream = new ByteArrayOutputStream();
        DataOutputStream pointStream = new DataOutputStream(dataStream);

        try {
            pointStream.writeInt(toIds.length);
            for (String toId : toIds) {
                pointStream.writeUTF(toId);
            }
            for (double toLat : toLats) {
                pointStream.writeDouble(toLat);
            }
            for (double toLon : toLons) {
                pointStream.writeDouble(toLon);
            }
            for (int i = 0; i < toIds.length; i++) {
                pointStream.writeDouble(1.0);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        ByteArrayInputStream pointsInput = new ByteArrayInputStream(dataStream.toByteArray());

        FreeFormPointSet destinationPoints = null;
        try {
            destinationPoints = new FreeFormPointSet(pointsInput);
        } catch (IOException e) {
            e.printStackTrace();
        }

        String[] modes = accessModes.split(";");
        if (!accessModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                transportNetwork.linkageCache.getLinkage(destinationPoints, transportNetwork.streetLayer, StreetMode.valueOf(mode));
            }
        }

        FreeFormPointSet finalDestinationPoints = destinationPoints;
        List<LinkedHashMap<String, ArrayList<Object>>> returnList;
        returnList = r5rThreadPool.submit(() ->
                Arrays.stream(originIndices).parallel()
                        .mapToObj(index -> {
                            LinkedHashMap<String, ArrayList<Object>> results =
                                    null;
                            try {
                                results = travelTimesFromOrigin(fromIds[index], fromLats[index], fromLons[index],
                                        toIds, toLats, toLons, directModes, transitModes, accessModes, egressModes,
                                        date, departureTime, maxWalkTime, maxTripDuration, finalDestinationPoints);
                            } catch (ParseException e) {
                                e.printStackTrace();
                            }
                            return results;
                        }).collect(Collectors.toList())).get();

        return returnList;
    }

    private LinkedHashMap<String, ArrayList<Object>> travelTimesFromOrigin(String fromId, double fromLat, double fromLon,
                                                                           String[] toIds, double[] toLats, double[] toLons,
                                                                           String directModes, String transitModes, String accessModes, String egressModes,
                                                                           String date, String departureTime,
                                                                           int maxWalkTime, int maxTripDuration, FreeFormPointSet destinationPoints) throws ParseException {

        RegionalTask request = new RegionalTask();

        request.scenario = new Scenario();
        request.scenario.id = "id";
        request.scenarioId = request.scenario.id;

        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.walkSpeed = (float) this.routingProperties.walkSpeed;
        request.bikeSpeed = (float) this.routingProperties.bikeSpeed;
        request.streetTime = maxTripDuration;
        request.maxWalkTime = maxWalkTime;
        request.maxBikeTime = maxTripDuration;
        request.maxCarTime = maxTripDuration;
        request.maxTripDurationMinutes = maxTripDuration;
        request.makeTauiSite = false;
//        request.computePaths = false;
//        request.computeTravelTimeBreakdown = false;
        request.recordTimes = true;
        request.maxRides = this.routingProperties.maxRides;
        request.bikeTrafficStress = this.routingProperties.maxLevelTrafficStress;

        request.directModes = Utils.setLegModes(directModes);
        request.accessModes = Utils.setLegModes(accessModes);
        request.egressModes = Utils.setLegModes(egressModes);
        request.transitModes = Utils.setTransitModes(transitModes);

        request.date = LocalDate.parse(date);

        int secondsFromMidnight = Utils.getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + (this.routingProperties.timeWindowSize * 60);

        request.monteCarloDraws = this.routingProperties.numberOfMonteCarloDraws;

        request.destinationPointSets = new PointSet[1];
        request.destinationPointSets[0] = destinationPoints;

        request.percentiles = this.percentiles;

        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);

        OneOriginResult travelTimeResults = computer.computeTravelTimes();

        // Build return table
        RDataFrame travelTimesTable = new RDataFrame();
        travelTimesTable.addStringColumn("fromId", fromId);
        travelTimesTable.addStringColumn("toId", "");

        if (percentiles.length == 1) {
            travelTimesTable.addIntegerColumn("travel_time", Integer.MAX_VALUE);
        } else {
            for (int p : percentiles) {
                String ps = String.format("%03d", p);
                travelTimesTable.addIntegerColumn("travel_time_p" + ps, Integer.MAX_VALUE);
            }
        }

        for (int i = 0; i < travelTimeResults.travelTimes.nPoints; i++) {
            if (travelTimeResults.travelTimes.getValues()[0][i] <= maxTripDuration) {
                travelTimesTable.append();
                travelTimesTable.set("toId", toIds[i]);
                if (percentiles.length == 1) {
                    travelTimesTable.set("travel_time", travelTimeResults.travelTimes.getValues()[0][i]);
                } else {
                    for (int p = 0; p < percentiles.length; p++) {
                        int tt = travelTimeResults.travelTimes.getValues()[p][i];
                        String ps = String.format("%03d", percentiles[p]);
                        if (tt < maxTripDuration) {
                            travelTimesTable.set("travel_time_p" + ps, tt);
                        }
                    }
                }
            }
        }

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable.getDataFrame();
        } else {
            return null;
        }
    }

    public List<Object> getStreetNetwork() {
        // Convert R5's transport network to Simple Features objects
        StreetNetwork streetNetwork = new StreetNetwork(this.transportNetwork);

        // Return a list of dataframes
        List<Object> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(streetNetwork.verticesTable.getDataFrame());
        transportNetworkList.add(streetNetwork.edgesTable.getDataFrame());

        return transportNetworkList;
    }

    public LinkedHashMap<String, ArrayList<Object>> getEdges() {
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

        return edgesTable.getDataFrame();
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


    public List<Object> getTransitNetwork() {
        // Build transit network

        // routes and shape geometries
        RDataFrame routesTable = new RDataFrame();
        routesTable.addStringColumn("agency_id", "");
        routesTable.addStringColumn("agency_name", "");
        routesTable.addStringColumn("route_id", "");
        routesTable.addStringColumn("long_name", "");
        routesTable.addStringColumn("short_name", "");
        routesTable.addStringColumn("mode", "");
        routesTable.addStringColumn("geometry", "");

        for (TripPattern pattern : transportNetwork.transitLayer.tripPatterns) {
            RouteInfo route = transportNetwork.transitLayer.routes.get(pattern.routeIndex);

            routesTable.append();
            routesTable.set("agency_id", route.agency_id);
            routesTable.set("agency_name", route.agency_name);
            routesTable.set("route_id", route.route_id);
            routesTable.set("long_name", route.route_long_name);
            routesTable.set("short_name", route.route_short_name);
            routesTable.set("mode", TransitLayer.getTransitModes(route.route_type).toString());

            if (pattern.shape != null) {
                routesTable.set("geometry", pattern.shape.toString());
            } else {
                // build geometry from stops
                StringBuilder geometry = new StringBuilder();
                for (int stopIndex : pattern.stops) {
                    Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIndex);

                    if (coordinate != null) {
                        coordinate.x = coordinate.x / FIXED_FACTOR;
                        coordinate.y = coordinate.y / FIXED_FACTOR;

                        if (geometry.toString().equals("")) {
                            geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                        } else {
                            geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                        }
                    }
                }
                if (!geometry.toString().equals("")) {
                    geometry.append(")");
                }
                routesTable.set("geometry", geometry.toString());
            }
        }

        // stops
        RDataFrame stopsTable = new RDataFrame();
        stopsTable.addIntegerColumn("stop_index", -1);
        stopsTable.addStringColumn("stop_id", "");
        stopsTable.addStringColumn("stop_name", "");
        stopsTable.addDoubleColumn("lat", -1.0);
        stopsTable.addDoubleColumn("lon", -1.0);
        stopsTable.addBooleanColumn("linked_to_street", false);

        LOG.info("Getting public transport stops from Transport Network");
        LOG.info("{} stops were found in the network", transportNetwork.transitLayer.getStopCount());

        for (int stopIndex = 0; stopIndex < transportNetwork.transitLayer.getStopCount(); stopIndex++) {
            LOG.info("Stop #{}", stopIndex);
            LOG.info("Stop id: {}", transportNetwork.transitLayer.stopIdForIndex.get(stopIndex));

            stopsTable.append();
            stopsTable.set("stop_index", stopIndex);
            stopsTable.set("stop_id", transportNetwork.transitLayer.stopIdForIndex.get(stopIndex));

            if (transportNetwork.transitLayer.stopNames != null) {
                LOG.info("Stop name: {}", transportNetwork.transitLayer.stopNames.get(stopIndex));
                stopsTable.set("stop_name", transportNetwork.transitLayer.stopNames.get(stopIndex));
            }

            Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIndex);
            if (coordinate != null) {
                Double lat = coordinate.y / FIXED_FACTOR;
                Double lon = coordinate.x / FIXED_FACTOR;
                stopsTable.set("lat", lat);
                stopsTable.set("lon", lon);
            }

            boolean linkedToStreet = (transportNetwork.transitLayer.streetVertexForStop.get(stopIndex) != -1);
            stopsTable.set("linked_to_street", linkedToStreet);
        }

        // Return a list of dataframes
        List<Object> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(routesTable.getDataFrame());
        transportNetworkList.add(stopsTable.getDataFrame());

        return transportNetworkList;
    }

    // Returns list of public transport services active on a given date
    public LinkedHashMap<String, ArrayList<Object>> getTransitServicesByDate(String date) {
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

        return servicesTable.getDataFrame();
    }


    public List<LinkedHashMap<String, ArrayList<Object>>> isochrones(String[] fromId, double[] fromLat, double[] fromLon, int cutoffs, int zoom,
                                                               String directModes, String transitModes, String accessModes, String egressModes,
                                                               String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {
        int[] cutoffTimes = new int[1];
        cutoffTimes[0] = cutoffs;

        return isochrones(fromId, fromLat, fromLon, cutoffTimes, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxTripDuration);
    }

    public List<LinkedHashMap<String, ArrayList<Object>>> isochrones(String fromId, double fromLat, double fromLon, int cutoffs, int zoom,
                                                               String directModes, String transitModes, String accessModes, String egressModes,
                                                               String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        String[] fromIds = {fromId};
        double[] fromLats = {fromLat};
        double[] fromLons = {fromLon};
        int[] cutoffTimes = {cutoffs};

        return isochrones(fromIds, fromLats, fromLons, cutoffTimes, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxTripDuration);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> isochrones(String[] fromId, double[] fromLat, double[] fromLon, int[] cutoffs, int zoom,
                                                               String directModes, String transitModes, String accessModes, String egressModes,
                                                               String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        // Instantiate IsochroneBuilder object and set properties
        IsochroneBuilder isochroneBuilder = new IsochroneBuilder(r5rThreadPool, this.transportNetwork, this.routingProperties);
        isochroneBuilder.setOrigins(fromId, fromLat, fromLon);
        isochroneBuilder.setModes(directModes, accessModes, transitModes, egressModes);
        isochroneBuilder.setDepartureDateTime(date, departureTime);
        isochroneBuilder.setTripDuration(maxWalkTime, maxTripDuration);
        isochroneBuilder.setCutoffs(cutoffs);
        isochroneBuilder.setResolution(zoom);

        // Build isochrones and return data to R as a list of data.frames
        return isochroneBuilder.run();
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
}
