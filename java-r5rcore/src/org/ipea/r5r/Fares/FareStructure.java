package org.ipea.r5r.Fares;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class FareStructure {

    /**
     * When fares are not found in farePerMode or farePerTransfer, the value of baseFare is used.
     */
    private float baseFare;
    @JsonIgnore
    private int integerBaseFare;

    /**
     * Maximum number of transfers that can have a discount. The transfer fare is obtained from the farePerTransfer
     * Map up to the number of transfers informed in this field. After that, each new leg gets the full fare from the
     * farePerMode Map.
     */
    private int maxDiscountedTransfers;

    /**
     * Maximum time allowed for discounted transfers, counting from the time of  boarding first transit leg
    */
    private int transferTimeAllowance;

    /**
     * Maximum charged fare for any combination of trips.
     */
    private int fareCap;

    private final List<FarePerMode> faresPerMode;
    private final List<FarePerTransfer> faresPerTransfer;
    private final List <FarePerRoute> faresPerRoute;

    // Getters and Setters
    public float getBaseFare() {
        return baseFare;
    }

    public int getIntegerBaseFare() {
        return integerBaseFare;
    }

    public void setBaseFare(float baseFare) {
        this.baseFare = baseFare;
        this.integerBaseFare = Math.round(baseFare * 100.0f);
    }

    public int getMaxDiscountedTransfers() {
        return maxDiscountedTransfers;
    }

    public void setMaxDiscountedTransfers(int maxDiscountedTransfers) {
        this.maxDiscountedTransfers = maxDiscountedTransfers;
    }

    public int getTransferTimeAllowance() {
        return transferTimeAllowance;
    }

    public void setTransferTimeAllowance(int transferTimeAllowance) {
        this.transferTimeAllowance = transferTimeAllowance;
    }

    public int getFareCap() {
        return fareCap;
    }

    public void setFareCap(int fareCap) {
        this.fareCap = fareCap;
    }

    public List<FarePerMode> getFaresPerMode() {
        return faresPerMode;
    }

    public List<FarePerTransfer> getFaresPerTransfer() {
        return faresPerTransfer;
    }

    public List<FarePerRoute> getFaresPerRoute() {
        return faresPerRoute;
    }

//    public Map<String, String> getDebugSettings() {
//        Map<String, String> map = new HashMap<>();
//
//        map.put("output_file", RuleBasedInRoutingFareCalculator.debugFileName);
//        map.put("trip_info", RuleBasedInRoutingFareCalculator.debugTripInfo);
//
//        return map;
//    }

    public FareStructure() {
        this(100);
    }

    public FareStructure(float fare) {
        this.baseFare = fare;
        this.integerBaseFare = Math.round(fare * 100.0f);

        this.maxDiscountedTransfers = 1;
        this.transferTimeAllowance = 120;
        this.fareCap = -1;

        this.faresPerMode = new ArrayList<>();
        this.faresPerTransfer = new ArrayList<>();
        this.faresPerRoute = new ArrayList<>();
    }

    public static FareStructure fromJson(String data) {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
            FareStructure fareStructure = objectMapper.readValue(data, FareStructure.class);

//            Map<String, String> debugMap = fareStructure.getDebugSettings();
//            RuleBasedInRoutingFareCalculator.debugFileName = debugMap.get("output_file");
//            RuleBasedInRoutingFareCalculator.debugTripInfo = debugMap.get("trip_info");
//            RuleBasedInRoutingFareCalculator.debugActive = !debugMap.get("output_file").equals("");

            return fareStructure;
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return null;
        }

        /*
        FareStructure fareStructure = new FareStructure();

        JSONParser parser = new JSONParser();
        try {
            JSONObject json = (JSONObject) parser.parse(data);

            // setting global properties
            fareStructure.setBaseFare(((Long) json.get("base_fare")).intValue());
            fareStructure.setMaxDiscountedTransfers(((Long) json.get("max_discounted_transfers")).intValue());
            fareStructure.setTransferTimeAllowance(((Long) json.get("transfer_time_allowance")).intValue());

            String fareCap = (String) json.get("fare_cap");
            if (fareCap.equals("Inf")) {
                fareStructure.setFareCap(Integer.MAX_VALUE);
            } else {
                fareStructure.setFareCap(Integer.parseInt(fareCap));
            }

            JSONArray farePerMode = (JSONArray) json.get("fare_per_mode");
            for (JSONObject item : (Iterable<JSONObject>) farePerMode) {

//                fareStructure.farePerModeTable.append();
//                fareStructure.farePerModeTable.set("mode", (String) item.get("mode"));
//                fareStructure.farePerModeTable.set("unlimited_transfers", (Boolean) item.get("unlimited_transfers"));
//                fareStructure.farePerModeTable.set("allow_same_route_transfer", (Boolean) item.get("allow_same_route_transfer"));
//                fareStructure.farePerModeTable.set("use_route_fare", (Boolean) item.get("use_route_fare"));
//                fareStructure.farePerModeTable.set("fare", ((Long) item.get("fare")).intValue());
            }

            JSONArray farePerTransfer = (JSONArray) json.get("fare_per_transfer");
            for (JSONObject item : (Iterable<JSONObject>) farePerTransfer) {

//                fareStructure.farePerTransferTable.append();
//                fareStructure.farePerTransferTable.set("leg1", (String) item.get("leg1"));
//                fareStructure.farePerTransferTable.set("leg2", (String) item.get("leg2"));
//                fareStructure.farePerTransferTable.set("fare", ((Long) item.get("fare")).intValue());
            }

            JSONArray routesInfo = (JSONArray) json.get("routes_info");
            for (JSONObject item : (Iterable<JSONObject>) routesInfo) {

//                fareStructure.routesInfoTable.append();
//                fareStructure.routesInfoTable.set("agency_id", (String) item.get("agency_id"));
//                fareStructure.routesInfoTable.set("agency_name", (String) item.get("agency_name"));
//                fareStructure.routesInfoTable.set("route_id", (String) item.get("route_id"));
//                fareStructure.routesInfoTable.set("route_short_name", (String) item.get("route_short_name"));
//                fareStructure.routesInfoTable.set("route_long_name", (String) item.get("route_long_name"));
//                fareStructure.routesInfoTable.set("mode", (String) item.get("mode"));
//                fareStructure.routesInfoTable.set("route_fare", ((Long) item.get("route_fare")).intValue());
//                fareStructure.routesInfoTable.set("fare_type", (String) item.get("fare_type"));
            }

            JSONObject debugSettings = (JSONObject) json.get("debug_settings");
            String debugOutputFile = (String) debugSettings.get("output_file");
            String tripInfo = (String) debugSettings.get("trip_info");

            RuleBasedInRoutingFareCalculator.debugFileName = debugOutputFile;
            RuleBasedInRoutingFareCalculator.debugTripInfo = tripInfo.toUpperCase();
            RuleBasedInRoutingFareCalculator.debugActive = !debugOutputFile.equals("");

        } catch (ParseException e) {
            e.printStackTrace();
        }

        return fareStructure;

 */
    }

    public String toJson() {
        ObjectMapper objectMapper = new ObjectMapper();
        try {
            objectMapper.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
            return objectMapper.writeValueAsString(this);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }

        return "";
    }

}
