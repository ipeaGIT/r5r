package org.ipea.r5r;

import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.Fares.RuleBasedInRoutingFareCalculator;

import java.io.*;
import java.util.Set;
import java.util.StringJoiner;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

public abstract class R5MultiDestinationProcess extends R5Process {

    protected String[] toIds;
    protected double[] toLats;
    protected double[] toLons;
    protected int[] opportunities;

    protected int nDestinations;
    protected FreeFormPointSet destinationPoints;

    public R5MultiDestinationProcess(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
        destinationPoints = null;
    }

    @Override
    public RDataFrame run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        RDataFrame results = super.run();

        if (this.routingProperties.fareCalculator != null && this.routingProperties.fareCalculator instanceof RuleBasedInRoutingFareCalculator) {
            if (RuleBasedInRoutingFareCalculator.debugActive) {
                Set<String> debugOutput = ((RuleBasedInRoutingFareCalculator) this.routingProperties.fareCalculator).getDebugOutput();

                File debugOutputFile = new File(RuleBasedInRoutingFareCalculator.debugFileName);
                try (PrintWriter pw = new PrintWriter(debugOutputFile)) {

                    pw.println("pattern,fare");
                    debugOutput.forEach(pw::println);

                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                }
            }
        }

        return results;
    }

    protected void buildDestinationPointSet() {
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
            for (int opportunity : opportunities) {
                pointStream.writeDouble(opportunity);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        ByteArrayInputStream pointsInput = new ByteArrayInputStream(dataStream.toByteArray());

        try {
            destinationPoints = new FreeFormPointSet(pointsInput);
        } catch (IOException e) {
            e.printStackTrace();
        }

        if (!this.directModes.isEmpty()) {
            for (LegMode mode : this.directModes) {
                transportNetwork.linkageCache.getLinkage(destinationPoints, transportNetwork.streetLayer, StreetMode.valueOf(mode.toString()));
            }
        }
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons) {
        int[] opportunities = new int[toIds.length];
        for (int i = 0; i < toIds.length; i++) opportunities[i] = 0;

        setDestinations(toIds, toLats, toLons, opportunities);
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons, int[] opportunities) {
        this.toIds = toIds;
        this.toLats = toLats;
        this.toLons = toLons;
        this.opportunities = opportunities;

        this.nDestinations = toIds.length;

        // set maxDestinations in R5 for detailed path information retrieval
        PathResult.maxDestinations = this.nDestinations;
    }
}
