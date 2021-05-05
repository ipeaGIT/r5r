package org.ipea.r5r;

import com.conveyal.gtfs.model.Service;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.*;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.EdgeTraversalTimes;
import com.conveyal.r5.streets.VertexStore;
import com.conveyal.r5.transit.TripPattern;
import com.conveyal.r5.transit.*;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.LineString;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.text.ParseException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;
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
        RegionalTask request = new RegionalTask();
        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.toLat = toLat;
        request.toLon = toLon;
        request.streetTime = maxTripDuration;
        request.maxWalkTime = maxWalkTime;
        request.maxBikeTime = maxTripDuration;
        request.maxCarTime = maxTripDuration;
        request.walkSpeed = (float) this.routingProperties.walkSpeed;
        request.bikeSpeed = (float) this.routingProperties.bikeSpeed;
        request.maxTripDurationMinutes = maxTripDuration;
//        request.computePaths = true;
//        request.computeTravelTimeBreakdown = true;
        request.maxRides = this.routingProperties.maxRides;
        request.bikeTrafficStress = this.routingProperties.maxLevelTrafficStress;

        request.suboptimalMinutes = this.routingProperties.suboptimalMinutes;

        request.directModes = Utils.setLegModes(directModes);
        request.accessModes = Utils.setLegModes(accessModes);
        request.egressModes = Utils.setLegModes(egressModes);
        request.transitModes = Utils.setTransitModes(transitModes);

        request.date = LocalDate.parse(date);

        int secondsFromMidnight = Utils.getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + (this.routingProperties.timeWindowSize * 60);
//        request.toTime = secondsFromMidnight + 60; // 1 minute, ignoring time window parameter (this.timeWindowSize * 60);

//        LOG.info("from time {}", request.fromTime);
//        LOG.info("to time {}", request.toTime);

        request.monteCarloDraws = this.routingProperties.numberOfMonteCarloDraws;

        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response = null;
        try {
            response = query.getPlan(request);
        } catch (IllegalStateException e) {
            LOG.error(String.format("Error (*illegal state*) while finding path between %s and %s", fromId, toId));
            LOG.error(e.getMessage());
            return null;
        } catch (ArrayIndexOutOfBoundsException e) {
            LOG.error(String.format("Error (*array out of bounds*) while finding path between %s and %s", fromId, toId));
            LOG.error(e.getMessage());
            return null;
        } catch (Exception e) {
            LOG.error(String.format("Error while finding path between %s and %s", fromId, toId));
            LOG.error(e.getMessage());
            return null;
        }

        if (!response.getOptions().isEmpty()) {
            LinkedHashMap<String, ArrayList<Object>> pathOptionsTable;

            try {
                // if only the shortest path is requested, return min travel times instead of avg
                boolean shortestPath = (this.routingProperties.suboptimalMinutes == 0);

                pathOptionsTable = buildPathOptionsTable(fromId, fromLat, fromLon, toId, toLat, toLon,
                        maxWalkTime, maxTripDuration, shortestPath, dropItineraryGeometry, response.getOptions());
            } catch (Exception e) {
                LOG.error(String.format("Error while collecting paths between %s and %s", fromId, toId));
                return null;
            }

            return pathOptionsTable;
        } else {
            return null;
        }
    }


    private LinkedHashMap<String, ArrayList<Object>> buildPathOptionsTable(String fromId, double fromLat, double fromLon,
                                                                           String toId, double toLat, double toLon,
                                                                           int maxWalkTime, int maxTripDuration,
                                                                           boolean shortestPath,
                                                                           boolean dropItineraryGeometry,
                                                                           List<ProfileOption> pathOptions) {

        // Build data.frame to return data to R in tabular form
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
        pathOptionsTable.addIntegerColumn("total_duration", 0);
        pathOptionsTable.addDoubleColumn("segment_duration", 0.0);
        pathOptionsTable.addDoubleColumn("wait", 0.0);
        pathOptionsTable.addIntegerColumn("distance", 0);
        pathOptionsTable.addStringColumn("route", "");
        pathOptionsTable.addStringColumn("board_time", "");
        pathOptionsTable.addStringColumn("alight_time", "");
        if (!dropItineraryGeometry) pathOptionsTable.addStringColumn("geometry", "");

        LOG.info("Building itinerary options table.");
        LOG.info("{} itineraries found.", pathOptions.size());

        int optionIndex = 0;
        for (ProfileOption option : pathOptions) {
            LOG.info("Itinerary option {} of {}: {}", optionIndex + 1, pathOptions.size(), option.summary);

            LOG.info("travel time min {}, avg {}", option.stats.min, option.stats.avg);
            if (option.stats.avg > (maxTripDuration * 60)) continue;

            if (option.transit == null) { // no transit, maybe has direct access legs
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {

                        // maxStreetTime parameter only affects access and egress walking segments, but no direct trips
                        // if a direct walking trip is found that is longer than maxWalkTime, then drop it
                        LOG.info("segment duration {}", segment.duration);
                        if (segment.mode == LegMode.WALK & (segment.duration / 60) > maxWalkTime) continue;
                        pathOptionsTable.append();

                        LOG.info("  direct {}", segment.toString());

                        optionIndex++;
                        pathOptionsTable.set("option", optionIndex);
                        pathOptionsTable.set("segment", 1);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // segment.distance value is inaccurate, so it's better to get distances from street edges
                        int dist = calculateSegmentLength(segment);
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

                        LOG.info("  access {}", segment.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);

                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

                for (TransitSegment transit : option.transit) {

                    if (!transit.segmentPatterns.isEmpty()) {
//                    for (SegmentPattern pattern : transit.segmentPatterns) {
                        // Use only first of many possible repeated patterns
                        SegmentPattern pattern = transit.segmentPatterns.get(0);
                        if (pattern != null) {

                            LOG.info("  transit pattern index {}", pattern.patternIdx);

                            TripPattern tripPattern = transportNetwork.transitLayer.tripPatterns.get(pattern.patternIdx);

                            if (tripPattern != null) {
                                pathOptionsTable.append();

                                segmentIndex++;

                                StringBuilder geometry = new StringBuilder();
                                int accDistance = 0;

                                try {
                                    accDistance = buildTransitGeometryAndCalculateDistance(pattern, tripPattern, geometry);
                                } catch (Exception e) {
                                    geometry = new StringBuilder("LINESTRING EMPTY");
                                }

                                pathOptionsTable.set("option", optionIndex);
                                pathOptionsTable.set("segment", segmentIndex);
                                pathOptionsTable.set("mode", transit.mode.toString());

                                if (shortestPath) {
                                    pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                                    pathOptionsTable.set("segment_duration", transit.rideStats.min / 60.0);
                                    pathOptionsTable.set("wait", transit.waitStats.min / 60.0);
                                } else {
                                    pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                                    pathOptionsTable.set("segment_duration", transit.rideStats.avg / 60.0);
                                    pathOptionsTable.set("wait", transit.waitStats.avg / 60.0);
                                }

                                pathOptionsTable.set("distance", accDistance);
                                pathOptionsTable.set("route", tripPattern.routeId);

                                pathOptionsTable.set("board_time", pattern.fromDepartureTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));
                                pathOptionsTable.set("alight_time", pattern.toArrivalTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));

                                if (!dropItineraryGeometry) pathOptionsTable.set("geometry", geometry.toString());
                            }
                        }
//                    }
                    }


                    // middle leg: walk between stops/stations
                    if (transit.middle != null) {
                        pathOptionsTable.append();

                        LOG.info("  middle {}", transit.middle.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.middle.mode.toString());
                        pathOptionsTable.set("segment_duration",transit.middle.duration / 60.0);

                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, which are more accurate than segment.distance
                        int dist = calculateSegmentLength(transit.middle);
                        pathOptionsTable.set("distance", dist / 1000);
                        if (!dropItineraryGeometry)
                            pathOptionsTable.set("geometry", transit.middle.geometry.toString());
                    }
                }

                // last leg: walk to destination
                if (option.egress != null) {
                    for (StreetSegment segment : option.egress) {
                        pathOptionsTable.append();

                        LOG.info("  egress {}", segment.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }
            }
        }

        if (pathOptionsTable.nRow() > 0) {
            return pathOptionsTable.getDataFrame();
        } else {
            return null;
        }

    }

    private int buildTransitGeometryAndCalculateDistance(SegmentPattern segmentPattern,
                                                         TripPattern tripPattern,
                                                         StringBuilder geometry) {
        Coordinate previousCoordinate = new Coordinate(0, 0);
        double accDistance = 0;

        if (tripPattern.shape != null) {
            List<LineString> shapeSegments = tripPattern.getHopGeometries(transportNetwork.transitLayer);
            int firstStop = segmentPattern.fromIndex;
            int lastStop = segmentPattern.toIndex;

            for (int i = firstStop; i < lastStop; i++) {
                for (Coordinate coordinate : shapeSegments.get(i).getCoordinates()) {
                    if (geometry.toString().equals("")) {
                        geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                    } else {
                        geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                        accDistance += GeometryUtils.distance(previousCoordinate.y, previousCoordinate.x, coordinate.y, coordinate.x);
                    }
                    previousCoordinate.x = coordinate.x;
                    previousCoordinate.y = coordinate.y;

                }
            }
            geometry.append(")");

        } else {
            for (int stop = segmentPattern.fromIndex; stop <= segmentPattern.toIndex; stop++) {
                int stopIdx = tripPattern.stops[stop];
                Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIdx);

                coordinate.x = coordinate.x / FIXED_FACTOR;
                coordinate.y = coordinate.y / FIXED_FACTOR;

                if (geometry.toString().equals("")) {
                    geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                } else {
                    geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                    accDistance += GeometryUtils.distance(previousCoordinate.y, previousCoordinate.x, coordinate.y, coordinate.x);
                }
                previousCoordinate.x = coordinate.x;
                previousCoordinate.y = coordinate.y;
            }
            geometry.append(")");
        }

        return (int) accDistance;
    }

    private int calculateSegmentLength(StreetSegment segment) {
        int sum = 0;
        for (StreetEdgeInfo streetEdgeInfo : segment.streetEdges) {
            sum += streetEdgeInfo.distance;
        }
        return sum;
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
        // Build vertices return table
        RDataFrame verticesTable = new RDataFrame();
        verticesTable.addIntegerColumn("index", 0);
        verticesTable.addDoubleColumn("lat", 0.0);
        verticesTable.addDoubleColumn("lon", 0.0);
        verticesTable.addBooleanColumn("park_and_ride", false);
        verticesTable.addBooleanColumn("bike_sharing", false);

        VertexStore vertices = transportNetwork.streetLayer.vertexStore;

        VertexStore.Vertex vertexCursor = vertices.getCursor();
        while (vertexCursor.advance()) {
            verticesTable.append();
            verticesTable.set("index", vertexCursor.index);
            verticesTable.set("lat", vertexCursor.getLat());
            verticesTable.set("lon", vertexCursor.getLon());
            verticesTable.set("park_and_ride", vertexCursor.getFlag(VertexStore.VertexFlag.PARK_AND_RIDE));
            verticesTable.set("bike_sharing", vertexCursor.getFlag(VertexStore.VertexFlag.BIKE_SHARING));
        }

        // Build edges return table
        RDataFrame edgesTable = new RDataFrame();
        edgesTable.addIntegerColumn("from_vertex", 0);
        edgesTable.addIntegerColumn("to_vertex", 0);
        edgesTable.addDoubleColumn("length", 0.0);
        edgesTable.addBooleanColumn("walk", false);
        edgesTable.addBooleanColumn("bicycle", false);
        edgesTable.addBooleanColumn("car", false);
        edgesTable.addStringColumn("geometry", "");

        EdgeStore edges = transportNetwork.streetLayer.edgeStore;

        EdgeStore.Edge edgeCursor = edges.getCursor();
        while (edgeCursor.advance()) {
            edgesTable.append();
            edgesTable.set("from_vertex", edgeCursor.getFromVertex());
            edgesTable.set("to_vertex", edgeCursor.getToVertex());
            edgesTable.set("length", edgeCursor.getLengthM());
            edgesTable.set("walk", edgeCursor.allowsStreetMode(StreetMode.WALK));
            edgesTable.set("bicycle", edgeCursor.allowsStreetMode(StreetMode.BICYCLE));
            edgesTable.set("car", edgeCursor.allowsStreetMode(StreetMode.CAR));
            edgesTable.set("geometry", edgeCursor.getGeometry().toString());
        }

        // Return a list of dataframes
        List<Object> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(verticesTable.getDataFrame());
        transportNetworkList.add(edgesTable.getDataFrame());

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

        String[] fromIds = new String[1];
        double[] fromLats = new double[1];
        double[] fromLons = new double[1];
        int[] cutoffTimes = new int[1];

        fromIds[0] = fromId;
        fromLats[0] = fromLat;
        fromLons[0] = fromLon;
        cutoffTimes[0] = cutoffs;

        return isochrones(fromIds, fromLats, fromLons, cutoffTimes, zoom, directModes, transitModes, accessModes, egressModes,
                date, departureTime, maxWalkTime, maxTripDuration);

    }

    public List<LinkedHashMap<String, ArrayList<Object>>> isochrones(String[] fromId, double[] fromLat, double[] fromLon, int[] cutoffs, int zoom,
                                                               String directModes, String transitModes, String accessModes, String egressModes,
                                                               String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException, ExecutionException, InterruptedException {

        IsochroneBuilder isochroneBuilder = new IsochroneBuilder(r5rThreadPool, this.transportNetwork, this.routingProperties);
        isochroneBuilder.setOrigins(fromId, fromLat, fromLon);
        isochroneBuilder.setModes(directModes, accessModes, transitModes, egressModes);
        isochroneBuilder.setDepartureDateTime(date, departureTime);
        isochroneBuilder.setTripDuration(maxWalkTime, maxTripDuration);
        isochroneBuilder.setCutoffs(cutoffs);
        isochroneBuilder.setResolution(zoom);

        return isochroneBuilder.build();


//        int[] requestIndices = new int[fromId.length];
//        for (int i = 0; i < fromId.length; i++) requestIndices[i] = i;
//
//        return r5rThreadPool.submit(() ->
//                Arrays.stream(requestIndices).parallel()
//                        .mapToObj(index -> {
//                            LinkedHashMap<String, ArrayList<Object>> results = null;
//                            try {
//                                results = isochrones(fromId[index], fromLat[index], fromLon[index], cutoffs, zoom,
//                                        directModes, transitModes, accessModes, egressModes,
//                                        date, departureTime, maxWalkTime, maxTripDuration);
//                            } catch (ParseException e) {
//                                e.printStackTrace();
//                            }
//                            return results;
//                        }).
//                        collect(Collectors.toList())).get();
    }

//    public LinkedHashMap<String, ArrayList<Object>> isochrones(String fromId, double fromLat, double fromLon, int[] cutoffs, int zoom,
//                                                               String directModes, String transitModes, String accessModes, String egressModes,
//                                                               String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException {
//
//        RegionalTask request = buildRequest(fromLat, fromLon, directModes, accessModes, transitModes, egressModes, date, departureTime, maxWalkTime, maxTripDuration);
//
//
//        request.destinationPointSets = new PointSet[1];
//        request.destinationPointSets[0] = getGridPointSet(zoom);
//
//        request.percentiles = new int[1];
//        request.percentiles[0] = 50;
//
//        LOG.info("checking grid point set");
//        LOG.info(gridPointSet.toString());
//
//        LOG.info(request.getWebMercatorExtents().toString());
//
//        LOG.info("compute travel times");
//
//        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);
//
//        OneOriginResult travelTimeResults = computer.computeTravelTimes();
//
//        int[] times = travelTimeResults.travelTimes.getValues()[0];
//        for (int i = 0; i < times.length; i++) {
//            // convert travel times from minutes to seconds
//            // this test is necessary because unreachable grid cells have travel time = Integer.MAX_VALUE, and
//            // multiplying Integer.MAX_VALUE by 60 causes errors in the isochrone algorithm
//            if (times[i] <= maxTripDuration) {
//                times[i] = times[i] * 60;
//            } else {
//                times[i] = Integer.MAX_VALUE;
//            }
//        }
//
//        // Build return table
//        WebMercatorExtents extents = WebMercatorExtents.forPointsets(request.destinationPointSets);
//        WebMercatorGridPointSet isoGrid = new WebMercatorGridPointSet(extents);
//
//        RDataFrame isochronesTable = new RDataFrame();
//        isochronesTable.addStringColumn("from_id", fromId);
//        isochronesTable.addIntegerColumn("cutoff", 0);
//        isochronesTable.addStringColumn("geometry", "");
//
//
//        for (int cutoff:cutoffs) {
//            IsochroneFeature isochroneFeature = new IsochroneFeature(cutoff*60, isoGrid, times);
//
//            isochronesTable.append();
//            isochronesTable.set("cutoff", cutoff);
//            isochronesTable.set("geometry", isochroneFeature.geometry.toString());
//        }
//
//        if (isochronesTable.nRow() > 0) {
//            return isochronesTable.getDataFrame();
//        } else {
//            return null;
//        }
//
//    }

    private RegionalTask buildRequest(double fromLat, double fromLon, String directModes, String accessModes, String transitModes, String egressModes, String date, String departureTime, int maxWalkTime, int maxTripDuration) throws ParseException {
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
        request.recordTimes = true;
        request.recordAccessibility = false;
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
        return request;
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
