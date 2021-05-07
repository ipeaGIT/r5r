package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.transit.TransportNetwork;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.concurrent.ForkJoinPool;

public class DetailedItineraryPlanner extends R5MultiDestinationProcess {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(DetailedItineraryPlanner.class);

    private boolean dropItineraryGeometry = false;
    public void dropItineraryGeometry() { dropItineraryGeometry = true; }

    public DetailedItineraryPlanner(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);

        routingProperties.timeWindowSize = 1; // minutes
        routingProperties.numberOfMonteCarloDraws = 1; //
    }

    @Override
    public LinkedHashMap<String, ArrayList<Object>> runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        ProfileResponse response = runQuery(index, request);
        if (response == null) return null;

        if (!response.getOptions().isEmpty()) {
            PathOptionsTable pathOptionsTable = new PathOptionsTable(transportNetwork, request, response);
            pathOptionsTable.setOrigin(fromIds[index], fromLats[index], fromLons[index]);
            pathOptionsTable.setDestination(toIds[index], toLats[index], toLons[index]);
            pathOptionsTable.setTripDuration(maxWalkTime, maxTripDuration);

            if (dropItineraryGeometry) pathOptionsTable.dropItineraryGeometry();

            pathOptionsTable.build();

            return pathOptionsTable.getDataFrame();
        } else {
            return null;
        }
    }

    private ProfileResponse runQuery(int index, RegionalTask request) {
        PointToPointQuery query = new PointToPointQuery(transportNetwork);

        ProfileResponse response = null;
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
