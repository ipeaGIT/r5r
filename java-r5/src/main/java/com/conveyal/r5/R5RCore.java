package com.conveyal.r5;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.AnalysisTask;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class R5RCore {

    private TransportNetwork transportNetwork;
//    private LinkedHashMap<String, Object> pathOptionsTable;

    public R5RCore(String dataFolder) {
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

    public void planMultipleTrips(double[] fromLat, double[] fromLon, double[] toLat, double[] toLon,
                                  String directModes, String transitModes, String date, String departureTime) {

    }

    public LinkedHashMap<String, Object> planSingleTrip(double fromLat, double fromLon, double toLat, double toLon,
                               String directModes, String transitModes, String date, String departureTime,
                               int maxStreetTime) throws ParseException {
        AnalysisTask request = new RegionalTask();
        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.toLat = toLat;
        request.toLon = toLon;
        request.streetTime = maxStreetTime;
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
        request.accessModes = EnumSet.noneOf(LegMode.class);
        request.egressModes = EnumSet.noneOf(LegMode.class);
        modes = transitModes.split(";");
        if (!transitModes.equals("") & modes.length > 0) {
            request.accessModes.add(LegMode.WALK);
            request.egressModes.add(LegMode.WALK);
            for (String mode : modes) {
                request.transitModes.add(TransitModes.valueOf(mode));
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
            return buildPathOptionsTable(response.getOptions());
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

    private LinkedHashMap<String, Object> buildPathOptionsTable(List<ProfileOption> pathOptions) {
        // When data.frame.row.major = FALSE, convertToJava() creates a LinkedHashMap<String, Object> object. In this case, the key/value pairs represent column names and data. The column data are converted to primitive Java arrays using the same rules as R vectors.

        // Columns:
        // option: int
        // segment: int
        // mode: string
        // geometry: string (LINESTRING)
        ArrayList<Integer> optionCol = new ArrayList<>();
        ArrayList<Integer> segmentCol = new ArrayList<>();
        ArrayList<String> modeCol = new ArrayList<>();
        ArrayList<Integer> durationCol = new ArrayList<>();
        ArrayList<String> routeCol = new ArrayList<>();
        ArrayList<String> geometryCol = new ArrayList<>();

        LinkedHashMap<String, Object> pathOptionsTable = new LinkedHashMap<>();
        pathOptionsTable.put("option", optionCol);
        pathOptionsTable.put("segment", segmentCol);
        pathOptionsTable.put("mode", modeCol);
        pathOptionsTable.put("duration", durationCol);
        pathOptionsTable.put("route", routeCol);
        pathOptionsTable.put("geometry", geometryCol);

        int optionIndex = 0;
        for (ProfileOption option : pathOptions) {
            if (option.transit == null) { // no transit, maybe has direct access legs

                if (option.access != null) {
                    for (StreetSegment segment : option.access) {
                        optionIndex++;
                        optionCol.add(optionIndex);
                        segmentCol.add(1);
                        modeCol.add(segment.mode.toString());
                        durationCol.add(segment.duration);
                        routeCol.add("");
                        geometryCol.add(segment.geometry.toString());
                    }
                }

            } else { // option has transit
                optionIndex++;
                int segmentIndex = 0;

                // first leg: access to station
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {
                        optionCol.add(optionIndex);
                        segmentIndex++;
                        segmentCol.add(segmentIndex);
                        modeCol.add(segment.mode.toString());
                        durationCol.add(segment.duration);
                        routeCol.add("");
                        geometryCol.add(segment.geometry.toString());
                    }
                }

                for (TransitSegment transit : option.transit) {

                    for (SegmentPattern pattern : transit.segmentPatterns) {
                        segmentIndex++;
                        TripPattern tripPattern = transportNetwork.transitLayer.tripPatterns.get(pattern.patternIdx);

                        String geometry = "NA";

                        for (int stop = pattern.fromIndex; stop <= pattern.toIndex; stop++) {
                            int stopIdx = tripPattern.stops[stop];
                            org.locationtech.jts.geom.Coordinate coord = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIdx);
                            coord.x = coord.x / FIXED_FACTOR;
                            coord.y = coord.y / FIXED_FACTOR;

                            if (geometry.equals("NA")) {
                                geometry = "LINESTRING (" + coord.x + " " + coord.y;
                            } else {
                                geometry = geometry + ", " + coord.x + " " + coord.y;
                            }
                        }
                        geometry = geometry + ")";

                        optionCol.add(optionIndex);
                        segmentCol.add(segmentIndex);
                        modeCol.add(transit.mode.toString());
                        durationCol.add(transit.rideStats.avg);
                        routeCol.add(tripPattern.routeId);
                        geometryCol.add(geometry);
                    }

                    if (transit.middle != null) {
                        optionCol.add(optionIndex);
                        segmentIndex++;
                        segmentCol.add(segmentIndex);
                        modeCol.add(transit.middle.mode.toString());
                        durationCol.add(transit.middle.duration);
                        routeCol.add("");
                        geometryCol.add(transit.middle.geometry.toString());
                    }
                }

                // first leg: access to station
                if (option.egress != null) {
                    for (StreetSegment segment : option.egress) {
                        optionCol.add(optionIndex);
                        segmentIndex++;
                        segmentCol.add(segmentIndex);
                        modeCol.add(segment.mode.toString());
                        durationCol.add(segment.duration);
                        routeCol.add("");
                        geometryCol.add(segment.geometry.toString());
                    }
                }

            }

        }

        return pathOptionsTable;
    }

    public List<Object> travelTimeMatrixParallel(String[] fromIds, double[] fromLats, double[] fromLons,
                                                 String[] toIds, double[] toLats, double[] toLons,
                                                 String directModes, String transitModes, String date, String departureTime,
                                                 int maxWalkTime, int maxTripDuration) {
        int[] originIndices = new int[fromIds.length];
        for (int i = 0; i < fromIds.length; i++) originIndices[i] = i;

        return Arrays.stream(originIndices).parallel()
                .mapToObj(index -> {
                    LinkedHashMap<String, Object> results =
                            null;
                    try {
                        results = travelTimesFromOrigin(fromIds[index], fromLats[index], fromLons[index],
                                toIds, toLats, toLons, directModes, transitModes, date, departureTime,
                                maxWalkTime, maxTripDuration);
                    } catch (ParseException e) {
                        e.printStackTrace();
                    }
                    return results;
                }).collect(Collectors.toList());


//
//            project.getHexGrid().getCells().entrySet()
//                    .parallelStream()
//                    .forEach(cell -> {
//                        String hexagonId = cell.getValue().getH3code();
//
//                        OneOriginResult travelTimeResults = travelTimesFromOrigin(hexagonId);
//
//                        saveTravelTimeResults(travelTimeResults, hexagonId);
//                    });
//
//            .map    (s -> { s.setState("ok"); return s; }) // need to return a value here
//                    .collect(Collectors.toList());
    }

    public LinkedHashMap<String, Object> travelTimesFromOrigin(String fromId, double fromLat, double fromLon,
                                                  String[] toIds, double[] toLats, double[] toLons,
                                                  String directModes, String transitModes, String date, String departureTime,
                                                  int maxWalkTime, int maxTripDuration) throws ParseException {

        RegionalTask request = new RegionalTask();

        request.scenario = new Scenario();
        request.scenario.id = "id";
        request.scenarioId = request.scenario.id;

        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.walkSpeed = 1f;
        request.bikeSpeed = 3.3f;
        request.streetTime = maxWalkTime;
        request.maxWalkTime = maxWalkTime;
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
        request.accessModes = EnumSet.noneOf(LegMode.class);
        request.egressModes = EnumSet.noneOf(LegMode.class);
        modes = transitModes.split(";");
        if (!transitModes.equals("") & modes.length > 0) {
            request.accessModes.add(LegMode.WALK);
            request.egressModes.add(LegMode.WALK);
            for (String mode : modes) {
                request.transitModes.add(TransitModes.valueOf(mode));
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
        ArrayList<Double> fromLatCol = new ArrayList<>();
        ArrayList<Double> fromLonCol = new ArrayList<>();

        ArrayList<String> idCol = new ArrayList<>();
        ArrayList<Double> latCol = new ArrayList<>();
        ArrayList<Double> lonCol = new ArrayList<>();

        ArrayList<Integer> travelTimeCol = new ArrayList<>();

        for (int i = 0; i < travelTimeResults.travelTimes.nPoints; i++) {
            if (travelTimeResults.travelTimes.getValues()[0][i] <= maxTripDuration) {
                fromIdCol.add(fromId);
                fromLatCol.add(fromLat);
                fromLonCol.add(fromLon);

                idCol.add(toIds[i]);
                latCol.add(toLats[i]);
                lonCol.add(toLons[i]);

                travelTimeCol.add(travelTimeResults.travelTimes.getValues()[0][i]);
            }
        }

        LinkedHashMap<String, Object> results = new LinkedHashMap<>();
        results.put("fromId", fromIdCol);
        results.put("fromLat", fromLatCol);
        results.put("fromLon", fromLonCol);
        results.put("toId", idCol);
        results.put("toLat", latCol);
        results.put("toLon", lonCol);
        results.put("travel_time", travelTimeCol);

        return results;
    }
}
