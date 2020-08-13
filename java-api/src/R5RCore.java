import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.cluster.AnalysisTask;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import com.conveyal.r5.util.CSVInputStreamProvider;
import org.locationtech.jts.geom.Coordinate;

import java.io.File;
import java.io.IOException;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class R5RCore {

    private TransportNetwork transportNetwork;
    private FreeFormPointSet destinationPointSet;
    private LinkedHashMap<String, Object> pathOptionsTable;

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

    public void loadDestinationPointsFromCsv(String csvFile) {
        CSVInputStreamProvider csvInputStream;
        try {
            csvInputStream = new CSVInputStreamProvider(csvFile);
            destinationPointSet = FreeFormPointSet.fromCsv(csvInputStream, "lat", "lon", "id", "count");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void planMultipleTrips(double[] fromLat, double[] fromLon, double[] toLat, double[] toLon,
                                  String directModes, String transitModes, String date, String departureTime) {

    }

    public void planSingleTrip(double fromLat, double fromLon, double toLat, double toLon,
                               String directModes, String transitModes, String date, String departureTime) throws ParseException {
        AnalysisTask request = new RegionalTask();
        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLat;
        request.fromLon = fromLon;
        request.toLat = toLat;
        request.toLon = toLon;
        request.streetTime = 60;
        request.computePaths = true;
        request.computeTravelTimeBreakdown = true;
        request.directModes = EnumSet.of(LegMode.WALK, LegMode.BICYCLE, LegMode.CAR);

        request.transitModes = EnumSet.of(TransitModes.BUS);
        request.accessModes = EnumSet.of(LegMode.WALK);
        request.egressModes = EnumSet.of(LegMode.WALK);
        request.date = LocalDate.parse(date);

        int secondsFromMidnight = getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + 60;

        request.monteCarloDraws = 1;

        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response = query.getPlan(request);

        if (!response.getOptions().isEmpty()) {
            buildPathOptionsTable(response.getOptions());
        }
    }

    private int getSecondsFromMidnight(String departureTime) throws ParseException {
        DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");
        Date reference = dateFormat.parse("00:00:00");
        Date date = dateFormat.parse(departureTime);
        return (int) ((date.getTime() - reference.getTime()) / 1000L);
    }

    private void buildPathOptionsTable(List<ProfileOption> pathOptions) {
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

        pathOptionsTable = new LinkedHashMap<>();
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
    }

    public LinkedHashMap<String, Object> getPathOptionsTable() {
        return pathOptionsTable;
    }
}
