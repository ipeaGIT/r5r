package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.PathResult;
import com.conveyal.r5.analyst.fare.*;
import com.conveyal.r5.transit.TransitLayer;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.ipea.r5r.Fares.RuleBasedInRoutingFareCalculator;

import static org.ipea.r5r.JsonUtil.OBJECT_MAPPER;


public class RoutingProperties {

    public static final float DEFAULT_WALK_SPEED = 1.0f;
    public static final float DEFAULT_BIKE_SPEED = 3.3f;
    public static final int DEFAULT_MAX_RIDES = 3;
    public static final int DEFAULT_MAX_LEVEL_TRAFFIC_STRESS = 2;
    public static final int DEFAULT_SUBOPTIMAL_MINUTES = 0;
    public static final int DEFAULT_TIME_WINDOW_SIZE = 10;
    public static final int DEFAULT_NUMBER_OF_MONTE_CARLO_DRAWS = 50;
    public static final float DEFAULT_MAX_FARE = -1.0f;
    public static final int[] DEFAULT_PERCENTILES = {50};
    public static final int[] DEFAULT_CUTOFFS = {30};
    public static final float[] DEFAULT_FARE_CUTOFFS = {-1.0f};
    public double walkSpeed = DEFAULT_WALK_SPEED;
    public double bikeSpeed = DEFAULT_BIKE_SPEED;
    public int maxRides = DEFAULT_MAX_RIDES; // max 8 number of rides in public transport trips
    public int maxLevelTrafficStress = DEFAULT_MAX_LEVEL_TRAFFIC_STRESS;
    public int suboptimalMinutes = DEFAULT_SUBOPTIMAL_MINUTES; // Suboptimal minutes in point-to-point queries
    public int timeWindowSize = DEFAULT_TIME_WINDOW_SIZE; // minutes
    public int numberOfMonteCarloDraws = DEFAULT_NUMBER_OF_MONTE_CARLO_DRAWS; //
    public int[] percentiles = DEFAULT_PERCENTILES;
    public int[] cutoffs = DEFAULT_CUTOFFS;
    public boolean travelTimesBreakdown = false;
    public boolean expandedTravelTimes = false;
    public PathResult.Stat travelTimesBreakdownStat = PathResult.Stat.MEAN;

    public float maxFare = DEFAULT_MAX_FARE;
    public float[] fareCutoffs = DEFAULT_FARE_CUTOFFS;
    public InRoutingFareCalculator fareCalculator = null;
    public TransitLayer transitLayer = null;

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
    }

    public void reset() {
        walkSpeed = DEFAULT_WALK_SPEED;
        bikeSpeed = DEFAULT_BIKE_SPEED;

        maxRides = DEFAULT_MAX_RIDES;
        maxLevelTrafficStress = DEFAULT_MAX_LEVEL_TRAFFIC_STRESS;
        suboptimalMinutes = DEFAULT_SUBOPTIMAL_MINUTES;
        timeWindowSize = DEFAULT_TIME_WINDOW_SIZE;
        numberOfMonteCarloDraws = DEFAULT_NUMBER_OF_MONTE_CARLO_DRAWS;

        travelTimesBreakdown = false;
        travelTimesBreakdownStat = PathResult.Stat.MEAN;
        expandedTravelTimes = false;

        percentiles = DEFAULT_PERCENTILES;
        cutoffs = DEFAULT_CUTOFFS;
        fareCutoffs = DEFAULT_FARE_CUTOFFS;

        maxFare = DEFAULT_MAX_FARE;
        fareCalculator = null;
        // do not reset transitLayer
    }
}
