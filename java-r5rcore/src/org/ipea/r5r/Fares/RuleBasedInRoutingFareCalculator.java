package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
import org.ipea.r5r.Process.ParetoItineraryPlanner;
import org.slf4j.LoggerFactory;

import java.util.*;

public class RuleBasedInRoutingFareCalculator extends InRoutingFareCalculator {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(RuleBasedInRoutingFareCalculator.class);

    private final FareStructure fareStructure;

    private FarePerRoute[] faresPerRoute;
    private FarePerTransfer[][] faresPerTransfer;

    public FareStructure getFareStructure() {
        return fareStructure;
    }

    public RuleBasedInRoutingFareCalculator(TransitLayer transitLayer, String jsonData) {
        this.transitLayer = transitLayer;
        this.fareStructure = FareStructure.fromJson(jsonData);

        // fill fare information lookup tables
        loadFareInformation();
    }

    private void loadFareInformation() {
        // index for route info route_id
        Map<String, FarePerRoute> indexRouteInfo = new HashMap<>();
        for (FarePerRoute route : fareStructure.getFaresPerRoute()) {
            indexRouteInfo.put(route.getUniqueId(), route);
        }
        // index for transport types
        Map<String, Integer> indexTransportType = new HashMap<>();
        for (int i = 0; i < fareStructure.getFaresPerType().size(); i++) {
            indexTransportType.put(fareStructure.getFaresPerType().get(i).getType(), i);
        }

        // load route info (fare per route)
        this.faresPerRoute = new FarePerRoute[transitLayer.tripPatterns.size()];
        for (int i = 0; i < transitLayer.tripPatterns.size(); i++) {
            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(i).routeIndex);

            this.faresPerRoute[i] = indexRouteInfo.get(FarePerRoute.getUniqueId(ri));
            int typeIndex = indexTransportType.get(faresPerRoute[i].getFareType());
            faresPerRoute[i].setTypeIndex(typeIndex);

            FarePerType typeOfRoute = fareStructure.getFaresPerType().get(typeIndex);
            if (!typeOfRoute.isUseRouteFare())
                faresPerRoute[i].setRouteFare(typeOfRoute.getFare());
        }

        // load fare per transfer as a two-dimensional array
        int nTypes = fareStructure.getFaresPerType().size();
        this.faresPerTransfer = new FarePerTransfer[nTypes][nTypes];

        for (FarePerTransfer transfer : fareStructure.getFaresPerTransfer()) {
            int firstTypeIndex = indexTransportType.get(transfer.getFirstLeg());
            int secondTypeIndex = indexTransportType.get(transfer.getSecondLeg());

            transfer.setFirstLegFullIntegerFare(fareStructure.getFaresPerType().get(firstTypeIndex).getIntegerFare());
            transfer.setSecondLegFullIntegerFare(fareStructure.getFaresPerType().get(secondTypeIndex).getIntegerFare());

            faresPerTransfer[firstTypeIndex][secondTypeIndex] = transfer;
        }

    }

    private FarePerType getTypeByIndex(int index) {
        return this.fareStructure.getFaresPerType().get(index);
    }

    private FarePerTransfer getTransferByIndex(int firstTypeIndex, int secondTypeIndex) {
        return faresPerTransfer[firstTypeIndex][secondTypeIndex];
    }

    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        // extract and order relevant rides
        TIntList patterns = new TIntArrayList();
        TIntList boardTimes = new TIntArrayList();

        while (state != null) {
            if (state.pattern > -1) {
                patterns.add(state.pattern);
                boardTimes.add(state.boardTime);
            }
            state = state.back;
        }

        patterns.reverse();
        boardTimes.reverse();

        // start calculating fare
        int fareForState = 0;

        int previousPatternIndex = -1;
        int discountsApplied = 0;
        int previousBoardTime = 0;

        int currentPatternIndex = -1;
        int currentBoardTime = -1;
        int lastFareType = -1;

        // first leg of multimodal trip
        if (!patterns.isEmpty()) {
            currentPatternIndex = patterns.get(0);
            previousBoardTime = boardTimes.get(0);

            fareForState = getFullFareForRoute(currentPatternIndex);

            previousPatternIndex = currentPatternIndex;
            lastFareType = faresPerRoute[currentPatternIndex].getTypeIndex();
        }

        // subsequent legs
        for (int ride = 1; ride < patterns.size(); ride ++) {
            currentPatternIndex = patterns.get(ride);
            currentBoardTime = boardTimes.get(ride);

            // get info on each leg
            FarePerRoute firstLegType = faresPerRoute[previousPatternIndex];
            FarePerRoute secondLegType = faresPerRoute[currentPatternIndex];
            lastFareType = secondLegType.getTypeIndex();

            // check if transfer is in same type with unlimited transfers
            if (firstLegType.getTypeIndex() == secondLegType.getTypeIndex()) {
                FarePerType typeData = getTypeByIndex(firstLegType.getTypeIndex());

                // unlimited transfers mean the fare is $ 0.00, and transfer allowance is not spent
                if (typeData.isUnlimitedTransfers()) {
                    previousPatternIndex = currentPatternIndex;
                    continue;
                }
            }

            // first and second legs types are different, or there are no unlimited transfer
            // test if discount for subsequent legs is applicable
            if (discountsApplied >= this.fareStructure.getMaxDiscountedTransfers()) {
                // all discounts have been used. get full fare
                fareForState += getFullFareForRoute(currentPatternIndex);
            } else {
                // check for discounted transfer
                IntegratedFare integratedFare = getIntegrationFare(previousPatternIndex, currentPatternIndex, currentBoardTime - previousBoardTime);

                fareForState += integratedFare.fare;
                if (integratedFare.usedDiscount) discountsApplied++;
            }

            previousPatternIndex = currentPatternIndex;
            previousBoardTime = currentBoardTime;
        }

        // fares are limited by the maxFare parameter
        if (fareStructure.getFareCap() > 0) {
            fareForState = Math.min(fareForState, fareStructure.getIntegerFareCap());
        }

        // initialize transfer allowance
        // if (discountsApplied >= this.fareStructure.getMaxDiscountedTransfers()) -> NO TRANSFER ALLOWANCE
        // if (currentBoardTime - previousBoardTime) > fareStructure.getTransferTimeAllowanceSeconds() -> NO TRANSFER ALLOWANCE
        // if (fareForState >= fareStructure.getIntegerFareCap()) -> MAX TRANSFER ALLOWANCE

        // if transfer allowances are inactive (for debugging purposes), just use and empty transfer allowance and
        // quit the function
        if (!ParetoItineraryPlanner.travelAllowanceActive) {
            return new FareBounds(fareForState, new R5RTransferAllowance());
        }

        // pattern is valid?
        if (currentPatternIndex == -1) {
            // no public transport patterns - return empty transfer allowance
            return new FareBounds(fareForState, new R5RTransferAllowance());
        }

        // remaining transfers
        int numberOfRemainingTransfers = fareStructure.getMaxDiscountedTransfers() - discountsApplied;
        if (numberOfRemainingTransfers <= 0) {
            // no remaining available transfers - return empty transfer allowance
            return new FareBounds(fareForState, new R5RTransferAllowance());
        }

        // get max benefit from possible transfers
        int fullFare = getFullFareForRoute(currentPatternIndex);
        int maxAllowanceValue = 0;
        for (FarePerTransfer transfer : faresPerTransfer[faresPerRoute[currentPatternIndex].getTypeIndex()]) {
            if (transfer != null) {
                int fullTransferFare = transfer.getFirstLegFullIntegerFare() + transfer.getSecondLegFullIntegerFare();

                int allowance = fullTransferFare - transfer.getIntegerFare();
                maxAllowanceValue = Math.max(allowance, maxAllowanceValue);
            }
        }

        // if fare cap has been reached, the max remaining allowance may be the type's full fare
        if (fareStructure.getFareCap() > 0 && fareForState > fareStructure.getIntegerFareCap() ) {
            maxAllowanceValue = Math.max(fullFare, maxAllowanceValue);
        }

        // remaining time available to use discount
        int expirationTime = currentBoardTime + fareStructure.getTransferTimeAllowanceSeconds();

        // build transfer allowance considering constraints above
        R5RTransferAllowance transferAllowance = new R5RTransferAllowance(lastFareType, maxAllowanceValue, numberOfRemainingTransfers, expirationTime);
        return new FareBounds(fareForState, transferAllowance);

    }

    private int getFullFareForRoute(int patternIndex) {
        FarePerRoute routeInfoData = faresPerRoute[patternIndex];

        return routeInfoData.getIntegerFare();
    }

    private IntegratedFare getIntegrationFare(int firstPattern, int secondPattern, int transferTime) {
        FarePerRoute firstLeg = faresPerRoute[firstPattern];
        FarePerRoute secondLeg = faresPerRoute[secondPattern];

        FarePerTransfer transferFare = getTransferByIndex(firstLeg.getTypeIndex(), secondLeg.getTypeIndex());
        if (transferFare == null) {
            // there is no record in transfers table, return full fare of second route
            int fareSecondLeg = getFullFareForRoute(secondPattern);
            return new IntegratedFare(fareSecondLeg, false);
        }

        // discounted transfer found
        // check if transfer is allowed (transfer between same route ids)
        if (!isTransferAllowed(firstLeg, secondLeg)) {
            // transfer is not allowed, so return full fare for second leg
            int fareSecondLeg = getFullFareForRoute(secondPattern);
            return new IntegratedFare(fareSecondLeg, false);
        }

        // transfer is allowed
        // check if transfer time is within limits
        if (transferTime > this.fareStructure.getTransferTimeAllowanceSeconds()) {
            // transfer time expired, return full fare for second leg
            int fareSecondLeg = getFullFareForRoute(secondPattern);
            return new IntegratedFare(fareSecondLeg, false);
        }

        // all restrictions clear: transfer is allowed
        // discount the fare already considered in first leg
        int fareFirstLeg = getFullFareForRoute(firstPattern);
        return new IntegratedFare(transferFare.getIntegerFare() - fareFirstLeg, true);
    }

    private boolean isTransferAllowed(FarePerRoute firstLeg, FarePerRoute secondLeg) {
        // if transfer is between routes in the same type, the condition 'allow-same-route-transfer' also applies
        if (firstLeg.getTypeIndex() == secondLeg.getTypeIndex()) {
            // if type allows transfers between same route, return true
            FarePerType typeData = getTypeByIndex(firstLeg.getTypeIndex());
            if (typeData.isAllowSameRouteTransfer()) return true;

            // if transfers between same route are not allowed, then check if route ids are different
            return !firstLeg.getRouteId().equals(secondLeg.getRouteId());
        } else {
            // transfer is between routes in different types, so transfer is allowed
            return true;
        }
    }

    @Override
    public String getType() {
        return "rule-based";
    }

}

