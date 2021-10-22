package org.ipea.r5r;

import com.amazonaws.util.StringUtils;
import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.PathWriter;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;
import com.esotericsoftware.minlog.Log;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.util.*;
import java.util.concurrent.ForkJoinPool;

public class TravelTimeMatrixComputer extends R5MultiDestinationProcess {

    private static final int ROUTES_INDEX = 0;
    private static final int ACCESS_TIME_INDEX = 4;
    private static final int WAIT_TIME_INDEX = 7;
    private static final int RIDE_TIME_INDEX = 3;
    private static final int TRANSFER_TIME_INDEX = 6;
    private static final int EGRESS_TIME_INDEX = 5;
    private static final int TOTAL_TIME_INDEX = 8;

    private static final Logger LOG = LoggerFactory.getLogger(TravelTimeMatrixComputer.class);

    public TravelTimeMatrixComputer(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        request.percentiles = this.routingProperties.percentiles;
        request.includePathResults = this.routingProperties.travelTimesBreakdown;
        request.nPathsPerTarget = 1;

        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);
        OneOriginResult travelTimeResults = computer.computeTravelTimes();
        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index], 10);
        populateDataFrame(travelTimeResults, travelTimesTable);

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable;
        } else {
            return null;
        }
    }

    private void populateDataFrame(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        // summarize travel paths, if required
        ArrayList<String[]>[] pathResults =  null;
        if (this.routingProperties.travelTimesBreakdown) {
            pathResults = travelTimeResults.paths.summarizeIterations(this.routingProperties.travelTimesBreakdownStat);
        }

        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            if (travelTimeResults.travelTimes.getValues()[0][destination] <= maxTripDuration) {

                // add new row to data frame
                travelTimesTable.append();

                // set destination id
                travelTimesTable.set("toId", toIds[destination]);

                // fill travel times for destination
                populateTravelTimes(travelTimeResults, travelTimesTable, destination);

                // fill travel details for destination
                populateTravelTimesBreakdown(travelTimesTable, pathResults, destination);
            }
        }
    }

    private void populateTravelTimes(OneOriginResult travelTimeResults, RDataFrame travelTimesTable, int destination) {
        if (this.routingProperties.percentiles.length == 1) {
            travelTimesTable.set("travel_time", travelTimeResults.travelTimes.getValues()[0][destination]);
        } else {
            for (int p = 0; p < this.routingProperties.percentiles.length; p++) {
                int tt = travelTimeResults.travelTimes.getValues()[p][destination];
                String ps = String.format("%03d", this.routingProperties.percentiles[p]);
                if (tt < maxTripDuration) {
                    travelTimesTable.set("travel_time_p" + ps, tt);
                }
            }
        }
    }

    private void populateTravelTimesBreakdown(RDataFrame travelTimesTable, ArrayList<String[]>[] pathResults, int destination) {
        if (this.routingProperties.travelTimesBreakdown & pathResults != null) {
            if (!pathResults[destination].isEmpty()) {
                // get only first recorded path
                String[] a = pathResults[destination].get(0);

                String routes = a[ROUTES_INDEX];
                travelTimesTable.set("routes", routes);

                if (!routes.equals(""))
                    travelTimesTable.set("n_rides", routes.split("\\|").length);

                travelTimesTable.set("access_time", parseAndSumTravelTimes(a[ACCESS_TIME_INDEX]));
                travelTimesTable.set("wait_time", parseAndSumTravelTimes(a[WAIT_TIME_INDEX]));
                travelTimesTable.set("ride_time", parseAndSumTravelTimes(a[RIDE_TIME_INDEX]));
                travelTimesTable.set("transfer_time", parseAndSumTravelTimes(a[TRANSFER_TIME_INDEX]));
                travelTimesTable.set("egress_time", parseAndSumTravelTimes(a[EGRESS_TIME_INDEX]));
                travelTimesTable.set("total_time", parseAndSumTravelTimes(a[TOTAL_TIME_INDEX]));
            }
        }
    }

    private double parseAndSumTravelTimes(String a) {
        if (a == null) return 0.0;
        if (a.equals("")) return 0.0;

        String[] b = a.split("\\|");

        return Arrays.stream(b).sequential().mapToDouble(s -> Double.parseDouble(s.replaceAll(",","."))).sum();
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // Build return table
        RDataFrame travelTimesTable = new RDataFrame(nRows);
        travelTimesTable.addStringColumn("fromId", fromId);
        travelTimesTable.addStringColumn("toId", "");

        if (this.routingProperties.percentiles.length == 1) {
            travelTimesTable.addIntegerColumn("travel_time", Integer.MAX_VALUE);
        } else {
            for (int p : this.routingProperties.percentiles) {
                String ps = String.format("%03d", p);
                travelTimesTable.addIntegerColumn("travel_time_p" + ps, Integer.MAX_VALUE);
            }
        }

        if (this.routingProperties.travelTimesBreakdown) {
            travelTimesTable.addDoubleColumn("access_time", 0.0);
            travelTimesTable.addDoubleColumn("wait_time", 0.0);
            travelTimesTable.addDoubleColumn("ride_time", 0.0);
            travelTimesTable.addDoubleColumn("transfer_time", 0.0);
            travelTimesTable.addDoubleColumn("egress_time", 0.0);
            travelTimesTable.addDoubleColumn("total_time", 0.0);

            travelTimesTable.addStringColumn("routes", "");
            travelTimesTable.addIntegerColumn("n_rides", 0);
        }
        return travelTimesTable;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.destinationPointSets = new PointSet[1];
        request.destinationPointSets[0] = destinationPoints;

        return request;
    }


}
