package org.ipea.r5r.Scenario;

import com.conveyal.r5.analyst.scenario.Modification;
import com.conveyal.r5.streets.EdgeStore;
import com.conveyal.r5.transit.TransportNetwork;
import gnu.trove.list.array.TIntArrayList;
import gnu.trove.list.array.TLongArrayList;
import gnu.trove.set.hash.TLongHashSet;
import org.slf4j.LoggerFactory;

import java.util.HashMap;

import static com.conveyal.r5.streets.EdgeStore.EdgeFlag.BIKE_LTS_EXPLICIT;

public class SetLtsOsm extends Modification {
    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(SetLtsOsm.class);

    /** A HashMap with key [osm_id] and value [max_speed] */
    public HashMap<Long, Integer> ltsMap;

    @Override
    public boolean resolve(TransportNetwork network) {
        TLongHashSet osmIdSet = new TLongHashSet();
        for (int i = 0; i < network.streetLayer.edgeStore.osmids.size(); i++) {
            // need to manually iterate because the iterator of osmids is disabled
            osmIdSet.add(network.streetLayer.edgeStore.osmids.get(i));
        }
        TLongArrayList badIds = new TLongArrayList();

        for (Long osmId : ltsMap.keySet()) {
            if (!osmIdSet.contains(osmId)){ badIds.add(osmId); }
        }

        if (!badIds.isEmpty()) {
            // this.addWarning("Cannot find the following OSM IDs in network: " + badIds);
            LOG.warn("Cannot find the following OSM IDs in network: {}", badIds);
        }

        return hasErrors();
    }

    @Override
    public boolean apply(TransportNetwork network) {
        LOG.info("Setting LTS levels by OSM id...");

        network.streetLayer.edgeStore.flags = new TIntArrayList(network.streetLayer.edgeStore.flags);
        EdgeStore edgeStore = network.streetLayer.edgeStore;
        EdgeStore.Edge edge = edgeStore.getCursor();

        while (edge.advance()) {
            int lts = ltsMap.getOrDefault(edge.getOSMID(), 0);
            if (lts == 0) continue;

            edge.setFlag(BIKE_LTS_EXPLICIT);
            edge.setLts(lts);
        }

        return hasErrors();
    }

    @Override
    public int getSortOrder() {
        return 95;
    }

    @Override
    public boolean affectsStreetLayer () {
        // This modification only affects the lts levels, but changes nothing at all about public transit.
        return true;
    }

    @Override
    public boolean affectsTransitLayer () {
        // This modification only affects the lts levels, but changes nothing at all about public transit.
        return false;
    }
}
