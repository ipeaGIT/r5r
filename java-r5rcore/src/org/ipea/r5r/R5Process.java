package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.scenario.Scenario;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.api.util.TransitModes;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.Utils.Utils;

import java.text.ParseException;
import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

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

    public List<LinkedHashMap<String, ArrayList<Object>>> run() throws ExecutionException, InterruptedException {
        int[] requestIndices = IntStream.range(0, nOrigins).toArray();
        AtomicInteger totalProcessed = new AtomicInteger(1);

        List<LinkedHashMap<String, ArrayList<Object>>> processResults = r5rThreadPool.submit(() ->
                Arrays.stream(requestIndices).parallel()
                        .mapToObj(index -> tryRunProcess(totalProcessed, index)).
                        collect(Collectors.toList())).get();
        System.out.println("\n");
        
        RDataFrame mergedDataFrame = buildDataFrameStructure("");
        for (LinkedHashMap<String, ArrayList<Object>> dataFrame : processResults) {

            for (String key : dataFrame.keySet()) {
                ArrayList<Object> originArray = dataFrame.get(key);
                ArrayList<Object> destinationArray = mergedDataFrame.getDataFrame().get(key);

                destinationArray.addAll(originArray);

                originArray.clear();
            }
        }

        List<LinkedHashMap<String, ArrayList<Object>>> resultList = new LinkedList<LinkedHashMap<String, ArrayList<Object>>>();
        resultList.add(mergedDataFrame.getDataFrame());
        return resultList;
    }

    protected abstract RDataFrame buildDataFrameStructure(String fromId);

    private LinkedHashMap<String, ArrayList<Object>> tryRunProcess(AtomicInteger totalProcessed, int index) {
        LinkedHashMap<String, ArrayList<Object>> results = null;
        try {
            results = runProcess(index);

            if (!Utils.verbose) {
                System.out.print("\r" + totalProcessed.getAndIncrement() + " out of " + nOrigins + " origins processed.                 ");
            }
        } catch (ParseException e) {
            e.printStackTrace();
        }
        return results;
    }

    protected abstract LinkedHashMap<String, ArrayList<Object>> runProcess(int index) throws ParseException;

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

        return request;
    }
}
