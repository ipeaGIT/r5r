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

    private FarePerRoute[] faresPerRoute;
    private FarePerTransfer[][] faresPerTransfer;

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

        this.debugOutput = new ConcurrentSkipListSet<>();

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
        this.faresPerRoute = new FarePerRoute[transitLayer.tripPatterns.size()];
        for (int i = 0; i < transitLayer.tripPatterns.size(); i++) {
            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(i).routeIndex);

            this.faresPerRoute[i] = indexRouteInfo.get(ri.route_id);
            int modeIndex = indexTransportMode.get(faresPerRoute[i].getFareType());
            faresPerRoute[i].setModeIndex(modeIndex);

            FarePerMode modeOfRoute = fareStructure.getFaresPerMode().get(modeIndex);
            if (!modeOfRoute.isUseRouteFare())
                faresPerRoute[i].setRouteFare(modeOfRoute.getFare());
        }

        // load fare per transfer as a two-dimensional array
        int nModes = fareStructure.getFaresPerMode().size();
        this.faresPerTransfer = new FarePerTransfer[nModes][nModes];

        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
            int firstModeIndex = indexTransportMode.get(transfer.getFirstLeg());
            int secondModeIndex = indexTransportMode.get(transfer.getSecondLeg());

            faresPerTransfer[firstModeIndex][secondModeIndex] = transfer;
        }

    }

    private FarePerMode getModeByIndex(int index) {
        return this.fareStructure.getFaresPerMode().get(index);
    }

    private FarePerTransfer getTransferByIndex(int firstModeIndex, int secondModeIndex) {
        return faresPerTransfer[firstModeIndex][secondModeIndex];
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
            FarePerRoute firstLegMode = faresPerRoute[previousPatternIndex];
            FarePerRoute secondLegMode = faresPerRoute[currentPatternIndex];

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

        if (debugActive) {
            String tripPattern = buildDebugInformation(patterns);
            float debugFare = fareForState / 100.0f;
            debugOutput.add(tripPattern + "," + debugFare);
        }

        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(int patternIndex) {
        FarePerRoute routeInfoData = faresPerRoute[patternIndex];

        if (routeInfoData != null) {
            return routeInfoData.getIntegerFare();
        } else {
            return this.fareStructure.getIntegerBaseFare();
        }
    }

    private IntegratedFare getIntegrationFare(int firstPattern, int secondPattern) {
        FarePerRoute firstLegMode = faresPerRoute[firstPattern];
        FarePerRoute secondLegMode = faresPerRoute[secondPattern];

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

    private String buildDebugInformation(TIntList patterns) {
        StringBuilder debugger = new StringBuilder();
        String delimiter = "";

        TIntIterator patternIt = patterns.iterator();
        while (patternIt.hasNext()) {
            int currentPatternIndex = patternIt.next();
            FarePerRoute secondLegMode = faresPerRoute[currentPatternIndex];

            switch (RuleBasedInRoutingFareCalculator.debugTripInfo) {
                case "MODE":
                    debugger.append(delimiter).append(secondLegMode.getFareType());
                    break;
                case "ROUTE":
                    if (secondLegMode.getRouteShortName() != null && !secondLegMode.getRouteShortName().equals("null")) {
                        debugger.append(delimiter).append(secondLegMode.getRouteShortName());
                    } else {
                        debugger.append(delimiter).append(secondLegMode.getRouteId());
                    }
                    break;
                case "MODE_ROUTE":
                    if (secondLegMode.getRouteShortName() != null && !secondLegMode.getRouteShortName().equals("null")) {
                        debugger.append(delimiter).append(secondLegMode.getFareType()).append(" ").append(secondLegMode.getRouteShortName());
                    } else {
                        debugger.append(delimiter).append(secondLegMode.getFareType()).append(" ").append(secondLegMode.getRouteId());
                    }
                    break;
            }

            delimiter = "|";
        }

        return debugger.toString();
    }

    @Override
    public String getType() {
        return "rule-based";
    }

}

