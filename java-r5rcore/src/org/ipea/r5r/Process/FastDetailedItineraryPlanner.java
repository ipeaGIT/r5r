package org.ipea.r5r.Process;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.R5.R5ParetoServer;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;

public class FastDetailedItineraryPlanner extends R5Process {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(FastDetailedItineraryPlanner.class);

    private boolean dropItineraryGeometry = false;

    public FastDetailedItineraryPlanner(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    public void dropItineraryGeometry() { dropItineraryGeometry = true; }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        R5ParetoServer computer = new R5ParetoServer(request, transportNetwork);
        R5ParetoServer.ParetoReturn travelTimeResults = computer.handle();

        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index], 10);
        populateDataFrame(index, travelTimeResults, travelTimesTable);

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable;
        } else {
            return null;
        }    }

    @Override
    protected void buildDestinationPointSet() {
        // not needed in this class
    }

    private void populateDataFrame(int index, R5ParetoServer.ParetoReturn travelTimeResults, RDataFrame travelTimesTable) {

        AtomicInteger tripId = new AtomicInteger(0);
        travelTimeResults.trips.forEach(trip -> {
            travelTimesTable.append();

            travelTimesTable.set("from_id", fromIds[index]);
            travelTimesTable.set("from_lat", fromLats[index]);
            travelTimesTable.set("from_lon", fromLons[index]);

            travelTimesTable.set("to_id", toIds[index]);
            travelTimesTable.set("to_lat", toLats[index]);
            travelTimesTable.set("to_lon", toLons[index]);

            travelTimesTable.set("option", tripId.incrementAndGet());
            travelTimesTable.set("departure_time", Utils.getTimeFromSeconds(trip.departureTime));
            travelTimesTable.set("total_duration", trip.durationSeconds / 60.0);
            travelTimesTable.set("total_fare", trip.fare / 100.0);

            AtomicInteger legId = new AtomicInteger(0);
            trip.legs.forEach(leg -> {
                if (legId.get() > 0) travelTimesTable.appendRepeat();

                travelTimesTable.set("segment", legId.incrementAndGet());
                travelTimesTable.set("mode", leg.getType());

                travelTimesTable.set("cumulative_fare", leg.cumulativeFare / 100.0);
                travelTimesTable.set("segment_duration", (leg.destTime - leg.originTime) / 60.0);

                travelTimesTable.set("distance", leg.geom.getLength());

                if (leg instanceof R5ParetoServer.ParetoTransitLeg) {
                    travelTimesTable.set("route", ((R5ParetoServer.ParetoTransitLeg) leg).route.route_id);
                } else {
                    travelTimesTable.set("route", "");
                }


                if (!dropItineraryGeometry) travelTimesTable.set("geometry", leg.geom.toString());
            });
        });
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        RDataFrame itinerariesDataFrame = new RDataFrame(nRows);
        itinerariesDataFrame.addStringColumn("from_id", fromId);
        itinerariesDataFrame.addDoubleColumn("from_lat", 0.0);
        itinerariesDataFrame.addDoubleColumn("from_lon", 0.0);
        itinerariesDataFrame.addStringColumn("to_id", "");
        itinerariesDataFrame.addDoubleColumn("to_lat", 0.0);
        itinerariesDataFrame.addDoubleColumn("to_lon", 0.0);
        itinerariesDataFrame.addIntegerColumn("option", 0);
        itinerariesDataFrame.addStringColumn("departure_time", "");
        itinerariesDataFrame.addDoubleColumn("total_duration", 0.0);
        itinerariesDataFrame.addDoubleColumn("total_fare", 0.0);

        itinerariesDataFrame.addIntegerColumn("segment", 0);
        itinerariesDataFrame.addStringColumn("mode", "");
        itinerariesDataFrame.addDoubleColumn("cumulative_fare", 0.0);
        itinerariesDataFrame.addDoubleColumn("segment_duration", 0.0);
        itinerariesDataFrame.addDoubleColumn("wait", 0.0);
        itinerariesDataFrame.addDoubleColumn("distance", 0.0);
        itinerariesDataFrame.addStringColumn("route", "");
        if (!dropItineraryGeometry) itinerariesDataFrame.addStringColumn("geometry", "");

        return itinerariesDataFrame;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.toLat = toLats[index];
        request.toLon = toLons[index];

        request.percentiles = new int[1];
        request.percentiles[0] = 50;

//        request.timeWindowSize = 1; // minutes
//        request.numberOfMonteCarloDraws = 1; //

        return request;
    }
}
