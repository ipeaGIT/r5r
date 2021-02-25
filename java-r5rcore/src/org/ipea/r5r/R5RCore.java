package org.ipea.r5r;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import com.conveyal.analysis.BackendVersion;
import com.conveyal.gtfs.model.Service;
import com.conveyal.kryo.TIntArrayListSerializer;
import com.conveyal.kryo.TIntIntHashMapSerializer;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.streets.VertexStore;
import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.io.Input;
import com.esotericsoftware.kryo.serializers.ExternalizableSerializer;
import com.esotericsoftware.kryo.serializers.JavaSerializer;
import gnu.trove.impl.hash.TPrimitiveHash;
import gnu.trove.list.array.TIntArrayList;
import gnu.trove.map.hash.TIntIntHashMap;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.LineString;
import org.objenesis.strategy.SerializingInstantiatorStrategy;
import org.slf4j.LoggerFactory;

import java.io.*;
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
    private int maxRides = 8; // max 8 number of rides in public transport trips

    public int getTimeWindowSize() {
        return timeWindowSize;
    }

    public void setTimeWindowSize(int timeWindowSize) {
        this.timeWindowSize = timeWindowSize;
    }

    public int getNumberOfMonteCarloDraws() {
        return numberOfMonteCarloDraws;
    }

    public void setNumberOfMonteCarloDraws(int numberOfMonteCarloDraws) {
        this.numberOfMonteCarloDraws = numberOfMonteCarloDraws;
    }

    private int timeWindowSize = 60; // minutes
    private int numberOfMonteCarloDraws = 220; //
    private int[] percentiles = {50};

    public void setPercentiles(int[] percentiles) {
        this.percentiles = percentiles;
    }

    public void setPercentiles(int percentile) {
        this.percentiles = new int[1];
        this.percentiles[0] = percentile;
    }

    public int getMaxRides() {
        return maxRides;
    }

    public void setMaxRides(int maxRides) {
        this.maxRides = maxRides;
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
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory(); //LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);

        Logger logger = loggerContext.getLogger("com.conveyal.r5");
        logger.setLevel(Level.ERROR);

        logger = loggerContext.getLogger("com.conveyal.osmlib");
        logger.setLevel(Level.ERROR);

        logger = loggerContext.getLogger("com.conveyal.gtfs");
        logger.setLevel(Level.ERROR);

        logger = loggerContext.getLogger("com.conveyal.r5.profile.ExecutionTimer");
        logger.setLevel(Level.ERROR);
    }

    public void verboseMode() {
        LoggerContext loggerContext = (LoggerContext) LoggerFactory.getILoggerFactory();// LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);

        Logger logger = loggerContext.getLogger("com.conveyal.r5");
        logger.setLevel(Level.ALL);

        logger = loggerContext.getLogger("com.conveyal.osmlib");
        logger.setLevel(Level.ALL);

        logger = loggerContext.getLogger("com.conveyal.gtfs");
        logger.setLevel(Level.ALL);

        logger = loggerContext.getLogger("com.conveyal.r5.profile.ExecutionTimer");
        logger.setLevel(Level.ALL);
    }

    public void setLogMode(String mode) {
        LoggerContext loggerContext = (LoggerContext)LoggerFactory.getILoggerFactory();//  LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME);

        Logger logger = loggerContext.getLogger("com.conveyal.r5");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.osmlib");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.gtfs");
        logger.setLevel(Level.valueOf(mode));

        logger = loggerContext.getLogger("com.conveyal.r5.profile.ExecutionTimer");
        logger.setLevel(Level.valueOf(mode));
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

        this.walkSpeed = 1.0f;
        this.bikeSpeed = 3.3f;

        File file = new File(dataFolder, "network.dat");
        if (!file.isFile()) {
            // network.dat file does not exist. create!
            transportNetwork = createR5Network(dataFolder);
        } else {
            // network.dat file exists
            // check version
            if (!checkR5NetworkVersion(dataFolder)) {
                // incompatible versions. try to create a new one
                // network could not be loaded, probably due to incompatible versions. create a new one
                transportNetwork = createR5Network(dataFolder);
            }
        }
        // compatible versions, load network
        transportNetwork = loadR5Network(dataFolder);
        transportNetwork.transitLayer.buildDistanceTables(null);
    }

    private TransportNetwork loadR5Network(String dataFolder) {
        try {
            TransportNetwork tn = KryoNetworkSerializer.read(new File(dataFolder, "network.dat"));
            return tn ;
        } catch (Exception e) {
            return null;
        }
    }

    private TransportNetwork createR5Network(String dataFolder) {
        File dir = new File(dataFolder);
        File[] mapdbFiles = dir.listFiles((d, name) -> name.contains(".mapdb"));

        for (File file:mapdbFiles) file.delete();

        TransportNetwork tn = TransportNetwork.fromDirectory(new File(dataFolder));
//        transportNetwork.transitLayer.buildDistanceTables(null);
        try {
            KryoNetworkSerializer.write(tn, new File(dataFolder, "network.dat"));
            return tn;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    private boolean checkR5NetworkVersion(String dataFolder) throws FileNotFoundException {
        LOG.info("Reading transport network...");

        File file = new File(dataFolder, "network.dat");
        Input input = new Input(new FileInputStream(file));
        Kryo kryo = makeKryo();
        byte[] header = new byte[KryoNetworkSerializer.HEADER.length];
        input.read(header, 0, header.length);
        if (!Arrays.equals(KryoNetworkSerializer.HEADER, header)) {
            throw new RuntimeException("Unrecognized file header. Is this an R5 Kryo network?");
        }
        String version = kryo.readObject(input, String.class);
        String commit = kryo.readObject(input, String.class);
        LOG.info("Loading {} file saved by R5 version {} commit {}", new String(header), version, commit);

        input.close();

        if (!BackendVersion.instance.version.equals(version)) {
            LOG.error(String.format("File version %s is not compatible with this R5 version %s",
                    version, BackendVersion.instance.version));
            return false;
        } else { return true; }
    }

    /**
     * Factory method ensuring that we configure Kryo exactly the same way when saving and loading networks, without
     * duplicating code. We could explicitly register all classes in this method, which would avoid writing out the
     * class names the first time they are encountered and guarantee that the desired serialization approach was used.
     * Because these networks are so big though, pre-registration should provide very little savings.
     * Registration is more important for small network messages.
     */
    private static Kryo makeKryo () {
        Kryo kryo;
        kryo = new Kryo();
        // Auto-associate classes with default serializers the first time each class is encountered.
        kryo.setRegistrationRequired(false);
        // Handle references and loops in the object graph, do not repeatedly serialize the same instance.
        kryo.setReferences(true);
        // Hash maps generally cannot be properly serialized just by serializing their fields.
        // Kryo's default serializers and instantiation strategies don't seem to deal well with Trove primitive maps.
        // Certain Trove class hierarchies are Externalizable though, and define their own optimized serialization
        // methods. addDefaultSerializer will create a serializer instance for any subclass of the specified class.
        // The TPrimitiveHash hierarchy includes all the trove primitive-primitive and primitive-Object implementations.
        kryo.addDefaultSerializer(TPrimitiveHash.class, ExternalizableSerializer.class);
        // We've got a custom serializer for primitive int array lists, because there are a lot of them and the custom
        // implementation is much faster than deferring to their Externalizable implementation.
        kryo.register(TIntArrayList.class, new TIntArrayListSerializer());
        // Likewise for TIntIntHashMaps - there are lots of them in the distance tables.
        kryo.register(TIntIntHashMap.class, new TIntIntHashMapSerializer());
        // Kryo's default instantiation and deserialization of BitSets leaves them empty.
        // The Kryo BitSet serializer in magro/kryo-serializers naively writes out a dense stream of booleans.
        // BitSet's built-in Java serializer saves the internal bitfields, which is efficient. We use that one.
        kryo.register(BitSet.class, new JavaSerializer());
        // Instantiation strategy: how should Kryo make new instances of objects when they are deserialized?
        // The default strategy requires every class you serialize, even in your dependencies, to have a zero-arg
        // constructor (which can be private). The setInstantiatorStrategy method completely replaces that default
        // strategy. The nesting below specifies the Java approach as a fallback strategy to the default strategy.
        kryo.setInstantiatorStrategy(new Kryo.DefaultInstantiatorStrategy(new SerializingInstantiatorStrategy()));
        return kryo;
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
        request.walkSpeed = (float) this.walkSpeed;
        request.bikeSpeed = (float) this.bikeSpeed;
        request.maxTripDurationMinutes = maxTripDuration;
        request.computePaths = true;
        request.computeTravelTimeBreakdown = true;
        request.maxRides = this.maxRides;

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
        request.toTime = secondsFromMidnight + 60; // 1 minute, ignoring time window parameter (this.timeWindowSize * 60);

        request.monteCarloDraws = 1;

        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response = null;
        try {
            response = query.getPlan(request);
        } catch (IllegalStateException e) {
            LOG.error(String.format("Error while finding path between %s and %s", fromId, toId));
            return null;
        }

        if (!response.getOptions().isEmpty()) {
            return buildPathOptionsTable(fromId, fromLat, fromLon, toId, toLat, toLon,
                    maxWalkTime, maxTripDuration, dropItineraryGeometry, response.getOptions());
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
                                                                           int maxWalkTime, int maxTripDuration,
                                                                           boolean dropItineraryGeometry,
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
        pathOptionsTable.addIntegerColumn("total_duration", 0);
        pathOptionsTable.addDoubleColumn("segment_duration", 0.0);
        pathOptionsTable.addDoubleColumn("wait", 0.0);
        pathOptionsTable.addIntegerColumn("distance", 0);
        pathOptionsTable.addStringColumn("route", "");
        if (!dropItineraryGeometry) pathOptionsTable.addStringColumn("geometry", "");

        int optionIndex = 0;
        for (ProfileOption option : pathOptions) {
            if (option.stats.avg > (maxTripDuration * 60)) continue;

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
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        pathOptionsTable.set("total_duration", option.stats.avg / 60.0);

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

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        pathOptionsTable.set("total_duration", option.stats.avg / 60.0);

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

                for (TransitSegment transit : option.transit) {

//                    for (SegmentPattern pattern : transit.segmentPatterns) {
                        // Use only first of many possible repeated patterns
                        SegmentPattern pattern = transit.segmentPatterns.get(0);
                        pathOptionsTable.append();

                        segmentIndex++;
                        TripPattern tripPattern = transportNetwork.transitLayer.tripPatterns.get(pattern.patternIdx);

                        StringBuilder geometry = new StringBuilder();
                        int accDistance = buildTransitGeometryAndCalculateDistance(pattern, tripPattern, geometry);

                        pathOptionsTable.set("option", optionIndex);
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.mode.toString());
                        pathOptionsTable.set("segment_duration", transit.rideStats.avg / 60.0);
                        pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        pathOptionsTable.set("distance", accDistance);
                        pathOptionsTable.set("route", tripPattern.routeId);
                        pathOptionsTable.set("wait", transit.waitStats.avg / 60.0);
                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", geometry.toString());
//                    }

                    // middle leg: walk between stops/stations
                    if (transit.middle != null) {
                        pathOptionsTable.append();

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.middle.mode.toString());
                        pathOptionsTable.set("segment_duration",transit.middle.duration / 60.0);
                        pathOptionsTable.set("total_duration", option.stats.avg / 60.0);

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

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        pathOptionsTable.set("total_duration", option.stats.avg / 60.0);

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


        FreeFormPointSet destinationPoints = new FreeFormPointSet(toIds.length);
        for (int i = 0; i < toIds.length; i++) {
            destinationPoints.setId(i, toIds[i]);
            destinationPoints.setLat(i, toLats[i]);
            destinationPoints.setLon(i, toLons[i]);
            destinationPoints.setCount(i, 1);
        }

        String[] modes = accessModes.split(";");
        if (!accessModes.equals("") & modes.length > 0) {
            for (String mode : modes) {
                transportNetwork.linkageCache.getLinkage(destinationPoints, transportNetwork.streetLayer, StreetMode.valueOf(mode));
            }
        }

        List<LinkedHashMap<String, ArrayList<Object>>> returnList;

        FreeFormPointSet finalDestinationPoints = destinationPoints;
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
        request.maxRides = this.maxRides;

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
        request.toTime = secondsFromMidnight + (this.timeWindowSize * 60);

        request.monteCarloDraws = this.numberOfMonteCarloDraws;

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
        ArrayList<Integer> indexCol = new ArrayList<>();
        ArrayList<Double> latCol = new ArrayList<>();
        ArrayList<Double> lonCol = new ArrayList<>();
        ArrayList<Boolean> parkAndRideCol = new ArrayList<>();
        ArrayList<Boolean> bikeSharingCol = new ArrayList<>();

        LinkedHashMap<String, Object> verticesTable = new LinkedHashMap<>();
        verticesTable.put("index", indexCol);
        verticesTable.put("lat", latCol);
        verticesTable.put("lon", lonCol);
        verticesTable.put("park_and_ride", parkAndRideCol);
        verticesTable.put("bike_sharing", bikeSharingCol);

        VertexStore vertices = transportNetwork.streetLayer.vertexStore;

        VertexStore.Vertex vertexCursor = vertices.getCursor();
        while (vertexCursor.advance()) {
            indexCol.add(vertexCursor.index);
            latCol.add(vertexCursor.getLat());
            lonCol.add(vertexCursor.getLon());
            parkAndRideCol.add(vertexCursor.getFlag(VertexStore.VertexFlag.PARK_AND_RIDE));
            bikeSharingCol.add(vertexCursor.getFlag(VertexStore.VertexFlag.BIKE_SHARING));
        }

        // Build edges return table
        ArrayList<Integer> fromVertexCol = new ArrayList<>();
        ArrayList<Integer> toVertexCol = new ArrayList<>();
        ArrayList<Double> lengthCol = new ArrayList<>();
        ArrayList<Boolean> walkCol = new ArrayList<>();
        ArrayList<Boolean> bicycleCol = new ArrayList<>();
        ArrayList<Boolean> carCol = new ArrayList<>();
        ArrayList<String> geometryCol = new ArrayList<>();

        LinkedHashMap<String, Object> edgesTable = new LinkedHashMap<>();
        edgesTable.put("from_vertex", fromVertexCol);
        edgesTable.put("to_vertex", toVertexCol);
        edgesTable.put("length", lengthCol);
        edgesTable.put("walk", walkCol);
        edgesTable.put("bicycle", bicycleCol);
        edgesTable.put("car", carCol);
        edgesTable.put("geometry", geometryCol);

        EdgeStore edges = transportNetwork.streetLayer.edgeStore;

        EdgeStore.Edge edgeCursor = edges.getCursor();
        while (edgeCursor.advance()) {
            fromVertexCol.add(edgeCursor.getFromVertex());
            toVertexCol.add(edgeCursor.getToVertex());
            lengthCol.add(edgeCursor.getLengthM());
            walkCol.add(edgeCursor.allowsStreetMode(StreetMode.WALK));
            bicycleCol.add(edgeCursor.allowsStreetMode(StreetMode.BICYCLE));
            carCol.add(edgeCursor.allowsStreetMode(StreetMode.CAR));
            geometryCol.add(edgeCursor.getGeometry().toString());
        }

        // Return a list of dataframes
        List<Object> transportNetworkList = new ArrayList<>();
        transportNetworkList.add(verticesTable);
        transportNetworkList.add(edgesTable);

        return transportNetworkList;
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



}
