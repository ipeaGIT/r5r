package org.ipea.r5r.Scenario;

import com.conveyal.r5.analyst.scenario.Modification;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.transit.TransportNetwork;
import gnu.trove.list.TShortList;
import gnu.trove.list.array.TIntArrayList;
import gnu.trove.list.array.TLongArrayList;
import gnu.trove.list.array.TShortArrayList;
import gnu.trove.set.hash.TLongHashSet;
import org.slf4j.LoggerFactory;

import java.util.HashMap;

import static com.conveyal.r5.streets.EdgeStore.EdgeFlag;

public class RoadCongestionOSM extends Modification {
    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RoadCongestionOSM.class);

    /**
     * The default value by which to scale when no polygon is found.
     */
    public float defaultScaling = 1;

    /**
     * A HashMap with key [osm_id] and value [max_speed]
     */
    public HashMap<Long, Float> speedMap;

    public boolean absoluteMode = false;


    @Override
    public boolean resolve(TransportNetwork network) {
        TLongHashSet osmIdSet = new TLongHashSet();
        for (int i = 0; i < network.streetLayer.edgeStore.osmids.size(); i++) {
            // need to manually iterate because the iterator of osmids is disabled
            osmIdSet.add(network.streetLayer.edgeStore.osmids.get(i));
        }
        TLongArrayList badIds = new TLongArrayList();

        for (Long osmId : speedMap.keySet()) {
            if (!osmIdSet.contains(osmId)) {
                badIds.add(osmId);
            }
        }

        if (!badIds.isEmpty()) {
            // this.addWarning("Cannot find the following OSM IDs in network: " + badIds);
            LOG.warn("Cannot find the following OSM IDs in network: {}", badIds);
        }

        return hasErrors();
    }

    @Override
    public boolean apply(TransportNetwork network) {
        LOG.info("Applying road congestion by OSM id...");

        EdgeStore edgeStore = network.streetLayer.edgeStore;
        EdgeStore.Edge edge = edgeStore.getCursor();
        network.streetLayer.edgeStore.flags = new TIntArrayList(network.streetLayer.edgeStore.flags);

        while (edge.advance()) {
            Float value = speedMap.get(edge.getOSMID());

            float scaling = (value == null) ? defaultScaling : value;

            if (scaling == 0) {
                edge.clearFlag(EdgeFlag.ALLOWS_CAR);
            } else if (value != null && absoluteMode) {
                edge.setSpeedKph(value);
            } else {
                edge.setSpeed((short) (edge.getSpeed() * scaling));
            }
        }

        return hasErrors();
    }

    @Override
    public int getSortOrder() {
        return 95;
    }

    @Override
    public boolean affectsStreetLayer() {
        // This modification only affects the street speeds, but changes nothing at all about public transit.
        return true;
    }

    @Override
    public boolean affectsTransitLayer() {
        // This modification only affects the street speeds, but changes nothing at all about public transit.
        return false;
    }
}
