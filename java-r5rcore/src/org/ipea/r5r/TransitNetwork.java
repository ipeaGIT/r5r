package org.ipea.r5r;

import com.conveyal.r5.transit.RouteInfo;
import com.conveyal.r5.transit.TransitLayer;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import org.locationtech.jts.geom.Coordinate;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class TransitNetwork {

    public RDataFrame routesTable;
    public RDataFrame stopsTable;

    public TransitNetwork(TransportNetwork transportNetwork) {
        // Build transit network

        buildRoutesTable(transportNetwork);
        buildStopsTable(transportNetwork);
    }

    private void buildStopsTable(TransportNetwork transportNetwork) {
        // stops
        stopsTable = new RDataFrame();
        stopsTable.addIntegerColumn("stop_index", -1);
        stopsTable.addStringColumn("stop_id", "");
        stopsTable.addStringColumn("stop_name", "");
        stopsTable.addDoubleColumn("lat", -1.0);
        stopsTable.addDoubleColumn("lon", -1.0);
        stopsTable.addBooleanColumn("linked_to_street", false);

//        LOG.info("Getting public transport stops from Transport Network");
//        LOG.info("{} stops were found in the network", transportNetwork.transitLayer.getStopCount());

        for (int stopIndex = 0; stopIndex < transportNetwork.transitLayer.getStopCount(); stopIndex++) {
//            LOG.info("Stop #{}", stopIndex);
//            LOG.info("Stop id: {}", transportNetwork.transitLayer.stopIdForIndex.get(stopIndex));

            stopsTable.append();
            stopsTable.set("stop_index", stopIndex);
            stopsTable.set("stop_id", transportNetwork.transitLayer.stopIdForIndex.get(stopIndex));

            if (transportNetwork.transitLayer.stopNames != null) {
//                LOG.info("Stop name: {}", transportNetwork.transitLayer.stopNames.get(stopIndex));
                stopsTable.set("stop_name", transportNetwork.transitLayer.stopNames.get(stopIndex));
            }

            Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIndex);
            if (coordinate != null) {
                Double lat = coordinate.y / FIXED_FACTOR;
                Double lon = coordinate.x / FIXED_FACTOR;
                stopsTable.set("lat", lat);
                stopsTable.set("lon", lon);
            }

            boolean linkedToStreet = (transportNetwork.transitLayer.streetVertexForStop.get(stopIndex) != -1);
            stopsTable.set("linked_to_street", linkedToStreet);
        }
    }

    private void buildRoutesTable(TransportNetwork transportNetwork) {
        // routes and shape geometries
        routesTable = new RDataFrame();
        routesTable.addStringColumn("agency_id", "");
        routesTable.addStringColumn("agency_name", "");
        routesTable.addStringColumn("route_id", "");
        routesTable.addStringColumn("long_name", "");
        routesTable.addStringColumn("short_name", "");
        routesTable.addStringColumn("mode", "");
        routesTable.addStringColumn("geometry", "");

        for (TripPattern pattern : transportNetwork.transitLayer.tripPatterns) {
            RouteInfo route = transportNetwork.transitLayer.routes.get(pattern.routeIndex);

            routesTable.append();
            routesTable.set("agency_id", route.agency_id);
            routesTable.set("agency_name", route.agency_name);
            routesTable.set("route_id", route.route_id);
            routesTable.set("long_name", route.route_long_name);
            routesTable.set("short_name", route.route_short_name);
            routesTable.set("mode", TransitLayer.getTransitModes(route.route_type).toString());

            if (pattern.shape != null) {
                routesTable.set("geometry", pattern.shape.toString());
            } else {
                // build geometry from stops
                StringBuilder geometry = new StringBuilder();
                for (int stopIndex : pattern.stops) {
                    Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIndex);

                    if (coordinate != null) {
                        coordinate.x = coordinate.x / FIXED_FACTOR;
                        coordinate.y = coordinate.y / FIXED_FACTOR;

                        if (geometry.toString().equals("")) {
                            geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                        } else {
                            geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                        }
                    }
                }
                if (!geometry.toString().equals("")) {
                    geometry.append(")");
                }
                routesTable.set("geometry", geometry.toString());
            }
        }
    }
}
