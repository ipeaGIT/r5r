package org.ipea.r5r.Process;

import java.text.ParseException;
import java.util.concurrent.ForkJoinPool;

import org.ipea.r5r.RDataFrame;
import org.ipea.r5r.RoutingProperties;
import org.ipea.r5r.R5.R5ParetoServer;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;

/**
 * This outputs the Pareto itinerary planner results directly to JSON.
 */
public class FaretoDebug extends R5Process {
    public FaretoDebug(ForkJoinPool threadPool,
            RoutingProperties routingProperties) {
        super(threadPool, routingProperties);
    }

    public R5ParetoServer.ParetoReturn pathResults = null;

    @Override
    protected boolean isOneToOne() {
        return true;
    }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);
        request.fromLat = fromLats[0];
        request.fromLon = fromLons[0];
        request.toLat = toLats[0];
        request.toLon = toLons[0];
        request.maxFare = 150_000_000;

        R5ParetoServer computer = new R5ParetoServer(request, transportNetwork);
        pathResults = computer.handle();

        // to match R5Process interface, return type must be dataframe. We work around this by returning an empty
        // dataframe. Cannot return null because value is used in mergeDataFrame
        return new RDataFrame(0);
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // to avoid NPEs in mergeDataFrame, something must be returned
        return new RDataFrame(nRows);
    }
 
    @Override
    protected void buildDestinationPointSet() {
        // not needed in this class
    }

}
