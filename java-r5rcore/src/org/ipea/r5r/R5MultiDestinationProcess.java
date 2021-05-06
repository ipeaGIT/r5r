package org.ipea.r5r;

import com.conveyal.r5.transit.TransportNetwork;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.concurrent.ForkJoinPool;

public abstract class R5MultiDestinationProcess extends R5Process {

    protected String[] toIds;
    protected double[] toLats;
    protected double[] toLons;

    protected int nDestinations;

    public R5MultiDestinationProcess(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons) {
        this.toIds = toIds;
        this.toLats = toLats;
        this.toLons = toLons;

        this.nDestinations = toIds.length;
    }


}
