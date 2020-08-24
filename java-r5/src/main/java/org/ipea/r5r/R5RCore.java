package org.ipea.r5r;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.AnalysisTask;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.VertexStore;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import org.locationtech.jts.geom.Coordinate;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.Collectors;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class R5RCore {

    private int numberOfThreads;
    ForkJoinPool r5rThreadPool;

    public double getWalkSpeed() {
        return walkSpeed;
    }

    public void setWalkSpeed(double walkSpeed) {
        this.walkSpeed = walkSpeed;
    }

    public double getBikeSpeed() {
        return bikeSpeed;
    }

    public void setBikeSpeed(double bikeSpeed) {
        this.bikeSpeed = bikeSpeed;
    }

    private double walkSpeed;
    private double bikeSpeed;

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
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.ERROR);
    }

    public void verboseMode() {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.INFO);
    }

    public void setLogMode(String mode) {
        Logger root = (Logger) LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);
        root.setLevel(Level.valueOf(mode));
    }

    private TransportNetwork transportNetwork;
//    private LinkedHashMap<String, Object> pathOptionsTable;

    public R5RCore(String dataFolder) {
        this(dataFolder, true);
    }

     public R5RCore(String dataFolder, boolean verbose) {
        if (verbose) {
            verboseMode();
        } else {
            silentMode();
        }

        setNumberOfThreadsToMax();

        this.walkSpeed = 1.0f;
        this.bikeSpeed = 3.3f;

        File file = new File(dataFolder + "network.dat");
        if (!file.isFile()) {
            // network.dat file does not exist. create!
            transportNetwork = TransportNetwork.fromDirectory(new File(dataFolder));
            try {
                KryoNetworkSerializer.write(transportNetwork, new File(dataFolder, "network.dat"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        try {
            transportNetwork = KryoNetworkSerializer.read(new File(dataFolder, "network.dat"));
//            transportNetwork.readOSM(new File(dir, "osm.mapdb"));
            transportNetwork.transitLayer.buildDistanceTables(null);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

//    public void loadDestinationPointsFromCsv(String csvFile) {
//        CSVInputStreamProvider csvInputStream;
//        try {
//            csvInputStream = new CSVInputStreamProvider(csvFile);
//            destinationPointSet = FreeFormPointSet.fromCsv(csvInputStream, "lat", "lon", "id", "count");
//        } catch (IOException e) {
//            e.printStackTrace();
//        }
//    }

    public List<LinkedHashMap<String, ArrayList<Object>>> planMultipleTrips(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                            String[] toIds, double[] toLats, double[] toLons,
                                                                            String directModes, String transitModes, String accessModes, String egressModes,
                                                                            String date, String departureTime, int maxWalkTime, int maxTripDuration,
                                                                            boolean dropItineraryGeometry) throws ExecutionException, InterruptedException {

        int[] requestIndices = new int[fromIds.length];
        for (int i = 0; i < fromIds.length; i++) requestIndices[i] = i;

        return r5rThreadPool.submit(() ->
                Arrays.stream(requestIndices).parallel()
                        .mapToObj(index -> {
                            LinkedHashMap<String, ArrayList<Object>> results =
                                    null;
                            try {
                                results = planSingleTrip(fromIds[index], fromLats[index], fromLons[index],
                                        toIds[index], toLats[index], toLons[index],
                                        directModes, transitModes, accessModes, egressModes, date, departureTime,
                                        maxWalkTime, maxTripDuration, dropItineraryGeometry);
                            } catch (ParseException e) {
                                e.printStackTrace();
                            }
                            return results;
                        }).
                        collect(Collectors.toList())).get();
    }

    public LinkedHashMap<String, ArrayList<Object>> planSingleTrip(String fromId, double fromLat, double fromLon, String toId, double toLat, double toLon,
                                                                   String directModes, String transitModes, String accessModes, String egressModes,
                                                                   String date, String departureTime, int maxWalkTime, int maxTripDuration,
                                                                   boolean dropItineraryGeometry) throws ParseException {
        AnalysisTask request = new RegionalTask();
        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.toLat = toLat;
        request.toLon = toLon;
        request.streetTime = maxTripDuration;
        request.maxWalkTime = maxWalkTime;
        request.maxBikeTime = maxTripDuration;
        request.maxCarTime = maxTripDuration;
        request.walkSpeed = (float) this.walkSpeed;
        request.bikeSpeed = (float) this.bikeSpeed;
        request.maxTripDurationMinutes = maxTripDuration;
        request.computePaths = true;
        request.computeTravelTimeBreakdown = true;

        request.directModes = EnumSet.noneOf(LegMode.class);
        String[] modes = directModes.split(";");
        if (!directModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.directModes.add(LegMode.valueOf(mode));
            }
        }

        request.transitModes = EnumSet.noneOf(TransitModes.class);
        modes = transitModes.split(";");
        if (!transitModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.transitModes.add(TransitModes.valueOf(mode));
            }
        }

        request.accessModes = EnumSet.noneOf(LegMode.class);
        modes = accessModes.split(";");
        if (!accessModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.accessModes.add(LegMode.valueOf(mode));
            }
        }

        request.egressModes = EnumSet.noneOf(LegMode.class);
        modes = egressModes.split(";");
        if (!egressModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.egressModes.add(LegMode.valueOf(mode));
            }
        }

        request.date = LocalDate.parse(date);

        int secondsFromMidnight = getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + 60;

        request.monteCarloDraws = 1;

        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response = query.getPlan(request);

        if (!response.getOptions().isEmpty()) {
            return buildPathOptionsTable(fromId, fromLat, fromLon, toId, toLat, toLon,
                    maxWalkTime, dropItineraryGeometry, response.getOptions());
        } else {
            return null;
        }
    }

    private int getSecondsFromMidnight(String departureTime) throws ParseException {
        DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");
        Date reference = dateFormat.parse("00:00:00");
        Date date = dateFormat.parse(departureTime);
        return (int) ((date.getTime() - reference.getTime()) / 1000L);
    }

    private LinkedHashMap<String, ArrayList<Object>> buildPathOptionsTable(String fromId, double fromLat, double fromLon,
                                                                           String toId, double toLat, double toLon,
                                                                           int maxWalkTime, boolean dropItineraryGeometry,
                                                                           List<ProfileOption> pathOptions) {
        RDataFrame pathOptionsTable = new RDataFrame();
        pathOptionsTable.addStringColumn("fromId", fromId);
        pathOptionsTable.addDoubleColumn("fromLat", fromLat);
        pathOptionsTable.addDoubleColumn("fromLon", fromLon);
        pathOptionsTable.addStringColumn("toId", toId);
        pathOptionsTable.addDoubleColumn("toLat", toLat);
        pathOptionsTable.addDoubleColumn("toLon", toLon);
        pathOptionsTable.addIntegerColumn("option", 0);
        pathOptionsTable.addIntegerColumn("segment", 0);
        pathOptionsTable.addStringColumn("mode", "");
        pathOptionsTable.addDoubleColumn("duration", 0.0);
        pathOptionsTable.addIntegerColumn("distance", 0);
        pathOptionsTable.addStringColumn("route", "");
        pathOptionsTable.addIntegerColumn("wait", 0);
        if (!dropItineraryGeometry) pathOptionsTable.addStringColumn("geometry", "");

        int optionIndex = 0;
        for (ProfileOption option : pathOptions) {
            if (option.transit == null) { // no transit, maybe has direct access legs

                if (option.access != null) {
                    for (StreetSegment segment : option.access) {

                        // maxStreetTime parameter only affects access and egress walking segments, but no direct trips
                        // if a direct walking trip is found that is longer than maxWalkTime, then drop it
                        if (segment.mode == LegMode.WALK & (segment.duration / 60) > maxWalkTime) continue;
                        pathOptionsTable.append();

                        optionIndex++;
                        pathOptionsTable.set("option", optionIndex);
                        pathOptionsTable.set("segment", 1);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("duration", Utils.roundTo2(segment.duration / 60.0));

                        // segment.distance value is inaccurate, so it's better to get distances from street edges
                        int dist = 0;
                        for (int i = 0; i < segment.streetEdges.size(); i++) {
                            dist += segment.streetEdges.get(i).distance;
                        }
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

            } else { // option has transit
                optionIndex++;
                int segmentIndex = 0;

                // first leg: access to station
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {
                        pathOptionsTable.append();

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("duration", Utils.roundTo2(segment.duration / 60.0));

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = 0;
                        for (int i = 0; i < segment.streetEdges.size(); i++) {
                            dist += segment.streetEdges.get(i).distance;
                        }
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

                for (TransitSegment transit : option.transit) {

                    for (SegmentPattern pattern : transit.segmentPatterns) {
                        pathOptionsTable.append();

                        segmentIndex++;
                        TripPattern tripPattern = transportNetwork.transitLayer.tripPatterns.get(pattern.patternIdx);

                        StringBuilder geometry = new StringBuilder("NA");
                        org.locationtech.jts.geom.Coordinate previousCoord = new Coordinate(0, 0);
                        double accDistance = 0;

                        for (int stop = pattern.fromIndex; stop <= pattern.toIndex; stop++) {
                            int stopIdx = tripPattern.stops[stop];
                            org.locationtech.jts.geom.Coordinate coord = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIdx);

                            coord.x = coord.x / FIXED_FACTOR;
                            coord.y = coord.y / FIXED_FACTOR;

                            if (geometry.toString().equals("NA")) {
                                geometry = new StringBuilder("LINESTRING (" + coord.x + " " + coord.y);
                                previousCoord.x = coord.x;
                                previousCoord.y = coord.y;
                            } else {
                                geometry.append(", ").append(coord.x).append(" ").append(coord.y);
                                accDistance +=  GeometryUtils.distance(previousCoord.y, previousCoord.x, coord.y, coord.x);
                                previousCoord.x = coord.x;
                                previousCoord.y = coord.y;
                            }
                        }
                        geometry.append(")");

                        pathOptionsTable.set("option", optionIndex);
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.mode.toString());
                        pathOptionsTable.set("duration", Utils.roundTo2(transit.rideStats.avg / 60.0));
                        pathOptionsTable.set("distance", (int) accDistance);
                        pathOptionsTable.set("route", tripPattern.routeId);
                        pathOptionsTable.set("wait", transit.waitStats.avg);
                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", geometry.toString());
                    }

                    if (transit.middle != null) {
                        pathOptionsTable.append();

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.middle.mode.toString());
                        pathOptionsTable.set("duration", Utils.roundTo2(transit.middle.duration / 60.0));

                        // getting distances from street edges, which are more accurate than segment.distance
                        int dist = 0;
                        for (int i = 0; i < transit.middle.streetEdges.size(); i++) {
                            dist += transit.middle.streetEdges.get(i).distance;
                        }
                        pathOptionsTable.set("distance", dist / 1000);
                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", transit.middle.geometry.toString());
                    }
                }

                // first leg: access to station
                if (option.egress != null) {
                    for (StreetSegment segment : option.egress) {
                        pathOptionsTable.append();

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("duration", Utils.roundTo2(segment.duration / 60.0));

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = 0;
                        for (int i = 0; i < segment.streetEdges.size(); i++) {
                            dist += segment.streetEdges.get(i).distance;
                        }
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }
            }
        }

        return pathOptionsTable.getDataFrame();
    }

    public List<LinkedHashMap<String, Object>> travelTimeMatrixParallel(String[] fromIds, double[] fromLats, double[] fromLons,
                                                                        String[] toIds, double[] toLats, double[] toLons,
                                                                        String directModes, String transitModes, String accessModes, String egressModes,
                                                                        String date, String departureTime,
                                                                        int maxWalkTime, int maxTripDuration) throws ExecutionException, InterruptedException {
        int[] originIndices = new int[fromIds.length];
        for (int i = 0; i < fromIds.length; i++) originIndices[i] = i;

        return r5rThreadPool.submit(() ->
                Arrays.stream(originIndices).parallel()
                .mapToObj(index -> {
                    LinkedHashMap<String, Object> results =
                            null;
                    try {
                        results = travelTimesFromOrigin(fromIds[index], fromLats[index], fromLons[index],
                                toIds, toLats, toLons, directModes, transitModes, accessModes, egressModes,
                                date, departureTime, maxWalkTime, maxTripDuration);
                    } catch (ParseException e) {
                        e.printStackTrace();
                    }
                    return results;
                }).collect(Collectors.toList())).get();
    }

    public LinkedHashMap<String, Object> travelTimesFromOrigin(String fromId, double fromLat, double fromLon,
                                                  String[] toIds, double[] toLats, double[] toLons,
                                                  String directModes, String transitModes, String accessModes, String egressModes,
                                                               String date, String departureTime,
                                                  int maxWalkTime, int maxTripDuration) throws ParseException {

        RegionalTask request = new RegionalTask();

        request.scenario = new Scenario();
        request.scenario.id = "id";
        request.scenarioId = request.scenario.id;

        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.walkSpeed = (float) this.walkSpeed;
        request.bikeSpeed = (float) this.bikeSpeed;
        request.streetTime = maxTripDuration;
        request.maxWalkTime = maxWalkTime;
        request.maxBikeTime = maxTripDuration;
        request.maxCarTime = maxTripDuration;
        request.maxTripDurationMinutes = maxTripDuration;
        request.makeTauiSite = false;
        request.computePaths = false;
        request.computeTravelTimeBreakdown = false;
        request.recordTimes = true;

        request.directModes = EnumSet.noneOf(LegMode.class);
        String[] modes = directModes.split(";");
        if (!directModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.directModes.add(LegMode.valueOf(mode));
            }
        }

        request.transitModes = EnumSet.noneOf(TransitModes.class);
        modes = transitModes.split(";");
        if (!transitModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.transitModes.add(TransitModes.valueOf(mode));
            }
        }

        request.accessModes = EnumSet.noneOf(LegMode.class);
        modes = accessModes.split(";");
        if (!accessModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.accessModes.add(LegMode.valueOf(mode));
            }
        }

        request.egressModes = EnumSet.noneOf(LegMode.class);
        modes = egressModes.split(";");
        if (!egressModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                request.egressModes.add(LegMode.valueOf(mode));
            }
        }

        request.date = LocalDate.parse(date);

        int secondsFromMidnight = getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + 60;

        request.monteCarloDraws = 1;


        request.destinationPointSet = new FreeFormPointSet(toIds.length);
        for (int i = 0; i < toIds.length; i++) {
            ((FreeFormPointSet)request.destinationPointSet).setId(i, toIds[i]);
            ((FreeFormPointSet)request.destinationPointSet).setLat(i, toLats[i]);
            ((FreeFormPointSet)request.destinationPointSet).setLon(i, toLons[i]);
            ((FreeFormPointSet)request.destinationPointSet).setCount(i, 1);
        }

//        request.inRoutingFareCalculator = fareCalculator;

        request.percentiles = new int[1];
        request.percentiles[0] = 100;
//        request.percentiles = new int[100];
//        for (int i = 1; i <= 100; i++) request.percentiles[i - 1] = i;

        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);

        OneOriginResult travelTimeResults = computer.computeTravelTimes();

        // Build return table
        ArrayList<String> fromIdCol = new ArrayList<>();
//        ArrayList<Double> fromLatCol = new ArrayList<>();
//        ArrayList<Double> fromLonCol = new ArrayList<>();

        ArrayList<String> idCol = new ArrayList<>();
//        ArrayList<Double> latCol = new ArrayList<>();
//        ArrayList<Double> lonCol = new ArrayList<>();

        ArrayList<Integer> travelTimeCol = new ArrayList<>();

        for (int i = 0; i < travelTimeResults.travelTimes.nPoints; i++) {
            if (travelTimeResults.travelTimes.getValues()[0][i] <= maxTripDuration) {
                fromIdCol.add(fromId);
//                fromLatCol.add(fromLat);
//                fromLonCol.add(fromLon);

                idCol.add(toIds[i]);
//                latCol.add(toLats[i]);
//                lonCol.add(toLons[i]);

                travelTimeCol.add(travelTimeResults.travelTimes.getValues()[0][i]);
            }
        }

        LinkedHashMap<String, Object> results = new LinkedHashMap<>();
        results.put("fromId", fromIdCol);
//        results.put("fromLat", fromLatCol);
//        results.put("fromLon", fromLonCol);
        results.put("toId", idCol);
//        results.put("toLat", latCol);
//        results.put("toLon", lonCol);
        results.put("travel_time", travelTimeCol);

        return results;
    }

    public List<Object> getStreetNetwork() {
        // Build vertices return table
        ArrayList<Integer> indexCol = new ArrayList<>();
        ArrayList<Double> latCol = new ArrayList<>();
        ArrayList<Double> lonCol = new ArrayList<>();

        LinkedHashMap<String, Object> verticesTable = new LinkedHashMap<>();
        verticesTable.put("index", indexCol);
        verticesTable.put("lat", latCol);
        verticesTable.put("lon", lonCol);

        VertexStore vertices = transportNetwork.streetLayer.vertexStore;

        VertexStore.Vertex vertexCursor = vertices.getCursor();
        while (vertexCursor.advance()) {
            indexCol.add(vertexCursor.index);
            latCol.add(vertexCursor.getLat());
            lonCol.add(vertexCursor.getLon());
        }

        // Build edges return table
        ArrayList<Integer> fromVertexCol = new ArrayList<>();
        ArrayList<Integer> toVertexCol = new ArrayList<>();
        ArrayList<Double> lengthCol = new ArrayList<>();
        ArrayList<Double> lengthGeoCol = new ArrayList<>();
        ArrayList<String> geometryCol = new ArrayList<>();

        LinkedHashMap<String, Object> edgesTable = new LinkedHashMap<>();
        edgesTable.put("fromVertex", fromVertexCol);
        edgesTable.put("toVertex", toVertexCol);
        edgesTable.put("length", lengthCol);
        edgesTable.put("lengthGeo", lengthGeoCol);
        edgesTable.put("geometry", geometryCol);

        EdgeStore edges = transportNetwork.streetLayer.edgeStore;

        EdgeStore.Edge edgeCursor = edges.getCursor();
        while (edgeCursor.advance()) {
            fromVertexCol.add(edgeCursor.getFromVertex());
            toVertexCol.add(edgeCursor.getToVertex());
            lengthCol.add(edgeCursor.getLengthM());
            lengthGeoCol.add(edgeCursor.getGeometry().getLength());
            geometryCol.add(edgeCursor.getGeometry().toString());
        }

        // Return a list of dataframes
        List<Object> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(verticesTable);
        transportNetworkList.add(edgesTable);

        return transportNetworkList;
    }
}
