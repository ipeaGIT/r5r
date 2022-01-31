package org.ipea.r5r.Fares;

import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;

public class FareStructureBuilder {

    private final TransportNetwork transportNetwork;

    public FareStructure getFareStructure() {
        return fareStructure;
    }

    private FareStructure fareStructure;

    public FareStructureBuilder(TransportNetwork transportNetwork) {
        this.transportNetwork = transportNetwork;

        populateFareStructure();
    }

    private void populateFareStructure() {
        this.fareStructure = new FareStructure();

        for (TripPattern pattern : transportNetwork.transitLayer.tripPatterns) {
            RouteInfo route = transportNetwork.transitLayer.routes.get(pattern.routeIndex);

            this.fareStructure.getModeOfRoute().put(
                    route.route_id,
                    TransitLayer.getTransitModes(route.route_type).toString()
            );

            this.fareStructure.getFarePerMode().put(
                    TransitLayer.getTransitModes(route.route_type).toString(),
                    this.fareStructure.getBaseFare()
            );
        }

        for (String modeLeg1 : this.fareStructure.getFarePerMode().keySet()) {
            for (String modeLeg2 : this.fareStructure.getFarePerMode().keySet()) {
                String legs = modeLeg1 + "&" + modeLeg2;
                this.fareStructure.getFarePerTransfer().put(
                        legs,
                        this.fareStructure.getBaseFare()
                );
            }
        }

    }

}
