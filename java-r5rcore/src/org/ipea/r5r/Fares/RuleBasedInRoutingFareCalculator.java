package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TCharArrayList;
import gnu.trove.list.array.TIntArrayList;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.atomic.AtomicInteger;

public class RuleBasedInRoutingFareCalculator extends InRoutingFareCalculator {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RuleBasedInRoutingFareCalculator.class);

    public static AtomicInteger cacheCalls = new AtomicInteger();
    public static AtomicInteger fullFunctionCalls = new AtomicInteger();

    public static String debugFileName = "";
    public static String debugTripInfo = "MODE";
    public static boolean debugActive = false;

    public FareStructure getFareStructure() {
        return fareStructure;
    }

    private final FareStructure fareStructure;

    private FarePerRoute[] routeInfo;
//    private Map<String, FarePerMode> farePerMode;
//    private Map<String, FarePerTransfer> farePerTransfer;
    private FarePerTransfer[][] farePerTransfer;
//    private final Map<String, Integer> fareCache;

    private final Set<String> debugOutput;

    public Set<String> getDebugOutput() {
        return debugOutput;
    }

    public RuleBasedInRoutingFareCalculator(TransitLayer transitLayer, String jsonData) {
        this.transitLayer = transitLayer;
        this.fareStructure = FareStructure.fromJson(jsonData);

//        if (debugActive) {
            this.debugOutput = new ConcurrentSkipListSet<>();
//        }

        // fill fare information lookup tables
//        loadFarePerMode();
        loadModeOfRoute();
//        loadFarePerTransfer();

        // build cache map
//        fareCache = new ConcurrentHashMap<>();
    }

//    private void loadFarePerMode() {
//        this.farePerMode = new ConcurrentHashMap<>();
//
//        for (FarePerMode mode : fareStructure.getFaresPerMode()) {
//            farePerMode.put(mode.getMode(), mode);
//        }
//    }

//    private void loadFarePerTransfer() {
//        this.farePerTransfer = new ConcurrentHashMap<>();
//
//        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
//            String key = transfer.getFirstLeg() + "&" + transfer.getSecondLeg();
//
//            farePerTransfer.put(key, transfer);
//        }
//    }

    private void loadModeOfRoute() {
        // indices of route info
        Map<String, FarePerRoute> tempRouteInfo = new HashMap<>();
        for (FarePerRoute route : fareStructure.getFaresPerRoute()) {
            tempRouteInfo.put(route.getRouteId(), route);
        }
        // indices of modes
        Map<String, Integer> tempModes = new HashMap<>();
        for (int i = 0; i < fareStructure.getFaresPerMode().size(); i++) {
            tempModes.put(fareStructure.getFaresPerMode().get(i).getMode(), i);

        }

        this.routeInfo = new FarePerRoute[transitLayer.tripPatterns.size()];
        for (int i = 0; i < transitLayer.tripPatterns.size(); i++) {
            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(i).routeIndex);

            this.routeInfo[i] = tempRouteInfo.get(ri.route_id);
            int modeIndex = tempModes.get(routeInfo[i].getMode());
            routeInfo[i].setModeIndex(modeIndex);
        }


        int nModes = fareStructure.getFaresPerMode().size();
        this.farePerTransfer = new FarePerTransfer[nModes][nModes];

        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
            int firstModeIndex = tempModes.get(transfer.getFirstLeg());
            int secondModeIndex = tempModes.get(transfer.getSecondLeg());

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
//        StringBuilder cacheIndex = new StringBuilder(32);

        while (state != null) {
            if (state.pattern > -1) {
                patterns.add(state.pattern);
//                cacheIndex.append(state.pattern).append("|");
            }
            state = state.back;
        }

        patterns.reverse();

        // look for pattern in the cache
//        Integer cachedFare = fareCache.get(cacheIndex.toString());
//        if (cachedFare != null) {
//            return new FareBounds(cachedFare, new TransferAllowance());
//        }

        // pattern not in cache... calculate

//        fullFunctionCalls.getAndIncrement();
        int fareForState = 0;

        int previousPatternIndex = -1;
        int discountsApplied = 0;

//        StringBuilder debugger = new StringBuilder();

//        String delimiter = "";
        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

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


            // first public transport leg, full ticket price
            if (previousPatternIndex == -1) {
                fareForState += getFullFareForRoute(pattern);
            } else {
                // get info on each leg
                FarePerRoute firstLegMode = routeInfo[previousPatternIndex];
                FarePerRoute secondLegMode = routeInfo[pattern];

                // check if transfer is in same mode with unlimited transfers
                if (firstLegMode.getFareType().equals(secondLegMode.getFareType())) {
//                    FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());
                    FarePerMode modeData = getModeByIndex(firstLegMode.getModeIndex());

                    // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                    if (modeData.isUnlimitedTransfers()) {
                        previousPatternIndex = pattern;
                        continue;
                    }
                }

                // first and second legs modes are different, or there are no unlimited transfer
                // test if discount for subsequent legs is applicable
                if (discountsApplied >= this.fareStructure.getMaxDiscountedTransfers()) {
                    // all discounts have been used. get full fare
                    fareForState += getFullFareForRoute(pattern);
                } else {
                    // check for discounted transfer
                    IntegratedFare integratedFare = getIntegrationFare(previousPatternIndex, pattern);

                    fareForState += integratedFare.fare;
                    if (integratedFare.usedDiscount) discountsApplied++;
                }
            }

            previousPatternIndex = pattern;
        }

//        float debugFare = fareForState / 100.0f;
//        debugger.append(",").append(debugFare);

//        if (debugActive) {
//            debugOutput.add(debugger.toString());
//        }
        //System.out.println(debugger);

//        fareCache.put(cacheIndex.toString(), fareForState);
        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(int patternIndex) {
        FarePerRoute routeInfoData = routeInfo[patternIndex];

        if (routeInfoData != null) {
//            FarePerMode farePerModeData = farePerMode.get(routeInfoData.getFareType());
            FarePerMode farePerModeData = getModeByIndex(routeInfoData.getModeIndex());
            if (farePerModeData != null) {

                if (farePerModeData.isUseRouteFare()) {
                    return routeInfoData.getIntegerFare();
                } else {
                    return farePerModeData.getIntegerFare();
                }
            } else {
                return this.fareStructure.getIntegerBaseFare();
            }
        } else {
            return this.fareStructure.getIntegerBaseFare();
        }
    }

    private IntegratedFare getIntegrationFare(int firstPattern, int secondPattern) {
        FarePerRoute firstLegMode = routeInfo[firstPattern];
        FarePerRoute secondLegMode = routeInfo[secondPattern];

        if (firstLegMode != null && secondLegMode != null) {
            // same mode, check if transfers between them are allowed
            if (firstLegMode.getModeIndex() == secondLegMode.getModeIndex()) {
//            if (firstLegMode.getFareType().equals(secondLegMode.getFareType())) {
//                FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());
                FarePerMode modeData = getModeByIndex(firstLegMode.getModeIndex());


                // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                if (modeData.isUnlimitedTransfers()) return new IntegratedFare(0, false);
            }

//            FarePerTransfer transferFare = farePerTransfer.get(firstLegMode.getFareType() + "&" + secondLegMode.getFareType());
            FarePerTransfer transferFare = getTransferByIndex(firstLegMode.getModeIndex(), secondLegMode.getModeIndex());
            if (transferFare == null) {
                // there is no record in transfers table, return full fare of second route
                int fareSecondLeg = getFullFareForRoute(secondPattern);

                return new IntegratedFare(fareSecondLeg, false);
            } else {
                // discounted transfer found

                // check if transferring between same route ids, and if that is allowed
//                FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());
                FarePerMode modeData = getModeByIndex(firstLegMode.getModeIndex());
                if (firstLegMode.getRouteId().equals(secondLegMode.getRouteId()) && modeData.isAllowSameRouteTransfer() ) {
                    int fareSecondLeg = getFullFareForRoute(secondPattern);
                    return new IntegratedFare(fareSecondLeg, false);
                } else {
                    int fareFirstLeg = getFullFareForRoute(firstPattern);
                    return new IntegratedFare(transferFare.getIntegerFare() - fareFirstLeg, true);
                }
            }
        } else {
            return new IntegratedFare(this.fareStructure.getIntegerBaseFare(), false);
        }
    }

    @Override
    public String getType() {
        return "rule-based";
    }

}
