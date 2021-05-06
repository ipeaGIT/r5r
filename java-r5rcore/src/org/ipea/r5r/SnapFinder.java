package org.ipea.r5r;

import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.Split;
import com.conveyal.r5.streets.StreetLayer;
import com.conveyal.r5.transit.TransportNetwork;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class SnapFinder {

    protected final ForkJoinPool r5rThreadPool;
    protected final TransportNetwork transportNetwork;

    protected String[] fromIds;
    protected double[] fromLats;
    protected double[] fromLons;

    protected int nOrigins;

    public SnapFinder(ForkJoinPool threadPool, TransportNetwork transportNetwork) {
        this.r5rThreadPool = threadPool;
        this.transportNetwork = transportNetwork;
    }

    public void setOrigins(String[] fromIds, double[] fromLats, double[] fromLons) {
        this.fromIds = fromIds;
        this.fromLats = fromLats;
        this.fromLons = fromLons;

        this.nOrigins = fromIds.length;
    }

    public LinkedHashMap<String, Object> run() throws ExecutionException, InterruptedException {
        int[] requestIndices = new int[nOrigins];
        for (int i = 0; i < nOrigins; i++) requestIndices[i] = i;

        double[] snapLats = new double[nOrigins];
        double[] snapLons = new double[nOrigins];

        Arrays.stream(requestIndices).parallel().forEach(index -> {
            Split split = Split.find(fromLats[index], fromLons[index], StreetLayer.INITIAL_LINK_RADIUS_METERS,
                    this.transportNetwork.streetLayer, StreetMode.WALK);

            if (split == null) {
                split = Split.find(fromLats[index], fromLons[index], StreetLayer.LINK_RADIUS_METERS,
                        this.transportNetwork.streetLayer, StreetMode.WALK);
                if (split == null) {
                    snapLats[index] = fromLats[index];
                    snapLons[index] = fromLons[index];
                } else {
                    snapLats[index] = split.fixedLat / FIXED_FACTOR;
                    snapLons[index] = split.fixedLon / FIXED_FACTOR;
                }
            } else {
                snapLats[index] = split.fixedLat / FIXED_FACTOR;
                snapLons[index] = split.fixedLon / FIXED_FACTOR;
            }
        });

        // Build edges return table
        LinkedHashMap<String, Object> snapTable = new LinkedHashMap<>();
        snapTable.put("point_id", fromIds);
        snapTable.put("lat", fromLats);
        snapTable.put("lon", fromLons);
        snapTable.put("snap_lat", snapLats);
        snapTable.put("snap_lon", snapLons);

        return snapTable;

    }
}
