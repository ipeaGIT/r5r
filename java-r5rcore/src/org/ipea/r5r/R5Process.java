package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.TransitModes;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.Utils.Utils;

import java.io.FileNotFoundException;
import java.text.ParseException;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static java.lang.Math.max;

public abstract class R5Process {

    protected final ForkJoinPool r5rThreadPool;
    protected final TransportNetwork transportNetwork;
    protected final RoutingProperties routingProperties;

    protected String[] fromIds;
    protected double[] fromLats;
    protected double[] fromLons;

    protected int nOrigins;

    protected EnumSet<LegMode> directModes;
    protected EnumSet<TransitModes> transitModes;
    protected EnumSet<LegMode> accessModes;
    protected EnumSet<LegMode> egressModes;

    protected String departureDate;
    protected String departureTime;

    protected int maxWalkTime;
    protected int maxBikeTime;
    protected int maxTripDuration;

    public R5Process(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        this.r5rThreadPool = threadPool;
        this.transportNetwork = transportNetwork;
        this.routingProperties = routingProperties;
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

    public void setTripDuration(int maxWalkTime, int maxBikeTime, int maxTripDuration) {
        this.maxWalkTime = maxWalkTime;
        this.maxBikeTime = maxBikeTime;
        this.maxTripDuration = maxTripDuration;
    }

    public RDataFrame run() throws ExecutionException, InterruptedException {
        int[] requestIndices = IntStream.range(0, nOrigins).toArray();
        AtomicInteger totalProcessed = new AtomicInteger(1);

        List<RDataFrame> processResults = r5rThreadPool.submit(() ->
                Arrays.stream(requestIndices).parallel().
                        mapToObj(index -> tryRunProcess(totalProcessed, index)).
                        filter(Objects::nonNull).
                        collect(Collectors.toList())).get();
        System.out.print(".. DONE!\n");
        if (!Utils.verbose & Utils.progress) {
            System.out.print(".. DONE!\n");
        }

        return mergeResults(processResults);
    }

    private RDataFrame tryRunProcess(AtomicInteger totalProcessed, int index) {
        RDataFrame results = null;
        try {
            long start = System.currentTimeMillis();
            results = runProcess(index);
            long duration = max(System.currentTimeMillis() - start, 0L);

            if (results != null & Utils.benchmark) {
                results.addLongColumn("execution_time", duration);
            }

            if (Utils.saveOutputToCsv & results != null) {
                String filename = Utils.outputCsvFolder + "/from_" + fromIds[index] + ".csv";
                results.saveToCsv(filename);
                results.clear();
            }

            if (!Utils.verbose & Utils.progress) {
                System.out.print("\r" + totalProcessed.getAndIncrement() + " out of " + nOrigins + " origins processed. Last origin id: " + fromIds[index]);
            }
        } catch (ParseException | FileNotFoundException e) {
            e.printStackTrace();
        }

        return Utils.saveOutputToCsv ? null : results;
    }

    protected abstract RDataFrame runProcess(int index) throws ParseException;

    private RDataFrame mergeResults(List<RDataFrame> processResults) {
        if (!Utils.verbose & Utils.progress) {
            System.out.print("Consolidating results...");
        }

        int nRows;
        nRows = processResults.stream()
                .mapToInt(RDataFrame::nRow)
                .sum();

        RDataFrame mergedDataFrame = buildDataFrameStructure("", nRows);
        if (Utils.benchmark) {
            mergedDataFrame.addLongColumn("execution_time", 0L);
        }

        mergedDataFrame.getDataFrame().keySet().stream().parallel().forEach(
                key -> {
                    ArrayList<Object> destinationArray = mergedDataFrame.getDataFrame().get(key);
                    processResults.forEach(
                            dataFrame -> {
                                ArrayList<Object> originArray = dataFrame.getDataFrame().get(key);
                                destinationArray.addAll(originArray);

                                originArray.clear();
                            });
                }
        );
        mergedDataFrame.updateRowCount();

        if (!Utils.verbose & Utils.progress) {
            System.out.print(" DONE!\n");
        }

        return mergedDataFrame;
    }

    protected abstract RDataFrame buildDataFrameStructure(String fromId, int nRows);

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
        request.maxCarTime = maxTripDuration;
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

        int secondsFromMidnight = Utils.getSecondsFromMidnight(departureTime);

        request.fromTime = secondsFromMidnight;
        request.toTime = secondsFromMidnight + (routingProperties.timeWindowSize * 60);

        request.monteCarloDraws = routingProperties.numberOfMonteCarloDraws;

        request.percentiles = routingProperties.percentiles;

        if (routingProperties.maxFare >= 0) {
            request.maxFare = routingProperties.maxFare;
            request.inRoutingFareCalculator = routingProperties.fareCalculator;
        } else {
            request.maxFare = -1;
            request.inRoutingFareCalculator = null;
        }

        return request;
    }
}
