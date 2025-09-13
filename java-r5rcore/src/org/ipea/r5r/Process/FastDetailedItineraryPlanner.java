package org.ipea.r5r.Process;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.Planner.Trip;
import org.ipea.r5r.Planner.TripPlanner;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.Utils.Utils;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.List;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.atomic.AtomicInteger;

public class FastDetailedItineraryPlanner extends R5DataFrameProcess {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(FastDetailedItineraryPlanner.class);

    private boolean dropItineraryGeometry = false;
    private boolean shortestPath = false;
    private boolean OSMLinkIds = false;

    private boolean hasFares() {
        return routingProperties.fareCalculator != null;
    }

    @Override
    protected boolean isOneToOne() {
        return true;
    }

    public FastDetailedItineraryPlanner(ForkJoinPool threadPool, RoutingProperties routingProperties) {
        super(threadPool, routingProperties);
    }

    public void dropItineraryGeometry() {
        dropItineraryGeometry = true;
    }
    public void shortestPathOnly() { shortestPath = true; }
    public void OSMLinkIds() { OSMLinkIds = true; }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRegionalTask(index);

        TripPlanner computer = new TripPlanner(transportNetwork, request);
        computer.setOD(fromIds[index], toIds[index]);
        computer.setShortestPath(this.shortestPath);
        computer.setOSMLinkIds(this.OSMLinkIds);
        List<Trip> trips = computer.plan();

        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index], 10);
        try {
            populateDataFrame(trips, travelTimesTable);
        } catch (Exception e) {
            LOG.error("error populating itineraries");
            e.printStackTrace();
        }

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable;
        } else {
            return null;
        }
    }

    @Override
    protected void buildDestinationPointSet() {
        // not needed in this class
    }

    private void populateDataFrame(List<Trip> trips, RDataFrame travelTimesTable) {

        AtomicInteger tripId = new AtomicInteger(0);
        trips.forEach(trip -> {
            travelTimesTable.append();

            travelTimesTable.set("from_id", trip.getFromId());
            travelTimesTable.set("from_lat", trip.getFromLat());
            travelTimesTable.set("from_lon", trip.getFromLon());

            travelTimesTable.set("to_id", trip.getToId());
            travelTimesTable.set("to_lat", trip.getToLat());
            travelTimesTable.set("to_lon", trip.getToLon());

            travelTimesTable.set("option", tripId.incrementAndGet());
            travelTimesTable.set("departure_time", Utils.getTimeFromSeconds(trip.getDepartureTime()));
            travelTimesTable.set("total_duration", Utils.roundTo1Place(trip.getTotalDurationSeconds() / 60.0));
            travelTimesTable.set("total_distance", trip.getTotalDistance());

            if (hasFares())
                travelTimesTable.set("total_fare", trip.getTotalFare() / 100.0);

            AtomicInteger legId = new AtomicInteger(0);
            trip.getLegs().forEach(leg -> {
                if (legId.get() > 0) travelTimesTable.appendRepeat();

                travelTimesTable.set("segment", legId.incrementAndGet());
                travelTimesTable.set("mode", leg.getMode());

                if (hasFares())
                    travelTimesTable.set("cumulative_fare", leg.getCumulativeFare() / 100.0);

                travelTimesTable.set("segment_duration", Utils.roundTo1Place(leg.getLegDurationSeconds() / 60.0));
                travelTimesTable.set("wait", Utils.roundTo1Place(leg.getWaitTime() / 60.0));
                travelTimesTable.set("distance", leg.getLegDistance());
                travelTimesTable.set("route", leg.getRoute());
                if (OSMLinkIds) {
                    travelTimesTable.set("osm_id_list", leg.getListOSMId().toString());
                    travelTimesTable.set("edge_id_list", leg.getListEdgeId().toString());
                    travelTimesTable.set("board_stop_id", leg.getBoardStopId());
                    travelTimesTable.set("alight_stop_id", leg.getAlightStopId());
                }

                if (!dropItineraryGeometry) travelTimesTable.set("geometry", leg.getGeometry().toString());
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
        itinerariesDataFrame.addIntegerColumn("total_distance", 0);

        if (hasFares())
            itinerariesDataFrame.addDoubleColumn("total_fare", 0.0);

        itinerariesDataFrame.addIntegerColumn("segment", 0);
        itinerariesDataFrame.addStringColumn("mode", "");

        if (hasFares())
            itinerariesDataFrame.addDoubleColumn("cumulative_fare", 0.0);

        itinerariesDataFrame.addDoubleColumn("segment_duration", 0.0);
        itinerariesDataFrame.addDoubleColumn("wait", 0.0);
        itinerariesDataFrame.addIntegerColumn("distance", 0);
        itinerariesDataFrame.addStringColumn("route", "");
        if (OSMLinkIds) {
            itinerariesDataFrame.addStringColumn("osm_id_list", "");
            itinerariesDataFrame.addStringColumn("edge_id_list", "");
            itinerariesDataFrame.addStringColumn("board_stop_id", "");
            itinerariesDataFrame.addStringColumn("alight_stop_id", "");
        }
        if (!dropItineraryGeometry) itinerariesDataFrame.addStringColumn("geometry", "");

        return itinerariesDataFrame;
    }

    @Override
    protected RegionalTask buildRegionalTask(int index) throws ParseException {
        RegionalTask request = super.buildRegionalTask(index);

        request.toLat = toLats[index];
        request.toLon = toLons[index];

        request.percentiles = new int[1];
        request.percentiles[0] = 50;

        request.monteCarloDraws = routingProperties.numberOfMonteCarloDraws;

        return request;
    }
}
