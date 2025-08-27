package org.ipea.r5r.Process;

import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.TransitModes;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.transit.TransportNetwork;
import org.apache.arrow.memory.BufferAllocator;
import org.apache.arrow.memory.RootAllocator;
import org.apache.arrow.vector.types.pojo.Schema;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.channels.WritableByteChannel;
import java.text.ParseException;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static java.lang.Math.max;
import static java.nio.channels.Channels.newChannel;

public abstract class ArrowR5Process {

    protected final ForkJoinPool r5rThreadPool;
    protected final TransportNetwork transportNetwork;
    protected final RoutingProperties routingProperties;

    protected String[] fromIds;
    protected double[] fromLats;
    protected double[] fromLons;
    protected int nOrigins;

    protected String[] toIds;
    protected double[] toLats;
    protected double[] toLons;
    protected String[] opportunities;
    protected int[][] opportunityCounts;
    protected int nDestinations;

    protected FreeFormPointSet[] destinationPoints;

    protected EnumSet<LegMode> directModes;
    protected EnumSet<TransitModes> transitModes;
    protected EnumSet<LegMode> accessModes;
    protected EnumSet<LegMode> egressModes;

    protected String departureDate;
    protected String departureTime;
    protected int secondsFromMidnight;

    protected int maxWalkTime;
    protected int maxBikeTime;
    protected int maxCarTime;
    protected int maxTripDuration;

    protected Schema schema;
    protected BufferAllocator parentAllocator;

    protected abstract boolean isOneToOne();

    private static final Logger LOG = LoggerFactory.getLogger(ArrowR5Process.class);

    public ArrowR5Process(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        this.r5rThreadPool = threadPool;
        this.transportNetwork = transportNetwork;
        this.routingProperties = routingProperties;

        destinationPoints = null;
    }

    public byte[] run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        buildSchemaStructure();

        final BlockingQueue<BatchWithSeq> queue = new ArrayBlockingQueue<>(Math.min(nOrigins, 256));

        try (BufferAllocator parentAllocator = new RootAllocator()) {
            this.parentAllocator = parentAllocator;
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            WritableByteChannel channel = newChannel(baos);

            Collector collector = new Collector(parentAllocator, schema, queue, channel, nOrigins);
            Thread collectorThread = new Thread(collector, "arrow-collector");
            collectorThread.start();

            AtomicInteger totalProcessed = new AtomicInteger(1);
            final List<ForkJoinTask<?>> tasks = new ArrayList<>(nOrigins);

            for (int index = 0; index < nOrigins; index++) {
                final int originIndex = index;
                tasks.add(r5rThreadPool.submit(() -> {
                    BatchWithSeq b = tryRunProcess(totalProcessed, originIndex);
                    try {
                        queue.put(b);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        LOG.error("Interrupted while enqueuing batch for origin {}", originIndex, ie);
                        throw new RuntimeException("Interrupted while enqueuing batch for origin " + originIndex, ie);
                    }
                }));
            }

            for (ForkJoinTask<?> t : tasks) {
                t.get();
            }

            collectorThread.join();
            LOG.info(".. DONE! All batches written: {} origins.", nOrigins);
            return baos.toByteArray();
        }
    }

    protected abstract void buildSchemaStructure();

    protected void buildDestinationPointSet() {
        destinationPoints = new FreeFormPointSet[this.opportunities.length];

        for (int i = 0; i < this.opportunities.length; i++) {
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
                for (int opportunity : opportunityCounts[i]) {
                    pointStream.writeDouble(opportunity);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }

            ByteArrayInputStream pointsInput = new ByteArrayInputStream(dataStream.toByteArray());

            try {
                destinationPoints[i] = new FreeFormPointSet(pointsInput);
            } catch (IOException e) {
                e.printStackTrace();
            }

            if (!this.directModes.isEmpty()) {
                for (LegMode mode : this.directModes) {
                    transportNetwork.linkageCache.getLinkage(destinationPoints[i], transportNetwork.streetLayer, StreetMode.valueOf(mode.toString()));
                }
            }
        }
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons) {
        int[][] opportunityCounts = new int[1][toIds.length];
        for (int i = 0; i < toIds.length; i++) opportunityCounts[0][i] = 0;

        String[] opportunities = new String[]{"all"};

        setDestinations(toIds, toLats, toLons, opportunities, opportunityCounts);
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons, String[] opportunities, int[][] opportunityCounts) {
        this.toIds = toIds;
        this.toLats = toLats;
        this.toLons = toLons;
        this.opportunities = opportunities;
        this.opportunityCounts = opportunityCounts;

        this.nDestinations = toIds.length;

        // set maxDestinations in R5 for detailed path information retrieval
        // PathResult.maxDestinations does not exist in R5 anymore
        //PathResult.maxDestinations = this.nDestinations;
    }

    public void setOrigins(String[] fromIds, double[] fromLats, double[] fromLons) {
        this.fromIds = fromIds;
        this.fromLats = fromLats;
        this.fromLons = fromLons;

        this.nOrigins = fromIds.length;
    }

    public void setModes(String directModes, String accessModes, String transitModes, String egressModes) {
        this.directModes = Utils.setLegModes(directModes);
        this.accessModes = Utils.setLegModes(accessModes);
        this.egressModes = Utils.setLegModes(egressModes);
        this.transitModes = Utils.setTransitModes(transitModes);
    }

    public void setDepartureDateTime(String departureDate, String departureTime) {
        this.departureDate = departureDate;
        this.departureTime = departureTime;
    }

    public void setTripDuration(int maxWalkTime, int maxBikeTime, int maxCarTime, int maxTripDuration) {
        this.maxWalkTime = maxWalkTime;
        this.maxBikeTime = maxBikeTime;
        this.maxCarTime = maxCarTime;
        this.maxTripDuration = maxTripDuration;
    }

    private BatchWithSeq tryRunProcess(AtomicInteger totalProcessed, int index) {
        BatchWithSeq results = null;
        try {
            long start = System.currentTimeMillis();
            results = runProcess(index);
            LOG.debug("Processed origin {} in {}ms.", nOrigins, max(System.currentTimeMillis() - start, 0L));


            // TODO Add saving to file
//            if (Utils.saveOutputToCsv & results != null) {
//                String filename = getCsvFilename(index);
//                results.saveToCsv(filename);
//                results.clear();
//            }

            LOG.info("{} out of {} origins processed.", totalProcessed.getAndIncrement(), nOrigins);

        } catch (ParseException e) {
            LOG.error(String.valueOf(e));
        }

//        return Utils.saveOutputToCsv ? null : results;
        return results;
    }

    private String getCsvFilename(int index) {
        String filename;
        if (this.isOneToOne()) {
            // one-to-one functions, such as detailed itineraries
            // save one file per origin-destination pair
            filename = Utils.outputCsvFolder + "/from_" + fromIds[index] + "_to_" + toIds[index] +  ".csv";
        } else {
            // one-to-many functions, such as travel time matrix
            // save one file per origin
            filename = Utils.outputCsvFolder + "/from_" + fromIds[index] +  ".csv";
        }
        return filename;
    }

    protected abstract BatchWithSeq runProcess(int index) throws ParseException;

    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = new RegionalTask();

        request.scenario = new Scenario();
        request.scenario.id = "id";
        request.scenarioId = request.scenario.id;

        request.zoneId = transportNetwork.getTimeZone();
        request.fromLat = fromLats[index];
        request.fromLon = fromLons[index];
        request.walkSpeed = (float) routingProperties.walkSpeed;
        request.bikeSpeed = (float) routingProperties.bikeSpeed;
        request.streetTime = maxTripDuration;
        request.maxWalkTime = maxWalkTime;
        request.maxBikeTime = maxBikeTime;
        request.maxCarTime = maxCarTime;
        request.maxTripDurationMinutes = maxTripDuration;
        request.makeTauiSite = false;
        request.recordTimes = true;
        request.recordAccessibility = false;
        request.maxRides = routingProperties.maxRides;
        request.bikeTrafficStress = routingProperties.maxLevelTrafficStress;

        request.directModes = directModes;
        request.accessModes = accessModes;
        request.egressModes = egressModes;
        request.transitModes = transitModes;

        request.date = LocalDate.parse(departureDate);

        secondsFromMidnight = Utils.getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + (routingProperties.timeWindowSize * 60) ;

        request.monteCarloDraws = routingProperties.numberOfMonteCarloDraws;
        request.suboptimalMinutes = routingProperties.suboptimalMinutes;

        request.percentiles = routingProperties.percentiles;

        request.inRoutingFareCalculator = routingProperties.fareCalculator;
        request.maxFare = Math.round(routingProperties.maxFare * 100.0f);

        return request;
    }
}
