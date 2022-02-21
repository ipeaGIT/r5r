package org.ipea.r5r.Fares;

import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class FareStructureBuilder {

    private final TransportNetwork transportNetwork;

    private FareStructure fareStructure;
    public FareStructure getFareStructure() {
        return fareStructure;
    }

    public FareStructureBuilder(TransportNetwork transportNetwork) {
        this.transportNetwork = transportNetwork;
    }

    public FareStructure build(float baseFare, String routeType) {
        this.fareStructure = new FareStructure(baseFare);

        populateFareStructure(routeType);

        return this.fareStructure;
    }

    private void populateFareStructure(String type) {
        Set<String> modes = new HashSet<>();
        Set<String> transfers = new HashSet<>();

        List<FarePerRoute> routes = this.fareStructure.getFaresPerRoute();
        for (RouteInfo route : transportNetwork.transitLayer.routes) {

            FarePerRoute newRoute = new FarePerRoute();

            newRoute.setAgencyId(route.agency_id);
            newRoute.setAgencyName(route.agency_name);
            newRoute.setRouteId(route.route_id);
            newRoute.setRouteShortName(route.route_short_name);
            newRoute.setRouteLongName(route.route_long_name);
            newRoute.setMode(TransitLayer.getTransitModes(route.route_type).toString());
            newRoute.setRouteFare(this.fareStructure.getBaseFare());

            switch (type) {
                case "MODE":
                    newRoute.setFareType(TransitLayer.getTransitModes(route.route_type).toString());
                    modes.add(TransitLayer.getTransitModes(route.route_type).toString());
                    break;
                case "AGENCY":
                case "AGENCY_ID":
                    newRoute.setFareType(route.agency_id);
                    modes.add(route.agency_id);
                    break;
                case "AGENCY_NAME":
                    newRoute.setFareType(route.agency_name);
                    modes.add(route.agency_name);
                    break;
                default:
                    newRoute.setFareType("GENERIC");
                    modes.add("GENERIC");
                    break;
            }

            routes.add(newRoute);
        }

        for (String modeLeg1 : modes) {
            for (String modeLeg2 : modes) {
                String legs = modeLeg1 + "&" + modeLeg2;
                transfers.add(legs);
            }
        }

        List<FarePerMode> faresPerMode = this.fareStructure.getFaresPerMode();
        for (String mode : modes) {
            FarePerMode newMode = new FarePerMode();
            newMode.setMode(mode);
            newMode.setFare(this.fareStructure.getBaseFare());

            faresPerMode.add(newMode);
        }

        List<FarePerTransfer> faresPerTransfer = this.fareStructure.getFaresPerTransfer();
        for (String transfer : transfers) {
            String[] legs = transfer.split("&");

            FarePerTransfer newTransfer = new FarePerTransfer();
            newTransfer.setFirstLeg(legs[0]);
            newTransfer.setSecondLeg(legs[1]);
            newTransfer.setFare(this.fareStructure.getBaseFare());

            faresPerTransfer.add(newTransfer);
        }
    }

}
