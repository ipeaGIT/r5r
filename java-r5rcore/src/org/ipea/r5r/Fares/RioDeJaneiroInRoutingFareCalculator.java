package org.ipea.r5r.Fares;

import com.conveyal.r5.analyst.fare.FareBounds;
import com.conveyal.r5.analyst.fare.InRoutingFareCalculator;
import com.conveyal.r5.profile.McRaptorSuboptimalPathProfileRouter;

public class RioDeJaneiroInRoutingFareCalculator extends InRoutingFareCalculator {
    @Override
    public FareBounds calculateFare(McRaptorSuboptimalPathProfileRouter.McRaptorState state, int maxClockTime) {
        return null;
    }

    @Override
    public String getType() {
        return "rio-de-janeiro";
    }
}
