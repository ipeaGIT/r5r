package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.transit.TransportNetwork;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.ForkJoinPool;

public class TravelTimeMatrixComputer extends R5MultiDestinationProcess {

    private static final int ROUTES_INDEX = 0;
    private static final int ACCESS_TIME_INDEX = 4;
    private static final int WAIT_TIME_INDEX = 7;
    private static final int RIDE_TIME_INDEX = 3;
    private static final int TRANSFER_TIME_INDEX = 6;
    private static final int EGRESS_TIME_INDEX = 5;
    private static final int TOTAL_TIME_INDEX = 8;

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
        ArrayList<String[]>[] pathResults =  null;

        if (this.routingProperties.travelTimesBreakdown) {
            pathResults = travelTimeResults.paths.summarizeIterations(this.routingProperties.travelTimesBreakdownStat);
        }

        for (int destination = 0; destination < travelTimeResults.travelTimes.nPoints; destination++) {
            if (travelTimeResults.travelTimes.getValues()[0][destination] <= maxTripDuration) {

                travelTimesTable.append();

                // fill travel times for destination
                travelTimesTable.set("toId", toIds[destination]);
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

                // fill travel details for destination
                if (this.routingProperties.travelTimesBreakdown & pathResults != null) {
                    if (!pathResults[destination].isEmpty()) {
                        // get only first recorded path
                        String[] a = pathResults[destination].get(0);

                        travelTimesTable.set("routes", a[ROUTES_INDEX]);

                        travelTimesTable.set("access_time", parseTravelTime(a[ACCESS_TIME_INDEX]));
                        travelTimesTable.set("wait_time", parseTravelTime(a[WAIT_TIME_INDEX]));
                        travelTimesTable.set("ride_time", parseTravelTime(a[RIDE_TIME_INDEX]));
                        travelTimesTable.set("transfer_time", parseTravelTime(a[TRANSFER_TIME_INDEX]));
                        travelTimesTable.set("egress_time", parseTravelTime(a[EGRESS_TIME_INDEX]));
                        travelTimesTable.set("total_time", parseTravelTime(a[TOTAL_TIME_INDEX]));
                    }
                }
            }
        }
    }

    private double parseTravelTime(String a) {
        if (a == null) return 0.0;
        if (a.equals("")) return 0.0;

        String[] b = a.split("\\|");

        return Arrays.stream(b).sequential().mapToDouble(Double::parseDouble).sum();
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
