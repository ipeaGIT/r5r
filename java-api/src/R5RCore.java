import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.util.CSVInputStreamProvider;

import java.io.File;
import java.io.IOException;

public class R5RCore {

    private TransportNetwork transportNetwork;
    private FreeFormPointSet destinationPointSet;

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

    public void loadDestinationPointsFromCsv(String csvFile) {
        CSVInputStreamProvider csvInputStream;
        try {
            csvInputStream = new CSVInputStreamProvider(csvFile);
            destinationPointSet = FreeFormPointSet.fromCsv(csvInputStream, "lat", "lon", "id", "count");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
