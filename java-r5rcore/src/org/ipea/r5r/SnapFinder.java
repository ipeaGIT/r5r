package org.ipea.r5r;

import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.streets.Split;
import com.conveyal.r5.streets.StreetLayer;
import com.conveyal.r5.transit.TransportNetwork;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ForkJoinPool;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class SnapFinder {

    protected final ForkJoinPool r5rThreadPool;
    protected final TransportNetwork transportNetwork;

    protected String[] fromIds;
    protected double[] fromLats;
    protected double[] fromLons;
    private StreetMode mode;

    public void setMode(String mode) {
        this.mode = StreetMode.valueOf(mode);
    }

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

    public RDataFrame run() {
        // Build edges return table
        RDataFrame snapTable = new RDataFrame(nOrigins);
        snapTable.addStringColumn("point_id", "");
        snapTable.addDoubleColumn("lat", 0.0);
        snapTable.addDoubleColumn("lon", 0.0);
        snapTable.addDoubleColumn("snap_lat", 0.0);
        snapTable.addDoubleColumn("snap_lon", 0.0);
        snapTable.addDoubleColumn("distance", 0.0);
        snapTable.addBooleanColumn("found", false);

        for (int index = 0; index < nOrigins; index++) {
            snapTable.append();

            snapTable.set("point_id", fromIds[index]);
            snapTable.set("lat", fromLats[index]);
            snapTable.set("lon", fromLons[index]);

            Split split = transportNetwork.streetLayer.findSplit(fromLats[index], fromLons[index],
                    StreetLayer.LINK_RADIUS_METERS, this.mode);

            if (split != null) {
                // found split at StreetLayer.INITIAL_LINK_RADIUS_METERS
                double snapLat = split.fixedLat / FIXED_FACTOR;
                double snapLon = split.fixedLon / FIXED_FACTOR;

                snapTable.set("snap_lat", snapLat);
                snapTable.set("snap_lon", snapLon);
                snapTable.set("distance", GeometryUtils.distance(fromLats[index], fromLons[index], snapLat, snapLon));
                snapTable.set("found", true);
            } else {
                // did not find split
                snapTable.set("snap_lat", fromLats[index]);
                snapTable.set("snap_lon", fromLons[index]);
                snapTable.set("distance", -1.0);
                snapTable.set("found", false);
            }
        }

        return snapTable;

    }
}
