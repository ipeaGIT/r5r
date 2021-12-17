package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import com.csvreader.CsvReader;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
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

    // base fare for routes that are not in the fare_schema (high value so it is avoided during routing
    private final int baseFare = Integer.MAX_VALUE;

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
        int fareForState = 0;

        // extract the relevant rides
        TIntList patterns = new TIntArrayList();

        while (state != null) {
            if (state.pattern > -1) patterns.add(state.pattern);
            state = state.back;
        }

        patterns.reverse();

        RouteInfo previousRoute = null;
        boolean discountAlreadyApplied = false;

        StringBuilder debugger = new StringBuilder();

        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);

            if (ri.route_short_name != null && !ri.route_short_name.equals("null")) {
                debugger.append(ri.route_short_name).append(" -> ");
            } else {
                debugger.append(ri.route_id).append(" -> ");
            }


            if (previousRoute == null || discountAlreadyApplied) {
                // first public transport leg or discount already applied... full ticket price
                fareForState += getFullFareForRoute(ri);
            } else {
                // test if discount for subsequent legs is applicable
                IntegratedFare integratedFare = getIntegrationFare(previousRoute, ri);

                fareForState += integratedFare.fare;
                if (integratedFare.usedDiscount) discountAlreadyApplied = true;
            }

            previousRoute = ri;
        }

        debugger.append(fareForState);
        System.out.println(debugger);

        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(RouteInfo ri) {
        String mode = modeOfRoute.get(ri.route_id);

        if (mode != null) {
            return farePerMode.get(mode);
        } else {
            return baseFare;
        }
    }

    private IntegratedFare getIntegrationFare(RouteInfo firstRoute, RouteInfo secondRoute) {
        String firstLegMode = modeOfRoute.get(firstRoute.route_id);
        String secondLegMode = modeOfRoute.get(secondRoute.route_id);

        if (firstLegMode != null && secondLegMode != null) {
            Integer fare = farePerTransfer.get(firstLegMode + "&" + secondLegMode);
            if (fare == null) {
                int fareSecondLeg = getFullFareForRoute(secondRoute);

                return new IntegratedFare(fareSecondLeg, false);

            } else {
                int fareFirstLeg = getFullFareForRoute(firstRoute);
                return new IntegratedFare(fare - fareFirstLeg, true);
            }
        } else {
            return new IntegratedFare(baseFare, false);
        }
    }

    @Override
    public String getType() {
        return "rio-de-janeiro";
    }
}
