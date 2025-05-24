package org.ipea.r5r.Utils;

import com.conveyal.osmlib.OSM;
import com.conveyal.osmlib.Way;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class SpeedSetter {

    private static final Logger LOG = LoggerFactory.getLogger(SpeedSetter.class);

    public enum SpeedSetterMode {
        ABSOLUTE, PERCENTAGE
    }

    /**
     * Reads an OSM PBF from dataFolder/*.pbf, applies maxspeed:motorcar tags based on the given CSV
     * and writes out a new PBF called congested_<original>.pbf in the same folder.
     *
     * @param dataFolder       Path to the folder containing the .pbf and the CSV
     * @param speedCsvFileName Name of the CSV file with columns [osmWayId,value]
     * @param mode             Mode of interpretation: ABSOLUTE (value as KPH) or PERCENTAGE (multiplier on existing maxspeed)
     * @return true if operation completed successfully
     * @throws Exception if reading or writing fails
     */
    public static boolean modifyOSMSpeeds(String dataFolder, String speedCsvFileName, double defaultValue,
                                          SpeedSetterMode mode) throws Exception {
        // Build paths
        File folder = new File(dataFolder);
        if (!folder.exists() || !folder.isDirectory()) {
            LOG.error("Data folder does not exist or is not a directory: {}", dataFolder);
            throw new IOException("Data folder does not exist or is not a directory: " + dataFolder);
        }

        // Find the first .pbf file in the folder
        File[] pbfFiles = folder.listFiles((dir, name) -> name.toLowerCase().endsWith(".pbf"));
        if (pbfFiles == null || pbfFiles.length != 1) {
            LOG.error("None or multiple .pbf file found in folder: {}", dataFolder);
            throw new IOException("None or multiple .pbf file found in folder: " + dataFolder);
        }
        File pbfIn = pbfFiles[0];

        File speedsFile = new File(folder, speedCsvFileName);
        if (!speedsFile.exists()) {
            LOG.error("Speeds CSV not found: {}", speedsFile.getAbsolutePath());
            throw new IOException("Speeds CSV not found: " + speedsFile.getAbsolutePath());
        }

        // Load OSM
        OSM osm = new OSM(null);
        osm.readFromFile(pbfIn.getAbsolutePath());
        LOG.info("Setting maxspeed:motorcar tags from {} in {} mode", speedsFile.getName(), mode);

        // Load CSV into a Map
        Map<Long, Double> speedMap = new HashMap<>();

        try (BufferedReader br = new BufferedReader(new FileReader(speedsFile))) {
            String header = br.readLine(); // skip header
            if (header == null) {
                LOG.error("Speeds CSV is empty: {}", speedsFile.getAbsolutePath());
                throw new IOException("Speeds CSV is empty: " + speedsFile.getAbsolutePath());
            }

            String line;
            while ((line = br.readLine()) != null) {
                String[] fields = line.split(",");
                if (fields.length < 2) continue; // skip malformed lines

                try {
                    long osmWayId = Long.parseLong(fields[0].trim());
                    double value = Double.parseDouble(fields[1].trim());
                    Way way = osm.ways.get(osmWayId);
                    if (way == null) {
                        LOG.warn("Way ID not found in OSM data, skipping: {}", osmWayId);
                        continue;
                    }
                    speedMap.put(osmWayId, value);
                } catch (NumberFormatException nfe) {
                    LOG.warn("Skipping invalid line in CSV: {}", line);
                }
            }
        }

        // Apply speeds to all ways
        for (Map.Entry<Long, Way> entry : osm.ways.entrySet()) {
            long wayId = entry.getKey();
            Way way = entry.getValue();

            double speedKph;
            Double value = speedMap.getOrDefault(wayId, defaultValue); // default value should always be -1 if absolute mode

            // disable road if speed is 0
            if (value == 0) {
                way.addOrReplaceTag("highway", "construction");
                continue;
            }

            if (mode == SpeedSetterMode.ABSOLUTE) {
                if (value == -1) continue; // skip setting a default if absolute mode
                speedKph = value;
            } else {
                // PERCENTAGE mode: apply multiplier to existing maxspeed tag
                String existingSpeed = way.getTag("maxspeed");
                if (existingSpeed == null) {
                    LOG.warn("No existing maxspeed for way {}, skipping percentage adjustment", wayId);
                    continue;
                }
                try {
                    double base = Double.parseDouble(existingSpeed);
                    speedKph = base * value;
                } catch (NumberFormatException nfe) {
                    LOG.warn("Cannot parse existing maxspeed='{}' for way {}, skipping", existingSpeed, wayId);
                    continue;
                }
            }

            way.addOrReplaceTag("maxspeed:motorcar", String.format("%1.1f kph", speedKph));
        }

        // Write to new PBF file
        String originalFileName = pbfIn.getName();
        String newFileName = "congested_" + originalFileName;
        File pbfOut = new File(folder, newFileName);
        osm.writeToFile(pbfOut.getAbsolutePath());

        LOG.info("Wrote modified OSM file to: {}", pbfOut.getAbsolutePath());
        return true;
    }
}
