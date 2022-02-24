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

    private Map<String, FarePerRoute> routeInfo;
    private Map<String, FarePerMode> farePerMode;
    private Map<String, FarePerTransfer> farePerTransfer;
    private Map<String, Integer> fareCache;

    private final Set<String> debugOutput;

    public Set<String> getDebugOutput() {
        return debugOutput;
    }

    public RuleBasedInRoutingFareCalculator(String jsonData) {
        this.fareStructure = FareStructure.fromJson(jsonData);

//        if (debugActive) {
            this.debugOutput = new ConcurrentSkipListSet<>();
//        }

        // fill fare information lookup tables
        loadFarePerMode();
        loadModeOfRoute();
        loadFarePerTransfer();

        // build cache map
        fareCache = new ConcurrentHashMap<>();
    }

    private void loadFarePerMode() {
        this.farePerMode = new HashMap<>();

        for (FarePerMode mode : fareStructure.getFaresPerMode()) {
            farePerMode.put(mode.getMode(), mode);
        }
    }

    private void loadFarePerTransfer() {
        this.farePerTransfer = new HashMap<>();

        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
            String key = transfer.getFirstLeg() + "&" + transfer.getSecondLeg();

            farePerTransfer.put(key, transfer);
        }
    }

    private void loadModeOfRoute() {
        this.routeInfo = new HashMap<>();

        for (FarePerRoute route : fareStructure.getFaresPerRoute()) {
            routeInfo.put(route.getRouteId(), route);
        }
    }

    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        // extract the relevant rides
        TIntList patterns = new TIntArrayList();
        StringBuilder cacheIndex = new StringBuilder();

        while (state != null) {
            if (state.pattern > -1) {
                patterns.add(state.pattern);
                cacheIndex.append(state.pattern).append("|");
            }
            state = state.back;
        }

        Integer cachedFare = fareCache.get(cacheIndex.toString());
        if (cachedFare != null) {
//            cacheCalls.getAndIncrement();
            return new FareBounds(cachedFare, new TransferAllowance());
        }

//        fullFunctionCalls.getAndIncrement();
        // calculate fare
        int fareForState = 0;
        patterns.reverse();

        RouteInfo previousRoute = null;
        int discountsApplied = 0;

//        StringBuilder debugger = new StringBuilder();

//        String delimiter = "";
        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);
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
            if (previousRoute == null) {
                fareForState += getFullFareForRoute(ri);
            } else {
                // get info on each leg
                FarePerRoute firstLegMode = routeInfo.get(previousRoute.route_id);
                FarePerRoute secondLegMode = routeInfo.get(ri.route_id);

                // check if transfer is in same mode with unlimited transfers
                if (firstLegMode.getFareType().equals(secondLegMode.getFareType())) {
                    FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());

                    // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                    if (modeData.isUnlimitedTransfers()) {
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

//        float debugFare = fareForState / 100.0f;
//        debugger.append(",").append(debugFare);

//        if (debugActive) {
//            debugOutput.add(debugger.toString());
//        }
        //System.out.println(debugger);

        fareCache.put(cacheIndex.toString(), fareForState);
        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(RouteInfo ri) {
        FarePerRoute routeInfoData = routeInfo.get(ri.route_id);

        if (routeInfoData != null) {
            FarePerMode farePerModeData = farePerMode.get(routeInfoData.getFareType());
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

    private IntegratedFare getIntegrationFare(RouteInfo firstRoute, RouteInfo secondRoute) {
        FarePerRoute firstLegMode = routeInfo.get(firstRoute.route_id);
        FarePerRoute secondLegMode = routeInfo.get(secondRoute.route_id);

        if (firstLegMode != null && secondLegMode != null) {
            // same mode, check if transfers between them are allowed
            if (firstLegMode.getFareType().equals(secondLegMode.getFareType())) {
                FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());

                // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                if (modeData.isUnlimitedTransfers()) return new IntegratedFare(0, false);
            }

            FarePerTransfer transferFare = farePerTransfer.get(firstLegMode.getFareType() + "&" + secondLegMode.getFareType());
            if (transferFare == null) {
                // there is no record in transfers table, return full fare of second route
                int fareSecondLeg = getFullFareForRoute(secondRoute);

                return new IntegratedFare(fareSecondLeg, false);
            } else {
                // discounted transfer found

                // check if transferring between same route ids, and if that is allowed
                FarePerMode modeData = farePerMode.get(firstLegMode.getFareType());
                if (firstLegMode.getRouteId().equals(secondLegMode.getRouteId()) && modeData.isAllowSameRouteTransfer() ) {
                    int fareSecondLeg = getFullFareForRoute(secondRoute);
                    return new IntegratedFare(fareSecondLeg, false);
                } else {
                    int fareFirstLeg = getFullFareForRoute(firstRoute);
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
