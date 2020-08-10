package org.ipea.r5r;

import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.transit.TransportNetwork;

import java.io.File;
import java.io.IOException;

public class R5RCore {
    TransportNetwork transportNetwork;
    FreeFormPointSet destinationPointSet;

    public R5RCore(String networkPath) {
        File file = new File(networkPath + "network.dat");
        if (!file.isFile()) {
            // network.dat file does not exist. create!
            transportNetwork = TransportNetwork.fromDirectory(new File(networkPath));
            try {
                KryoNetworkSerializer.write(transportNetwork, new File(networkPath, "network.dat"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        try {
            transportNetwork = KryoNetworkSerializer.read(new File(networkPath, "network.dat"));
            transportNetwork.readOSM(new File(networkPath, "osm.mapdb"));
            transportNetwork.transitLayer.buildDistanceTables(null);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
