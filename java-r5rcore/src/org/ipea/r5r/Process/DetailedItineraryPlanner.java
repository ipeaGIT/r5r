package org.ipea.r5r.Process;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.transit.TransportNetwork;
import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.concurrent.ForkJoinPool;

public class DetailedItineraryPlanner extends R5Process {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(DetailedItineraryPlanner.class);

    private boolean dropItineraryGeometry = false;
    public void dropItineraryGeometry() { dropItineraryGeometry = true; }

    public DetailedItineraryPlanner(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);

        routingProperties.timeWindowSize = 1; // minutes
        routingProperties.numberOfMonteCarloDraws = 1; //
    }

    @Override
    protected void buildDestinationPointSet() {
        // not needed in this class
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
        itinerariesDataFrame.addIntegerColumn("segment", 0);
        itinerariesDataFrame.addStringColumn("mode", "");
        itinerariesDataFrame.addDoubleColumn("total_duration", 0.0);
        itinerariesDataFrame.addDoubleColumn("segment_duration", 0.0);
        itinerariesDataFrame.addDoubleColumn("wait", 0.0);
        itinerariesDataFrame.addIntegerColumn("distance", 0);
        itinerariesDataFrame.addStringColumn("route", "");
        if (!dropItineraryGeometry) itinerariesDataFrame.addStringColumn("geometry", "");

        return itinerariesDataFrame;
    }

    @Override
    public RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        ProfileResponse response = runQuery(index, request);
        if (response == null) return null;

        if (!response.getOptions().isEmpty()) {
            PathOptionsTable pathOptionsTable = new PathOptionsTable(transportNetwork, response);
            pathOptionsTable.setOrigin(fromIds[index], fromLats[index], fromLons[index]);
            pathOptionsTable.setDestination(toIds[index], toLats[index], toLons[index]);
            pathOptionsTable.setTripDuration(maxWalkTime, maxBikeTime, maxTripDuration);

            if (dropItineraryGeometry) pathOptionsTable.dropItineraryGeometry();

            pathOptionsTable.build();

            return pathOptionsTable.getDataFrame();
        } else {
            return null;
        }
    }

    private ProfileResponse runQuery(int index, RegionalTask request) {
        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response;
        try {
            response = query.getPlan(request);
        } catch (IllegalStateException e) {
            LOG.error(String.format("Error (*illegal state*) while finding path between %s and %s", fromIds[index], toIds[index]));
            LOG.error(e.getMessage());
            return null;
        } catch (ArrayIndexOutOfBoundsException e) {
            LOG.error(String.format("Error (*array out of bounds*) while finding path between %s and %s", fromIds[index], toIds[index]));
            LOG.error(e.getMessage());
            return null;
        } catch (Exception e) {
            LOG.error(String.format("Error while finding path between %s and %s", fromIds[index], toIds[index]));
            LOG.error(e.getMessage());
            return null;
        }
        return response;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.toLat = toLats[index];
        request.toLon = toLons[index];

        request.percentiles = new int[1];
        request.percentiles[0] = 50;


        return request;
    }

}
