package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.FreeFormPointSet;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.api.util.LegMode;
import com.conveyal.r5.profile.StreetMode;
import com.conveyal.r5.transit.TransportNetwork;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;

public class TravelTimeMatrixComputer extends R5MultiDestinationProcess {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(TravelTimeMatrixComputer.class);

    private FreeFormPointSet destinationPoints;

    public TravelTimeMatrixComputer(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
        destinationPoints = null;
    }

    @Override
    public List<LinkedHashMap<String, ArrayList<Object>>> run() throws ExecutionException, InterruptedException {
        buildDestinationPointSet();
        return super.run();
    }


    private void buildDestinationPointSet() {
        ByteArrayOutputStream dataStream = new ByteArrayOutputStream();
        DataOutputStream pointStream = new DataOutputStream(dataStream);

        try {
            pointStream.writeInt(toIds.length);
            for (String toId : toIds) {
                pointStream.writeUTF(toId);
            }
            for (double toLat : toLats) {
                pointStream.writeDouble(toLat);
            }
            for (double toLon : toLons) {
                pointStream.writeDouble(toLon);
            }
            for (int i = 0; i < toIds.length; i++) {
                pointStream.writeDouble(1.0);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        ByteArrayInputStream pointsInput = new ByteArrayInputStream(dataStream.toByteArray());

        try {
            destinationPoints = new FreeFormPointSet(pointsInput);
        } catch (IOException e) {
            e.printStackTrace();
        }

        if (!this.directModes.isEmpty()) {
            for (LegMode mode : this.directModes) {
                transportNetwork.linkageCache.getLinkage(destinationPoints, transportNetwork.streetLayer, StreetMode.valueOf(mode.toString()));
            }
        }
    }

    @Override
    protected LinkedHashMap<String, ArrayList<Object>> runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

        request.percentiles = this.routingProperties.percentiles;

        TravelTimeComputer computer = new TravelTimeComputer(request, transportNetwork);
        OneOriginResult travelTimeResults = computer.computeTravelTimes();
        RDataFrame travelTimesTable = buildDataFrameStructure(fromIds[index]);
        populateDataFrame(travelTimeResults, travelTimesTable);

        if (travelTimesTable.nRow() > 0) {
            return travelTimesTable.getDataFrame();
        } else {
            return null;
        }
    }

    private void populateDataFrame(OneOriginResult travelTimeResults, RDataFrame travelTimesTable) {
        for (int i = 0; i < travelTimeResults.travelTimes.nPoints; i++) {
            if (travelTimeResults.travelTimes.getValues()[0][i] <= maxTripDuration) {
                travelTimesTable.append();
                travelTimesTable.set("toId", toIds[i]);
                if (this.routingProperties.percentiles.length == 1) {
                    travelTimesTable.set("travel_time", travelTimeResults.travelTimes.getValues()[0][i]);
                } else {
                    for (int p = 0; p < this.routingProperties.percentiles.length; p++) {
                        int tt = travelTimeResults.travelTimes.getValues()[p][i];
                        String ps = String.format("%03d", this.routingProperties.percentiles[p]);
                        if (tt < maxTripDuration) {
                            travelTimesTable.set("travel_time_p" + ps, tt);
                        }
                    }
                }
            }
        }
    }

    private RDataFrame buildDataFrameStructure(String fromId) {
        // Build return table
        RDataFrame travelTimesTable = new RDataFrame();
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
