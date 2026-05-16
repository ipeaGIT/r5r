package org.ipea.r5r.Scenario;

import com.conveyal.r5.analyst.scenario.Scenario;

public class DummyScenario extends Scenario {
    @Override
    public boolean affectsStreetLayer() {
        return false;
    }

    @Override
    public boolean affectsTransitLayer() {
        return false;
    }

}
