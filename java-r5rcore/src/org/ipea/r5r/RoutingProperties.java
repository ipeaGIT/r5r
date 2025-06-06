package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.fare.*;
import com.conveyal.r5.api.util.SearchType;
import com.conveyal.r5.transit.TransitLayer;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.ipea.r5r.Fares.RuleBasedInRoutingFareCalculator;

import static org.ipea.r5r.JsonUtil.OBJECT_MAPPER;


public class RoutingProperties {

    public double walkSpeed;
    public double bikeSpeed;
    public int maxRides; // max 8 number of rides in public transport trips
    public int maxLevelTrafficStress;
    public int suboptimalMinutes; // Suboptimal minutes in point-to-point queries
    public int timeWindowSize; // minutes
    public int numberOfMonteCarloDraws; //
    public int[] percentiles = {50};
    public int [] cutoffs = {30};
    public boolean travelTimesBreakdown;
    public boolean expandedTravelTimes;
    public PathResult.Stat travelTimesBreakdownStat;

    public float maxFare;
    public float[] fareCutoffs = {-1.0f};
    public InRoutingFareCalculator fareCalculator;
    public TransitLayer transitLayer;
    public SearchType searchType = SearchType.DEPART_FROM;

    public void setFareCalculatorJson(String fareCalculatorJson) {
        // first, check to see if this is a built-in R5 fare calculator JSON representation
        try {
            ObjectNode node = OBJECT_MAPPER.readValue(fareCalculatorJson, ObjectNode.class);
            // https://stackoverflow.com/questions/26190851
            if (node.has("type")) {
                this.fareCalculator = OBJECT_MAPPER.readValue(fareCalculatorJson, InRoutingFareCalculator.class);
            } else {
                this.fareCalculator = new RuleBasedInRoutingFareCalculator(transitLayer, fareCalculatorJson);
            }
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

    }

    public RoutingProperties() {
        walkSpeed = 1.0f;
        bikeSpeed = 3.3f;
        maxRides = 8; // max 8 number of rides in public transport trips
        maxLevelTrafficStress = 4;
        suboptimalMinutes = 5; // Suboptimal minutes in point-to-point queries
        timeWindowSize = 60; // minutes
        numberOfMonteCarloDraws = 60; //

        travelTimesBreakdown = false;
        travelTimesBreakdownStat = PathResult.Stat.MEAN;
        expandedTravelTimes = false;

        maxFare = -1.0f;
        fareCalculator = null;
        transitLayer = null;
    }
}
