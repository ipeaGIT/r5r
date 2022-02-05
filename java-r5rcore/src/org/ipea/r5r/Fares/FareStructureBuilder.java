package org.ipea.r5r.Fares;

import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.RDataFrame;

import java.util.HashSet;
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

    public FareStructure build(int baseFare, String routeType) {
        this.fareStructure = new FareStructure(baseFare);

        populateFareStructure(routeType);

        return this.fareStructure;
    }

    private void populateFareStructure(String type) {
        Set<String> modes = new HashSet<>();
        Set<String> transfers = new HashSet<>();

        RDataFrame routes = this.fareStructure.getRoutesInfoTable();
        for (RouteInfo route : transportNetwork.transitLayer.routes) {

            routes.append();
            routes.set("agency_id", route.agency_id);
            routes.set("agency_name", route.agency_name);
            routes.set("route_id", route.route_id);
            routes.set("route_short_name", route.route_short_name);
            routes.set("route_long_name", route.route_long_name);
            routes.set("mode", TransitLayer.getTransitModes(route.route_type).toString());

            switch (type) {
                case "MODE":
                    routes.set("fare_type", TransitLayer.getTransitModes(route.route_type).toString());
                    modes.add(TransitLayer.getTransitModes(route.route_type).toString());
                    break;
                case "AGENCY":
                case "AGENCY_ID":
                    routes.set("fare_type", route.agency_id);
                    modes.add(route.agency_id);
                    break;
                case "AGENCY_NAME":
                    routes.set("fare_type", route.agency_name);
                    modes.add(route.agency_name);
                    break;
                default:
                    routes.set("fare_type", "GENERIC");
                    modes.add("GENERIC");
                    break;
            }
        }

        for (String modeLeg1 : modes) {
            for (String modeLeg2 : modes) {
                String legs = modeLeg1 + "&" + modeLeg2;
                transfers.add(legs);
            }
        }

        RDataFrame farePerModeTable = this.fareStructure.getFarePerModeTable();
        for (String mode : modes) {
            farePerModeTable.append();
            farePerModeTable.set("mode", mode);
        }

        RDataFrame farePerTransferTable = this.fareStructure.getFarePerTransferTable();
        for (String transfer : transfers) {
            String[] legs = transfer.split("&");
            farePerTransferTable.append();
            farePerTransferTable.set("leg1", legs[0]);
            farePerTransferTable.set("leg2", legs[1]);
        }

    }

}
