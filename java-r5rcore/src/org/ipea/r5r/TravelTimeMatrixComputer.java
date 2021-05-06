package org.ipea.r5r;

import com.conveyal.r5.transit.TransportNetwork;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

public class TravelTimeMatrixComputer extends R5Process {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(TravelTimeMatrixComputer.class);

    protected String[] toIds;
    private double[] toLats;
    private double[] toLons;

    private int nDestinations;

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons) {
        this.toIds = toIds;
        this.toLats = toLats;
        this.toLons = toLons;

        this.nDestinations = toIds.length;
    }

    public TravelTimeMatrixComputer(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    @Override
    public List<LinkedHashMap<String, ArrayList<Object>>> run() throws ExecutionException, InterruptedException {
        return null;
    }

}
