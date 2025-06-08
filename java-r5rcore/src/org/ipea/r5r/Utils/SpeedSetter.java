package org.ipea.r5r.Utils;

import com.conveyal.osmlib.OSM;
import com.conveyal.osmlib.Way;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
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
     * @param pbfFile Absolute path to the pbf file
     * @param speedCsvFile Absolute path to the CSV file with columns [osm_id,max_speed]
     * @param modePercentage Mode of interpretation: FALSE = ABSOLUTE (value as KPH) or TRUE = PERCENTAGE (multiplier on existing maxspeed)
     * @return true if operation completed successfully
     * @throws Exception if reading or writing fails
     */
    public static boolean modifyOSMSpeeds(String pbfFile, String speedCsvFile, String outputFolder, double defaultValue,
                                          boolean modePercentage) throws Exception {
        SpeedSetterMode mode = getSpeedSetterMode(modePercentage);

        // Build paths
        Path outputFolderPath = Paths.get(outputFolder);
        if (!Files.exists(outputFolderPath) || !Files.isDirectory(outputFolderPath)) {
            LOG.error("Output folder does not exist or is not a directory: {}", outputFolder);
            throw new IOException("Output folder does not exist or is not a directory: " + outputFolder);
        }

        Path pbfFilePath = Paths.get(pbfFile);
        if (!Files.exists(pbfFilePath)) {
            LOG.error("PBF file not found: {}", pbfFilePath.toAbsolutePath());
            throw new IOException("Speeds CSV not found: " + pbfFilePath.toAbsolutePath());
        }

        Path speedCsvFilePath = Paths.get(speedCsvFile);
        if (!Files.exists(speedCsvFilePath)) {
            LOG.error("Speeds CSV not found: {}", speedCsvFilePath.toAbsolutePath());
            throw new IOException("Speeds CSV not found: " + speedCsvFilePath.toAbsolutePath());
        }

        // Load OSM
        OSM osm = new OSM(null);
        osm.readFromFile(pbfFilePath.toAbsolutePath().toString());
        LOG.info("Setting maxspeed:motorcar tags from {} in {} mode", speedCsvFilePath.getFileName(), mode);

        // Load CSV into a Map
        Map<Long, Double> speedMap = buildSpeedMap(speedCsvFilePath, osm);

        // Apply speeds to all ways
        modifyWaySpeeds(defaultValue, mode, osm, speedMap);

        // Write to new PBF file
        String originalPbfName = pbfFilePath.getFileName().toString();
        String csvPrefix = speedCsvFilePath.getFileName().toString().substring(0, speedCsvFilePath.getFileName().toString().length() - 4); // cut extension
        String newFileName = csvPrefix + "-" + originalPbfName;
        Path pbfOut = outputFolderPath.resolve(newFileName);
        osm.writeToFile(pbfOut.toAbsolutePath().toString());

        LOG.info("Wrote modified OSM file to: {}", pbfOut.toAbsolutePath());
        return true;
    }

    private static SpeedSetterMode getSpeedSetterMode(boolean modePercentage) {
        return modePercentage ? SpeedSetterMode.PERCENTAGE : SpeedSetterMode.ABSOLUTE;
    }

    private static Map<Long, Double> buildSpeedMap(Path speedCsvFilePath, OSM osm) throws IOException {
        Map<Long, Double> speedMap = new HashMap<>();

        try (BufferedReader br = Files.newBufferedReader(speedCsvFilePath)) {
            String header = br.readLine(); // skip header
            if (header == null) {
                LOG.error("Speeds CSV is empty: {}", speedCsvFilePath.toAbsolutePath());
                throw new IOException("Speeds CSV is empty: " + speedCsvFilePath.toAbsolutePath());
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

        return speedMap;
    }

    private static void modifyWaySpeeds(double defaultValue, SpeedSetterMode mode, OSM osm, Map<Long, Double> speedMap) {
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
    }
}
