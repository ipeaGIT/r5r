package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.*;
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
import java.util.stream.Collectors;

public class IsochroneBuilder extends R5Process {

    private int[] cutoffs;

    private Grid gridPointSet = null;

    public IsochroneBuilder(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    public void setResolution(int resolution) {
        this.gridPointSet = new Grid(resolution, this.transportNetwork.getEnvelope());
    }

    public void setCutoffs(int[] cutoffs) {
        this.cutoffs = cutoffs;
    }

    @Override
    protected LinkedHashMap<String, ArrayList<Object>> runProcess(int index) throws ParseException {
        // Build request
        RegionalTask request = buildRequest(index);

        // Calculate travel times and convert to seconds
        int[] times = computeTravelTimes(request);

        // Build isochrone features
        List<IsochroneFeature> isochroneFeatures = buildIsochroneFeatures(request, times);

        // Build return table
        RDataFrame isochronesTable = buildIsochronesTable(fromIds[index], isochroneFeatures);

        // Return isochrones
        if (isochronesTable.nRow() > 0) {
            return isochronesTable.getDataFrame();
        } else {
            return null;
        }
    }

    private int[] computeTravelTimes(RegionalTask request) {
        TravelTimeComputer computer = new TravelTimeComputer(request, this.transportNetwork);
        OneOriginResult travelTimeResults = computer.computeTravelTimes();

        int[] times = travelTimeResults.travelTimes.getValues()[0];
        for (int i = 0; i < times.length; i++) {
            // convert travel times from minutes to seconds
            // this test is necessary because unreachable grid cells have travel time = Integer.MAX_VALUE, and
            // multiplying Integer.MAX_VALUE by 60 causes errors in the isochrone algorithm
            if (times[i] <= maxTripDuration) {
                times[i] = times[i] * 60;
            } else {
                times[i] = Integer.MAX_VALUE;
            }
        }
        return times;
    }

    private List<IsochroneFeature> buildIsochroneFeatures(RegionalTask request, int[] times) {
        WebMercatorExtents extents = WebMercatorExtents.forPointsets(request.destinationPointSets);
        WebMercatorGridPointSet isoGrid = new WebMercatorGridPointSet(extents);

        List<IsochroneFeature> isochroneFeatures = new LinkedList<>();
        for (int cutoff:cutoffs) {
            isochroneFeatures.add(new IsochroneFeature(cutoff*60, isoGrid, times));
        }
        return isochroneFeatures;
    }

    private RDataFrame buildIsochronesTable(String fromId, List<IsochroneFeature> isochroneFeatures) {
        RDataFrame isochronesTable = new RDataFrame();
        isochronesTable.addStringColumn("from_id", fromId);
        isochronesTable.addIntegerColumn("cutoff", 0);
        isochronesTable.addStringColumn("geometry", "");

        for (IsochroneFeature isochroneFeature : isochroneFeatures) {
            isochronesTable.append();
            isochronesTable.set("cutoff", isochroneFeature.cutoffSec / 60);
            isochronesTable.set("geometry", isochroneFeature.geometry.toString());
        }
        return isochronesTable;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.destinationPointSets = new PointSet[1];
        request.destinationPointSets[0] = this.gridPointSet;

        request.percentiles = new int[1];
        request.percentiles[0] = 50;

        return request;
    }

    }
