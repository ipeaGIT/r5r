package org.ipea.r5r;

import com.conveyal.r5.transit.TransportNetwork;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

public abstract class R5MultiDestinationProcess extends R5Process {

    protected String[] toIds;
    protected double[] toLats;
    protected double[] toLons;
    protected int[] opportunities;

    protected int nDestinations;

    public R5MultiDestinationProcess(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    @Override
    public List<LinkedHashMap<String, ArrayList<Object>>> run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        return super.run();
    }

    protected abstract void buildDestinationPointSet();

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
    }


}
