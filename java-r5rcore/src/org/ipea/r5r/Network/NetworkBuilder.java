package org.ipea.r5r.Network;

import com.conveyal.analysis.datasource.DataSourceException;
import com.conveyal.gtfs.GTFSFeed;
import com.conveyal.osmlib.OSM;
import com.conveyal.r5.analyst.scenario.RasterCost;
import com.conveyal.r5.kryo.KryoNetworkSerializer;
import com.conveyal.r5.streets.StreetLayer;
import com.conveyal.r5.transit.TransferFinder;
import com.conveyal.r5.transit.TransportNetwork;
import org.apache.commons.io.FilenameUtils;
import org.ipea.r5r.R5RCore;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class NetworkBuilder {

    public static boolean useNativeElevation = false;
    public static String elevationCostFunction = "NONE";

    private static List<String> gtfsFiles = new ArrayList<>();
    private static String osmFilename;

    private static OSM osmFile;
    private static Stream<GTFSFeed> gtfsFeeds;
    private static String tiffFile = "";

    public static TransportNetwork checkAndLoadR5Network(String dataFolder) throws Exception {
        File file = new File(dataFolder, "network.dat");
        if (!file.isFile()) {
            // network.dat file does not exist. create!
            NetworkBuilder.createR5Network(dataFolder);
        } else {
            // network.dat file exists
            // check version
            if (!NetworkChecker.checkR5NetworkVersion(dataFolder)) {
                // incompatible versions. try to create a new one
                // network could not be loaded, probably due to incompatible versions. create a new one
                NetworkBuilder.createR5Network(dataFolder);
            }
        }
        // compatible versions, load network
        return NetworkBuilder.loadR5Network(dataFolder);
    }

    public static TransportNetwork loadR5Network(String dataFolder) throws Exception {
        return KryoNetworkSerializer.read(new File(dataFolder, "network.dat"));
    }

    public static void createR5Network(String dataFolder) {
        File dir = new File(dataFolder);

        cleanUpMapdb(dir);

        loadDirectory(dir);

        TransportNetwork tn = createNetwork();

        Map<String, String> networkConfig = buildNetworkConfig();

        try {
            KryoNetworkSerializer.write(tn, new File(dataFolder, "network.dat"));
            writeNetworkSettings(dataFolder, networkConfig);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void writeNetworkSettings(String dataFolder, Map<String, String> networkConfig) throws IOException {
        String json = "{" + networkConfig.entrySet().stream()
                .map(e -> "\""+ e.getKey() + "\":\"" + e.getValue() + "\"")
                .collect(Collectors.joining(", "))+"}";

        FileWriter fileWriter = new FileWriter(new File(dataFolder, "network_settings.json"));
        PrintWriter printWriter = new PrintWriter(fileWriter);
        printWriter.print(json);
        printWriter.close();
    }

    private static Map<String, String> buildNetworkConfig() {
        Map<String, String> networkConfig = new LinkedHashMap<>();

        networkConfig.put("r5_version", R5RCore.R5_VERSION);
        networkConfig.put("r5_network_version", KryoNetworkSerializer.NETWORK_FORMAT_VERSION);
        networkConfig.put("r5r_version", R5RCore.R5R_VERSION);
        networkConfig.put("creation_date", LocalDateTime.now().toString());

        networkConfig.put("pbf_file_name", osmFilename);

        for (int i = 0; i < gtfsFiles.size(); i++) {
            networkConfig.put("gtfs_" + (i + 1), gtfsFiles.get(i));
        }

        networkConfig.put("use_elevation", String.valueOf(useNativeElevation));
        networkConfig.put("elevation_cost_function", elevationCostFunction);
        networkConfig.put("tiff_file_name", tiffFile);

        return networkConfig;
    }

    private static TransportNetwork createNetwork() {
        TransportNetwork network = new TransportNetwork();

        network.scenarioId = "r5r";
        network.streetLayer = new StreetLayer();
        network.streetLayer.loadFromOsm(osmFile);
        osmFile.close();

        network.streetLayer.parentNetwork = network;
        network.streetLayer.indexStreets();

        network.transitLayer = new TransitLayerWithShapes();

        gtfsFeeds.forEach(gtfsFeed -> {
            network.transitLayer.loadFromGtfs(gtfsFeed);
            // Is there a reason we can't push this close call down into the loader method? Maybe exception handling?
            gtfsFeed.close();
        });

        network.transitLayer.parentNetwork = network;
        network.streetLayer.associateStops(network.transitLayer);
        network.streetLayer.buildEdgeLists();

        network.rebuildTransientIndexes();

        TransferFinder transferFinder = new TransferFinder(network);
        transferFinder.findTransfers();
        transferFinder.findParkRideTransfer();

        // apply elevation costs if a tiff file is available
        try
        {
            if (useNativeElevation) {
                if (!tiffFile.equals("")) {
                    RasterCost elevationRaster = new RasterCost();
                    elevationRaster.dataSourceId = FilenameUtils.removeExtension(tiffFile);
                    elevationRaster.costFunction = RasterCost.CostFunction.valueOf(elevationCostFunction);

                    elevationRaster.resolve(network);
                    elevationRaster.apply(network);

                }
            }
        } catch (DataSourceException e) {
            e.printStackTrace();
        }

        network.scenarioId = "r5r";

        // Networks created in TransportNetworkCache are going to be used for analysis work. Pre-compute distance tables
        // from stops to street vertices, then pre-build a linked grid point set for the whole region. These linkages
        // should be serialized along with the network, which avoids building them when an analysis worker starts.
        // The linkage we create here will never be used directly, but serves as a basis for scenario linkages, making
        // analysis much faster to start up.
        network.transitLayer.buildDistanceTables(null);

        // pre-calculate transfers between transit stops
        new TransferFinder(network).findTransfers();

        return network;
    }

    public static void loadDirectory(File directory) {
        osmFilename = "";
        tiffFile = "";
        gtfsFiles.clear();

        for (File file : Objects.requireNonNull(directory.listFiles())) {
            String name = file.getName();

            if (name.endsWith(".pbf")) {
                osmFilename = file.getAbsolutePath();

                // Load OSM data into MapDB to pass into network builder.
                osmFile = new OSM(osmFilename + ".mapdb");
                osmFile.intersectionDetection = true;
                osmFile.readFromFile(osmFilename);
            }
            if (name.endsWith(".zip")) gtfsFiles.add(file.getAbsolutePath());
            if (name.endsWith(".tif") | name.endsWith(".tiff")) tiffFile = file.getAbsolutePath();
        }

        // Supply feeds with a stream, so they do not sit open in memory while other feeds are being processed.
        gtfsFeeds = gtfsFiles.stream().map(GTFSFeed::readOnlyTempFileFromGtfs);
    }

    private static void cleanUpMapdb(File dir) {
        // clean up older mapdb files
        File[] mapdbFiles = dir.listFiles((d, name) -> name.contains(".mapdb"));

        if (mapdbFiles != null) { for (File file:mapdbFiles) file.delete(); }
    }


}
