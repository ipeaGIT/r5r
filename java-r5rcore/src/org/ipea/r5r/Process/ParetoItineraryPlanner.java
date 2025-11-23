package org.ipea.r5r.Process;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.R5.R5ParetoServer;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;

import java.io.IOException;
import java.text.ParseException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;

public class ParetoItineraryPlanner extends R5DataFrameProcess {

    public static boolean travelAllowanceActive = true;

    @Override
    protected boolean isOneToOne() {
        return true;
    }

    public ParetoItineraryPlanner(ForkJoinPool threadPool, RoutingProperties routingProperties) {
        super(threadPool, routingProperties);
    }

    @Override
    protected void buildDestinationPointSet() {
        // not needed in this class
    }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRegionalTask(index);

        R5ParetoServer computer = new R5ParetoServer(request, transportNetwork);
        R5ParetoServer.ParetoReturn travelTimeResults = computer.handle();

        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index], 10);
        populateDataFrame(index, travelTimeResults, travelTimesTable);

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable;
        } else {
            return null;
        }
    }

    private void populateDataFrame(int index, R5ParetoServer.ParetoReturn travelTimeResults, RDataFrame travelTimesTable) {

        AtomicInteger tripId = new AtomicInteger(0);
        travelTimeResults.trips.forEach(trip -> {
            travelTimesTable.append();
            travelTimesTable.set("to_id", toIds[index]);

            travelTimesTable.set("trip_id", tripId.incrementAndGet());
            travelTimesTable.set("departure_time", Utils.getTimeFromSeconds(trip.departureTime));
            travelTimesTable.set("duration", trip.durationSeconds / 60.0);
            travelTimesTable.set("total_fare", trip.fare / 100.0);

            AtomicInteger legId = new AtomicInteger(0);
            trip.legs.forEach(leg -> {
                if (legId.get() > 0) travelTimesTable.appendRepeat();

                travelTimesTable.set("leg_id", legId.incrementAndGet());
                travelTimesTable.set("leg_type", leg.getType());

                travelTimesTable.set("origin_lat", leg.originLat);
                travelTimesTable.set("origin_lon", leg.originLon);
                travelTimesTable.set("origin_stop_id", leg.originStopId);
                travelTimesTable.set("origin_stop_name", leg.originStopName);
                travelTimesTable.set("origin_time", Utils.getTimeFromSeconds(leg.originTime));

                travelTimesTable.set("destination_lat", leg.destLat);
                travelTimesTable.set("destination_lon", leg.destLon);
                travelTimesTable.set("destination_stop_id", leg.destStopId);
                travelTimesTable.set("destination_stop_name", leg.destStopName);
                travelTimesTable.set("destination_time", Utils.getTimeFromSeconds(leg.destTime));

                travelTimesTable.set("cumulative_fare", leg.cumulativeFare / 100.0);

                if (leg instanceof R5ParetoServer.ParetoTransitLeg) {
                    travelTimesTable.set("agency_id", ((R5ParetoServer.ParetoTransitLeg) leg).route.agency_id);
                    travelTimesTable.set("route_id", ((R5ParetoServer.ParetoTransitLeg) leg).route.route_id);
                    travelTimesTable.set("route_short_name", ((R5ParetoServer.ParetoTransitLeg) leg).route.route_short_name);
                } else {
                    travelTimesTable.set("agency_id", "");
                    travelTimesTable.set("route_id", "");
                    travelTimesTable.set("route_short_name", "");
                }

                travelTimesTable.set("allowance_value", leg.transferAllowance.value / 100.0);
                travelTimesTable.set("allowance_number", leg.transferAllowance.number);
                travelTimesTable.set("allowance_time", Utils.getTimeFromSeconds(leg.transferAllowance.expirationTime));

                travelTimesTable.set("geometry", leg.geom.toString());
            });
        });
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // Build return table
        RDataFrame paretoTable = new RDataFrame(nRows);
        paretoTable.addStringColumn("from_id", fromId);
        paretoTable.addStringColumn("to_id", "");

        paretoTable.addIntegerColumn("trip_id", 0);
        paretoTable.addStringColumn("departure_time", "");
        paretoTable.addDoubleColumn("duration", 0.0);
        paretoTable.addDoubleColumn("total_fare", 0.0);

        paretoTable.addIntegerColumn("leg_id", 0);
        paretoTable.addStringColumn("leg_type", "transit");

        paretoTable.addDoubleColumn("origin_lat", 0.0);
        paretoTable.addDoubleColumn("origin_lon", 0.0);
        paretoTable.addStringColumn("origin_stop_id", "");
        paretoTable.addStringColumn("origin_stop_name", "");
        paretoTable.addStringColumn("origin_time", "");

        paretoTable.addDoubleColumn("destination_lat", 0.0);
        paretoTable.addDoubleColumn("destination_lon", 0.0);
        paretoTable.addStringColumn("destination_stop_id", "");
        paretoTable.addStringColumn("destination_stop_name", "");
        paretoTable.addStringColumn("destination_time", "");

        paretoTable.addDoubleColumn("cumulative_fare", 0.0);

        paretoTable.addStringColumn("agency_id", "");
        paretoTable.addStringColumn("route_id", "");
        paretoTable.addStringColumn("route_short_name", "");

        paretoTable.addDoubleColumn("allowance_value", 0.0);
        paretoTable.addIntegerColumn("allowance_number", 0);
        paretoTable.addStringColumn("allowance_time", "");

        paretoTable.addStringColumn("geometry", "");

        return paretoTable;
    }

    @Override
    protected RegionalTask buildRegionalTask(int index) throws ParseException {
        RegionalTask request = super.buildRegionalTask(index);

        request.toLat = toLats[index];
        request.toLon = toLons[index];

        request.percentiles = new int[1];
        request.percentiles[0] = 50;

        request.suboptimalMinutes = 5;


        return request;
    }
}
