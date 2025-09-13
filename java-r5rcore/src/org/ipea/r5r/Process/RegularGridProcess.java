package org.ipea.r5r.Process;

import java.text.ParseException;
import java.util.List;
import java.util.concurrent.ForkJoinPool;

import org.ipea.r5r.RegularGridResult;
import org.ipea.r5r.RoutingProperties;
import org.locationtech.jts.geom.Envelope;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.WebMercatorExtents;
import com.conveyal.r5.analyst.cluster.TravelTimeSurfaceTask;
/**
 * This class produces regular grids of travel times, used in isochrones.
 */
public class RegularGridProcess extends R5Process<RegularGridResult, RegularGridResult[]> {
    public WebMercatorExtents extents;

    public RegularGridProcess(ForkJoinPool threadPool, RoutingProperties routingProperties) {
        super(threadPool, routingProperties);
        setZoom(12);
    }

    public void setZoom(int zoom) {
        Envelope env = routingProperties.transportNetworkWorking.getEnvelope();
        extents = WebMercatorExtents.forWgsEnvelope(env, zoom);
    }

    @Override
    public RegularGridResult runProcess(int index) {
        TravelTimeSurfaceTask request = new TravelTimeSurfaceTask();

        try {
            initalizeRequest(index, request);
        } catch (ParseException e) {
            // rethrow as unchecked
            throw new RuntimeException(e);
        }
    
        request.makeTauiSite = false;
        request.percentiles = routingProperties.percentiles;
        request.zoom = extents.zoom;
        request.west = extents.west;
        request.width = extents.width;
        request.north = extents.north;
        request.height = extents.height;

        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);
        OneOriginResult result = computer.computeTravelTimes();

        return new RegularGridResult(result.travelTimes, request);
    }

    @Override
    protected RegularGridResult[] mergeResults(List<RegularGridResult> processResults) {
        return processResults.toArray(new RegularGridResult[0]);
    }

    // no destination pointsets
    @Override
    protected void buildDestinationPointSet() {}
}
