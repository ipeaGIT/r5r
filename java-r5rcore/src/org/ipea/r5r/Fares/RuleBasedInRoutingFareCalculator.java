package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

/*
 * support data classes
 */

class ModeData {
    String mode;
    boolean unlimitedTransfers;
    boolean allowTransferToSameRoute;
    boolean useRouteFare;
    int fare;

    @Override
    public String toString() {
        return "ModeData{" +
                "mode='" + mode + '\'' +
                ", unlimitedTransfers=" + unlimitedTransfers +
                ", allowTransferTooSameRoute=" + allowTransferToSameRoute +
                ", useRouteFare=" + useRouteFare +
                ", fare=" + fare +
                '}';
    }
}

class TransferData {
    String leg1;
    String leg2;
    int fare;

    @Override
    public String toString() {
        return "TransferData{" +
                "leg1='" + leg1 + '\'' +
                ", leg2='" + leg2 + '\'' +
                ", fare=" + fare +
                '}';
    }
}

class RouteInfoData {
    String routeId;
    String mode;
    int fare;

    @Override
    public String toString() {
        return "RouteInfoData{" +
                "routeId='" + routeId + '\'' +
                ", mode='" + mode + '\'' +
                ", fare=" + fare +
                '}';
    }
}

public class RuleBasedInRoutingFareCalculator extends InRoutingFareCalculator {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RuleBasedInRoutingFareCalculator.class);

    public static String debugFileName = "";
    public static String debugTripInfo = "";
    public static boolean debugActive = false;

    private final FareStructure fareStructure;

    private Map<String, RouteInfoData> routeInfo;
    private Map<String, ModeData> farePerMode;
    private Map<String, TransferData> farePerTransfer;

    private Set<String> debugOutput;

    public Set<String> getDebugOutput() {
        return debugOutput;
    }

    public RuleBasedInRoutingFareCalculator(String jsonData) {
        this.fareStructure = FareStructure.fromJson(jsonData);

        if (debugActive) {
            this.debugOutput = new ConcurrentSkipListSet<>();
        }

        // fill fare information lookup tables
        loadFarePerMode();
        loadModeOfRoute();
        loadFarePerTransfer();
    }

    private void loadFarePerMode() {
        this.farePerMode = new HashMap<>();

        for (int i = 0; i < fareStructure.getFarePerModeTable().nRow(); i++) {
            fareStructure.getFarePerModeTable().seek(i);

            ModeData data = new ModeData();
            data.mode = fareStructure.getFarePerModeTable().getStringValue("mode");
            data.unlimitedTransfers = fareStructure.getFarePerModeTable().getBooleanValue("unlimited_transfers");
            data.allowTransferToSameRoute = fareStructure.getFarePerModeTable().getBooleanValue("allow_same_route_transfer");
            data.useRouteFare = fareStructure.getFarePerModeTable().getBooleanValue("use_route_fare");
            data.fare = fareStructure.getFarePerModeTable().getIntValue("fare");

            farePerMode.put(data.mode, data);

//            LOG.error(data.toString());
        }
    }

    private void loadFarePerTransfer() {
        this.farePerTransfer = new HashMap<>();

        for (int i = 0; i < fareStructure.getFarePerTransferTable().nRow(); i++) {
            fareStructure.getFarePerTransferTable().seek(i);

            String key = fareStructure.getFarePerTransferTable().getStringValue("leg1") + "&" +
                    fareStructure.getFarePerTransferTable().getStringValue("leg2");

            TransferData data = new TransferData();
            data.leg1 = fareStructure.getFarePerTransferTable().getStringValue("leg1");
            data.leg2 = fareStructure.getFarePerTransferTable().getStringValue("leg2");
            data.fare = fareStructure.getFarePerTransferTable().getIntValue("fare");

            farePerTransfer.put(key, data);

//            LOG.error(data.toString());
        }
    }

    private void loadModeOfRoute() {
        this.routeInfo = new HashMap<>();

        for (int i = 0; i < fareStructure.getRoutesInfoTable().nRow(); i++) {
            fareStructure.getRoutesInfoTable().seek(i);

            RouteInfoData data = new RouteInfoData();
            data.routeId = fareStructure.getRoutesInfoTable().getStringValue("route_id");
            data.mode = fareStructure.getRoutesInfoTable().getStringValue("fare_type");
            data.fare = fareStructure.getRoutesInfoTable().getIntValue("route_fare");

            routeInfo.put(data.routeId, data);
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
        int discountsApplied = 0;

        StringBuilder debugger = new StringBuilder();

        String delimiter = "";
        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);
            RouteInfoData rInfo = routeInfo.get(ri.route_id);

            switch (RuleBasedInRoutingFareCalculator.debugTripInfo) {
                case "MODE":
                    debugger.append(delimiter).append(rInfo.mode);
                    break;
                case "ROUTE":
                    if (ri.route_short_name != null && !ri.route_short_name.equals("null")) {
                        debugger.append(delimiter).append(ri.route_short_name);
                    } else {
                        debugger.append(delimiter).append(ri.route_id);
                    }
                    break;
                case "MODE_ROUTE":
                    if (ri.route_short_name != null && !ri.route_short_name.equals("null")) {
                        debugger.append(delimiter).append(rInfo.mode).append(" ").append(ri.route_short_name);
                    } else {
                        debugger.append(delimiter).append(rInfo.mode).append(" ").append(ri.route_id);
                    }
                    break;
            }

            delimiter = "|";


            // first public transport leg, full ticket price
            if (previousRoute == null) {
                fareForState += getFullFareForRoute(ri);
            } else {
                // get info on each leg
                RouteInfoData firstLegMode = routeInfo.get(previousRoute.route_id);
                RouteInfoData secondLegMode = routeInfo.get(ri.route_id);

                // check if transfer is in same mode with unlimited transfers
                if (firstLegMode.mode.equals(secondLegMode.mode)) {
                    ModeData modeData = farePerMode.get(firstLegMode.mode);

                    // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                    if (modeData.unlimitedTransfers) {
                        previousRoute = ri;
                        continue;
                    }
                }

                // first and second legs modes are different, or there are no unlimited transfer
                // test if discount for subsequent legs is applicable
                if (discountsApplied >= this.fareStructure.getMaxDiscountedTransfers()) {
                    // all discounts have been used. get full fare
                    fareForState += getFullFareForRoute(ri);
                } else {
                    // check for discounted transfer
                    IntegratedFare integratedFare = getIntegrationFare(previousRoute, ri);

                    fareForState += integratedFare.fare;
                    if (integratedFare.usedDiscount) discountsApplied++;
                }
            }

            previousRoute = ri;
        }

        debugger.append(",").append(fareForState);

        if (debugActive) {
            debugOutput.add(debugger.toString());
        }
        //System.out.println(debugger);

        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(RouteInfo ri) {
        RouteInfoData routeInfoData = routeInfo.get(ri.route_id);

        if (routeInfoData != null) {
            ModeData farePerModeData = farePerMode.get(routeInfoData.mode);
            if (farePerModeData != null) {

                if (farePerModeData.useRouteFare) {
                    return routeInfoData.fare;
                } else {
                    return farePerModeData.fare;
                }
            } else {
                return this.fareStructure.getBaseFare();
            }
        } else {
            return this.fareStructure.getBaseFare();
        }
    }

    private IntegratedFare getIntegrationFare(RouteInfo firstRoute, RouteInfo secondRoute) {
        RouteInfoData firstLegMode = routeInfo.get(firstRoute.route_id);
        RouteInfoData secondLegMode = routeInfo.get(secondRoute.route_id);

        if (firstLegMode != null && secondLegMode != null) {
            // same mode, check if transfers between them are allowed
            if (firstLegMode.mode.equals(secondLegMode.mode)) {
                ModeData modeData = farePerMode.get(firstLegMode.mode);

                // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                if (modeData.unlimitedTransfers) return new IntegratedFare(0, false);
            }

            TransferData transferFare = farePerTransfer.get(firstLegMode.mode + "&" + secondLegMode.mode);
            if (transferFare == null) {
                // there is no record in transfers table, return full fare of second route
                int fareSecondLeg = getFullFareForRoute(secondRoute);

                return new IntegratedFare(fareSecondLeg, false);
            } else {
                // discounted transfer found

                // check if transferring between same route ids, and if that is allowed
                ModeData modeData = farePerMode.get(firstLegMode.mode);
                if (firstLegMode.routeId.equals(secondLegMode.routeId) && modeData.allowTransferToSameRoute ) {
                    int fareSecondLeg = getFullFareForRoute(secondRoute);
                    return new IntegratedFare(fareSecondLeg, false);
                } else {
                    int fareFirstLeg = getFullFareForRoute(firstRoute);
                    return new IntegratedFare(transferFare.fare - fareFirstLeg, true);
                }
            }
        } else {
            return new IntegratedFare(this.fareStructure.getBaseFare(), false);
        }
    }

    @Override
    public String getType() {
        return "rule-based";
    }

}
