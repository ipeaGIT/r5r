import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.transit.TransportNetwork;

import java.io.File;
import java.io.IOException;

public class R5RCore {

    TransportNetwork transportNetwork;

    public R5RCore(String dataFolder) {
        File file = new File(dataFolder + "network.dat");
        if (!file.isFile()) {
            // network.dat file does not exist. create!
            transportNetwork = TransportNetwork.fromDirectory(new File(dataFolder));
            try {
                KryoNetworkSerializer.write(transportNetwork, new File(dataFolder, "network.dat"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        try {
            transportNetwork = KryoNetworkSerializer.read(new File(dataFolder, "network.dat"));
//            transportNetwork.readOSM(new File(dir, "osm.mapdb"));
            transportNetwork.transitLayer.buildDistanceTables(null);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
