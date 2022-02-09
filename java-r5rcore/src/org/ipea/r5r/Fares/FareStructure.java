package org.ipea.r5r.Fares;

import org.ipea.r5r.RDataFrame;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

public class FareStructure {

    /**
     * When fares are not found in farePerMode or farePerTransfer, the value of baseFare is used.
     */
    private int baseFare;

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

    private final RDataFrame farePerModeTable;
    private final RDataFrame farePerTransferTable;
    private final RDataFrame routesInfoTable;

    // Getters and Setters
    public int getBaseFare() {
        return baseFare;
    }

    public void setBaseFare(int baseFare) {
        this.baseFare = baseFare;
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

    public RDataFrame getFarePerModeTable() {
        return farePerModeTable;
    }
    public RDataFrame getFarePerTransferTable() {
        return farePerTransferTable;
    }
    public RDataFrame getRoutesInfoTable() {
        return routesInfoTable;
    }

    public FareStructure() {
        this(100);
    }

    public FareStructure(int fare) {
        this.baseFare = fare;
        this.maxDiscountedTransfers = 1;
        this.transferTimeAllowance = 120;
        this.fareCap = -1;

        this.farePerModeTable = new RDataFrame();
        this.farePerModeTable.addStringColumn("mode", "BUS");
        this.farePerModeTable.addBooleanColumn("unlimited_transfers", false);
        this.farePerModeTable.addBooleanColumn("allow_same_route_transfer", true);
        this.farePerModeTable.addBooleanColumn("use_route_fare", false);
        this.farePerModeTable.addIntegerColumn("fare", this.baseFare);

        this.farePerTransferTable = new RDataFrame();
        this.farePerTransferTable.addStringColumn("leg1", "BUS");
        this.farePerTransferTable.addStringColumn("leg2", "BUS");
        this.farePerTransferTable.addIntegerColumn("fare", this.baseFare);

        this.routesInfoTable = new RDataFrame();
        this.routesInfoTable.addStringColumn("agency_id", "");
        this.routesInfoTable.addStringColumn("agency_name", "");
        this.routesInfoTable.addStringColumn("route_id", "");
        this.routesInfoTable.addStringColumn("route_short_name", "");
        this.routesInfoTable.addStringColumn("route_long_name", "");
        this.routesInfoTable.addStringColumn("mode", "");
        this.routesInfoTable.addIntegerColumn("route_fare", this.baseFare);
        this.routesInfoTable.addStringColumn("fare_type", "");
    }

    public static FareStructure fromJson(String data) {
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

                fareStructure.farePerModeTable.append();
                fareStructure.farePerModeTable.set("mode", (String) item.get("mode"));
                fareStructure.farePerModeTable.set("unlimited_transfers", (Boolean) item.get("unlimited_transfers"));
                fareStructure.farePerModeTable.set("allow_same_route_transfer", (Boolean) item.get("allow_same_route_transfer"));
                fareStructure.farePerModeTable.set("use_route_fare", (Boolean) item.get("use_route_fare"));
                fareStructure.farePerModeTable.set("fare", ((Long) item.get("fare")).intValue());
            }

            JSONArray farePerTransfer = (JSONArray) json.get("fare_per_transfer");
            for (JSONObject item : (Iterable<JSONObject>) farePerTransfer) {

                fareStructure.farePerTransferTable.append();
                fareStructure.farePerTransferTable.set("leg1", (String) item.get("leg1"));
                fareStructure.farePerTransferTable.set("leg2", (String) item.get("leg2"));
                fareStructure.farePerTransferTable.set("fare", ((Long) item.get("fare")).intValue());
            }

            JSONArray routesInfo = (JSONArray) json.get("routes_info");
            for (JSONObject item : (Iterable<JSONObject>) routesInfo) {

                fareStructure.routesInfoTable.append();
                fareStructure.routesInfoTable.set("agency_id", (String) item.get("agency_id"));
                fareStructure.routesInfoTable.set("agency_name", (String) item.get("agency_name"));
                fareStructure.routesInfoTable.set("route_id", (String) item.get("route_id"));
                fareStructure.routesInfoTable.set("route_short_name", (String) item.get("route_short_name"));
                fareStructure.routesInfoTable.set("route_long_name", (String) item.get("route_long_name"));
                fareStructure.routesInfoTable.set("mode", (String) item.get("mode"));
                fareStructure.routesInfoTable.set("route_fare", ((Long) item.get("route_fare")).intValue());
                fareStructure.routesInfoTable.set("fare_type", (String) item.get("fare_type"));
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
    }

}
