package org.ipea.r5r.Process;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.text.ParseException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.TransitModes;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.transit.TransportNetwork;

import static java.lang.Math.max;

/**
 * T is the type returned for each task, A is the aggregate result. They may be the same in some cases.
 */
public abstract class R5Process<T, A> {
    private static final Logger LOG = LoggerFactory.getLogger(R5Process.class);

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

    protected abstract boolean isOneToOne();

    public R5Process(ForkJoinPool threadPool, RoutingProperties routingProperties) {
        this.r5rThreadPool = threadPool;
        this.transportNetwork = routingProperties.transportNetworkWorking;
        this.routingProperties = routingProperties;

        destinationPoints = null;
    }

    public A run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        // TODO shouldn't this start at 0?
        AtomicInteger totalProcessed = new AtomicInteger(1);

        // define callable separately so that Java compiler can check types
        // h/t ChatGPT
        Callable<List<T>> task = () ->
                IntStream.range(0, nOrigins)
                    .parallel()
                    .mapToObj(index -> tryRunProcess(totalProcessed, index))
                    .filter(Objects::nonNull)
                    .collect(Collectors.toList());

        List<T> processResults = r5rThreadPool.submit(task).get();

        LOG.info(".. DONE!");

        A results = mergeResults(processResults);

        return results;
    }


    /**
     * This is protected so that if subclasses don't need a destination point set they can
     * replace it with a no-op.
     */
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

    protected T tryRunProcess(AtomicInteger totalProcessed, int index) {
        T results = null;
        try {
            results = runProcess(index);
        } catch (Exception e) {
            e.printStackTrace();
            // re-throw as unchecked so we get an error on the R side
            throw new RuntimeException();
        }

        int nProcessed = totalProcessed.getAndIncrement();
        if (nProcessed % 1000 == 1 || (nProcessed == nOrigins)) {
            LOG.info("{} out of {} origins processed.", nProcessed, nOrigins);
        }

        return results;
    }

    protected abstract T runProcess(int index) throws ParseException;

    protected abstract A mergeResults(List<T> processResults);

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
