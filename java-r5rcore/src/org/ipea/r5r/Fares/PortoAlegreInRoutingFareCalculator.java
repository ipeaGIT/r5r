package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.BogotaInRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;
import com.conveyal.r5.transit.RouteInfo;
import gnu.trove.iterator.TIntIterator;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;

public class PortoAlegreInRoutingFareCalculator extends InRoutingFareCalculator {

    public int fare = 480;

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

        String previousRouteId = "";
        boolean discountAlreadyApplied = false;
        for (TIntIterator patternIt = patterns.iterator(); patternIt.hasNext();) {
            int pattern = patternIt.next();

            RouteInfo ri = transitLayer.routes.get(transitLayer.tripPatterns.get(pattern).routeIndex);

            if (previousRouteId.equals("") || discountAlreadyApplied) {
                // first public transport leg or discount already applied... full ticket price
                fareForState += fare;
            } else {
                // test if discount for subsequent legs is applicable
                if (previousRouteId.equals(ri.route_id)) {
                    // if same bus, then full price
                    fareForState += fare;
                } else {
                    // if different bus, then half price
                    fareForState += fare / 2;
                    discountAlreadyApplied = true;
                }
            }

            previousRouteId = ri.route_id;
        }

        return new FareBounds(fareForState, new TransferAllowance());
    }

    @Override
    public String getType() {
        return "porto-alegre";
    }
}
