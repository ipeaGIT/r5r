package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.analyst.fare.TransferAllowance;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;

public class PortoAlegreInRoutingFareCalculator extends InRoutingFareCalculator {

    public int fare = 480;

    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        int fareForState = 0;

        while (state != null) {
            if (state.pattern != -1) fareForState += fare;
            state = state.back;
        }

        return new FareBounds(fareForState, new TransferAllowance());
    }

    @Override
    public String getType() {
        return "porto-alegre";
    }
}
