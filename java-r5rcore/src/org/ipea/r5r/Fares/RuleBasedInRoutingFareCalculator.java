package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.ConcurrentSkipListSet;

public class RuleBasedInRoutingFareCalculator extends InRoutingFareCalculator {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RuleBasedInRoutingFareCalculator.class);

    public static String debugFileName = "";
    public static String debugTripInfo = "MODE";
    public static boolean debugActive = false;

    private final FareStructure fareStructure;

    private FarePerRoute[] routeInfo;
    private FarePerTransfer[][] farePerTransfer;

    private final Set<String> debugOutput;

    public Set<String> getDebugOutput() {
        return debugOutput;
    }

    public FareStructure getFareStructure() {
        return fareStructure;
    }

    public RuleBasedInRoutingFareCalculator(TransitLayer transitLayer, String jsonData) {
        this.transitLayer = transitLayer;
        this.fareStructure = FareStructure.fromJson(jsonData);

//        if (debugActive) {
            this.debugOutput = new ConcurrentSkipListSet<>();
//        }

        // fill fare information lookup tables
        loadFareInformation();
    }

    private void loadFareInformation() {
        // index for route info route_id
        Map<String, FarePerRoute> indexRouteInfo = new HashMap<>();
        for (FarePerRoute route : fareStructure.getFaresPerRoute()) {
            indexRouteInfo.put(route.getRouteId(), route);
        }
        // index for transport modes
        Map<String, Integer> indexTransportMode = new HashMap<>();
        for (int i = 0; i < fareStructure.getFaresPerMode().size(); i++) {
            indexTransportMode.put(fareStructure.getFaresPerMode().get(i).getMode(), i);
        }

        // load route info (fare per route)
        this.routeInfo = new FarePerRoute[transitLayer.tripPatterns.size()];
        for (int i = 0; i < transitLayer.tripPatterns.size(); i++) {
            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(i).routeIndex);

            this.routeInfo[i] = indexRouteInfo.get(ri.route_id);
            int modeIndex = indexTransportMode.get(routeInfo[i].getFareType());
            routeInfo[i].setModeIndex(modeIndex);

            FarePerMode modeOfRoute = fareStructure.getFaresPerMode().get(modeIndex);
            if (!modeOfRoute.isUseRouteFare())
                routeInfo[i].setRouteFare(modeOfRoute.getFare());
        }

        // load fare per transfer as a two-dimensional array
        int nModes = fareStructure.getFaresPerMode().size();
        this.farePerTransfer = new FarePerTransfer[nModes][nModes];

        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
            int firstModeIndex = indexTransportMode.get(transfer.getFirstLeg());
            int secondModeIndex = indexTransportMode.get(transfer.getSecondLeg());

            farePerTransfer[firstModeIndex][secondModeIndex] = transfer;
        }

    }

    private FarePerMode getModeByIndex(int index) {
        return this.fareStructure.getFaresPerMode().get(index);
    }

    private FarePerTransfer getTransferByIndex(int firstModeIndex, int secondModeIndex) {
        return farePerTransfer[firstModeIndex][secondModeIndex];
    }

    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        // extract and order relevant rides
        TIntList patterns = new TIntArrayList();

        while (state != null) {
            if (state.pattern > -1) {
                patterns.add(state.pattern);
            }
            state = state.back;
        }

        patterns.reverse();

        // start calculating fare
        int fareForState = 0;

        int previousPatternIndex = -1;
        int discountsApplied = 0;

        TIntIterator patternIt = patterns.iterator();
        int currentPatternIndex;

        // first leg of multimodal trip
        if (patternIt.hasNext()) {
            currentPatternIndex = patternIt.next();
            fareForState = getFullFareForRoute(currentPatternIndex);
            previousPatternIndex = currentPatternIndex;
        }

        // subsequent legs
        while (patternIt.hasNext()) {
            currentPatternIndex = patternIt.next();

            // get info on each leg
            FarePerRoute firstLegMode = routeInfo[previousPatternIndex];
            FarePerRoute secondLegMode = routeInfo[currentPatternIndex];

            // check if transfer is in same mode with unlimited transfers
            if (firstLegMode.getModeIndex() == secondLegMode.getModeIndex()) {
                FarePerMode modeData = getModeByIndex(firstLegMode.getModeIndex());

                // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                if (modeData.isUnlimitedTransfers()) {
                    previousPatternIndex = currentPatternIndex;
                    continue;
                }
            }

            // first and second legs modes are different, or there are no unlimited transfer
            // test if discount for subsequent legs is applicable
            if (discountsApplied >= this.fareStructure.getMaxDiscountedTransfers()) {
                // all discounts have been used. get full fare
                fareForState += getFullFareForRoute(currentPatternIndex);
            } else {
                // check for discounted transfer
                IntegratedFare integratedFare = getIntegrationFare(previousPatternIndex, currentPatternIndex);

                fareForState += integratedFare.fare;
                if (integratedFare.usedDiscount) discountsApplied++;
            }

            previousPatternIndex = currentPatternIndex;
        }

        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(int patternIndex) {
        FarePerRoute routeInfoData = routeInfo[patternIndex];

        if (routeInfoData != null) {
            return routeInfoData.getIntegerFare();
        } else {
            return this.fareStructure.getIntegerBaseFare();
        }
    }

    private IntegratedFare getIntegrationFare(int firstPattern, int secondPattern) {
        FarePerRoute firstLegMode = routeInfo[firstPattern];
        FarePerRoute secondLegMode = routeInfo[secondPattern];

        FarePerTransfer transferFare = getTransferByIndex(firstLegMode.getModeIndex(), secondLegMode.getModeIndex());
        if (transferFare == null) {
            // there is no record in transfers table, return full fare of second route
            int fareSecondLeg = getFullFareForRoute(secondPattern);

            return new IntegratedFare(fareSecondLeg, false);
        } else {
            // discounted transfer found
            if (isTransferAllowed(firstLegMode, secondLegMode)) {
                // transfer is allowed, so discount the fare already considered in first leg
                int fareFirstLeg = getFullFareForRoute(firstPattern);
                return new IntegratedFare(transferFare.getIntegerFare() - fareFirstLeg, true);
            } else {
                // transfer is not allowed, so return full fare for second leg
                int fareSecondLeg = getFullFareForRoute(secondPattern);
                return new IntegratedFare(fareSecondLeg, false);
            }
        }
    }

    private boolean isTransferAllowed(FarePerRoute firstLeg, FarePerRoute secondLeg) {
        // if transfer is between routes in the same mode, the condition 'allow-same-route-transfer' also applies
        if (firstLeg.getModeIndex() == secondLeg.getModeIndex()) {
            // if mode allows transfers between same route, return true
            FarePerMode modeData = getModeByIndex(firstLeg.getModeIndex());
            if (modeData.isAllowSameRouteTransfer()) return true;

            // if transfers between same route are not allowed, then check if route id's are different
            return !firstLeg.getRouteId().equals(secondLeg.getRouteId());
        } else {
            // transfer is between routes in different modes, so transfer is allowed
            return true;
        }
    }

    @Override
    public String getType() {
        return "rule-based";
    }

}

//            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);
//            FarePerRoute rInfo = routeInfo.get(ri.route_id);

//            switch (RuleBasedInRoutingFareCalculator.debugTripInfo) {
//                case "MODE":
//                    debugger.append(delimiter).append(rInfo.getFareType());
//                    break;
//                case "ROUTE":
//                    if (ri.route_short_name != null && !ri.route_short_name.equals("null")) {
//                        debugger.append(delimiter).append(ri.route_short_name);
//                    } else {
//                        debugger.append(delimiter).append(ri.route_id);
//                    }
//                    break;
//                case "MODE_ROUTE":
//                    if (ri.route_short_name != null && !ri.route_short_name.equals("null")) {
//                        debugger.append(delimiter).append(rInfo.getFareType()).append(" ").append(ri.route_short_name);
//                    } else {
//                        debugger.append(delimiter).append(rInfo.getFareType()).append(" ").append(ri.route_id);
//                    }
//                    break;
//            }
//
//            delimiter = "|";

//        float debugFare = fareForState / 100.0f;
//        debugger.append(",").append(debugFare);

//        if (debugActive) {
//            debugOutput.add(debugger.toString());
//        }
//System.out.println(debugger);