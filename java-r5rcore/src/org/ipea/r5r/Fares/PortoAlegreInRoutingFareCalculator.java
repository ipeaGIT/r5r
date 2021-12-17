package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;

public class PortoAlegreInRoutingFareCalculator extends InRoutingFareCalculator {

    public static int fareEptcFull = 480;
    public static int getFareEptcDiscount = 240;
    public static int fareTrensurb = 450;
    public static int fareTrainAfterBus = 837 - fareEptcFull;
    public static int fareBusAfterTrain = 837 - fareTrensurb;

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

        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);

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

        return new FareBounds(fareForState, new TransferAllowance());
    }

    private int getFullFareForRoute(RouteInfo ri) {
        if (ri.agency_id.equals("TRENS")) {
            return fareTrensurb;
        } else {
            return fareEptcFull;
        }
    }

    private IntegratedFare getIntegrationFare(RouteInfo firstRoute, RouteInfo secondRoute) {
        String firstAgency = firstRoute.agency_id;
        String secondAgency = secondRoute.agency_id;

        // transfers between metro services and aeromovel are free
        if (firstAgency.equals("TRENS") && secondAgency.equals("TRENS")) {
            return new IntegratedFare(0, false);
        }

        // metro and train transfers have a small discount
        if ( firstAgency.equals("TRENS") && secondAgency.equals("EPTC") ) {
            return new IntegratedFare(fareBusAfterTrain, true); // total 837, first leg has cost 450
        }

        if ( firstAgency.equals("EPTC") && secondAgency.equals("TRENS")) {
            return new IntegratedFare(fareTrainAfterBus, true); // total 837, first leg has cost 480
        }

        // transfer between bus services (EPTC -> EPTC)
        if (firstRoute.route_id.equals(secondRoute.route_id)) {
            // transfers between buses in the same route have full price
            return new IntegratedFare(fareEptcFull, false);
        } else {
            // transfers between buses in different routes have a 50% discount
            return new IntegratedFare(getFareEptcDiscount, true);
        }
    }

    @Override
    public String getType() {
        return "porto-alegre";
    }
}

