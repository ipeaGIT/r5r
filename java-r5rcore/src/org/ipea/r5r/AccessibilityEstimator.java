package org.ipea.r5r;

import com.conveyal.r5.OneOriginResult;
import com.conveyal.r5.analyst.PointSet;
import com.conveyal.r5.analyst.TravelTimeComputer;
import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.analyst.decay.*;
import com.conveyal.r5.transit.TransportNetwork;

import java.text.ParseException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.concurrent.ForkJoinPool;

public class AccessibilityEstimator extends R5MultiDestinationProcess {

    private DecayFunction decayFunction;

    public void setDecayFunction(String decayFunction, double decayValue) {
        decayFunction = decayFunction.toUpperCase();
        if (decayFunction.equals("STEP")) { this.decayFunction = new StepDecayFunction(); }
        if (decayFunction.equals("EXPONENTIAL")) { this.decayFunction = new ExponentialDecayFunction(); }

        if (decayFunction.equals("FIXED_EXPONENTIAL")) {
            this.decayFunction = new FixedExponentialDecayFunction();
            ((FixedExponentialDecayFunction) this.decayFunction).decayConstant = decayValue;
        }
        if (decayFunction.equals("LINEAR")) {
            this.decayFunction = new LinearDecayFunction();
            ((LinearDecayFunction) this.decayFunction).widthMinutes = (int) decayValue;
        }
        if (decayFunction.equals("LOGISTIC")) {
            this.decayFunction = new LogisticDecayFunction();
            ((LogisticDecayFunction) this.decayFunction).standardDeviationMinutes = decayValue;
        }
        this.decayFunction.prepare();
    }

    public AccessibilityEstimator(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);
    }

    @Override
    protected RDataFrame runProcess(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

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
        int[][][] accessibility = travelTimeResults.accessibility.getIntValues();

        int nPercentiles = routingProperties.percentiles.length;
        int nCutoffs = routingProperties.cutoffs.length;


        for (int p = 0; p < nPercentiles; p++) {
            for (int c = 0; c < nCutoffs; c++) {
                travelTimesTable.append();
                travelTimesTable.set("percentile", routingProperties.percentiles[p]);
                travelTimesTable.set("cutoff", routingProperties.cutoffs[c]);
                travelTimesTable.set("accessibility", accessibility[0][p][c]);
            }
        }
    }

    @Override
    protected RDataFrame buildDataFrameStructure(String fromId, int nRows) {
        // Build return table
        RDataFrame travelTimesTable = new RDataFrame(nRows);
        travelTimesTable.addStringColumn("from_id", fromId);
        travelTimesTable.addIntegerColumn("percentile", 0);
        travelTimesTable.addIntegerColumn("cutoff", 0);
        travelTimesTable.addIntegerColumn("accessibility", 0);

        return travelTimesTable;
    }

    @Override
    protected RegionalTask buildRequest(int index) throws ParseException {
        RegionalTask request = super.buildRequest(index);

        request.destinationPointSetKeys = new String[1];
        request.destinationPointSetKeys[0] = "opportunities";
        request.destinationPointSets = new PointSet[1];
        request.destinationPointSets[0] = destinationPoints;

        request.percentiles = this.routingProperties.percentiles;
        request.recordAccessibility = true;
        request.recordTimes = false;
        request.includePathResults = false;
        request.decayFunction = this.decayFunction;

        request.cutoffsMinutes = routingProperties.cutoffs;

        return request;
    }

}
