package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.csvreader.CsvReader;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

public class RioDeJaneiroInRoutingFareCalculator extends InRoutingFareCalculator {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RioDeJaneiroInRoutingFareCalculator.class);

    private Map<String, String> modeOfRoute;
    private Map<String, Integer> farePerMode;
    private Map<String, Integer> farePerTransfer;

    public RioDeJaneiroInRoutingFareCalculator() {
        // load fares csv from:
        // resources/fares/rio
        loadFarePerMode();
        loadModeOfRoute();
        loadFarePerTransfer();
    }

    private void loadFarePerTransfer() {
        this.farePerTransfer = new HashMap<>();
        try {
            InputStream is = getClass().getClassLoader().getResourceAsStream("fares/rio/fare_schema.csv");
            CsvReader reader = new CsvReader(is, ',', StandardCharsets.UTF_8);
            reader.readHeaders();
            while (reader.readRecord()) {
                String integrationId = reader.get("int_id");
                Integer fare = (int)(Double.parseDouble(reader.get("fare")) * 100);

                this.farePerTransfer.put(integrationId, fare);
            }
            is.close();
        } catch (Exception ex) {
            LOG.error("Error while loading Rio de Janeiro's route info CSV table: " + ex.getMessage());
        }
    }

    private void loadModeOfRoute() {
        this.modeOfRoute = new HashMap<>();
        try {
            InputStream is = getClass().getClassLoader().getResourceAsStream("fares/rio/routes_info.csv");
            CsvReader reader = new CsvReader(is, ',', StandardCharsets.UTF_8);
            reader.readHeaders();
            while (reader.readRecord()) {
                String routeId = reader.get("route_id");
                String type = reader.get("type");

                this.modeOfRoute.put(routeId, type);
            }
            is.close();
        } catch (Exception ex) {
            LOG.error("Error while loading Rio de Janeiro's route info CSV table: " + ex.getMessage());
        }
    }

    private void loadFarePerMode() {
        this.farePerMode = new HashMap<>();
        try {
            InputStream is = getClass().getClassLoader().getResourceAsStream("fares/rio/price_per_mode.csv");
            CsvReader reader = new CsvReader(is, ',', StandardCharsets.UTF_8);
            reader.readHeaders();
            while (reader.readRecord()) {
                String type = reader.get("type");
                Integer fare = (int)(Double.parseDouble(reader.get("price")) * 100);

                this.farePerMode.put(type, fare);
            }
            is.close();
        } catch (Exception ex) {
            LOG.error("Error while loading Rio de Janeiro's fares CSV table: " + ex.getMessage());
        }
    }

    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        return new FareBounds(1, new TransferAllowance());
    }

    @Override
    public String getType() {
        return "rio-de-janeiro";
    }
}
