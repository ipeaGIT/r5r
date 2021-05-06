package org.ipea.r5r;

import com.conveyal.r5.analyst.cluster.RegionalTask;
import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.point_to_point.builder.PointToPointQuery;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.LineString;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ForkJoinPool;
import java.util.stream.Collectors;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class DetailedItineraryPlanner extends R5Process {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(DetailedItineraryPlanner.class);

    protected String[] toIds;
    private double[] toLats;
    private double[] toLons;

    private int nDestinations;

    private boolean dropItineraryGeometry = false;
    public void dropItineraryGeometry() { dropItineraryGeometry = true; }

    public DetailedItineraryPlanner(ForkJoinPool threadPool, TransportNetwork transportNetwork, RoutingProperties routingProperties) {
        super(threadPool, transportNetwork, routingProperties);

        routingProperties.timeWindowSize = 1; // minutes
        routingProperties.numberOfMonteCarloDraws = 1; //
    }

    public void setDestinations(String[] toIds, double[] toLats, double[] toLons) {
        this.toIds = toIds;
        this.toLats = toLats;
        this.toLons = toLons;

        this.nDestinations = toIds.length;
    }

    @Override
    public List<LinkedHashMap<String, ArrayList<Object>>> run() throws ExecutionException, InterruptedException {
        int[] requestIndices = new int[fromIds.length];
        for (int i = 0; i < fromIds.length; i++) requestIndices[i] = i;

        return r5rThreadPool.submit(() ->
                Arrays.stream(requestIndices).parallel()
                        .mapToObj(index -> {
                            LinkedHashMap<String, ArrayList<Object>> results = null;
                            try {
                                results = planSingleTrip(index);
                            } catch (ParseException e) {
                                e.printStackTrace();
                            }
                            return results;
                        }).
                        collect(Collectors.toList())).get();
    }

    public LinkedHashMap<String, ArrayList<Object>> planSingleTrip(int index) throws ParseException {
        RegionalTask request = buildRequest(index);

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

        if (!response.getOptions().isEmpty()) {
            LinkedHashMap<String, ArrayList<Object>> pathOptionsTable;

            try {
                // if only the shortest path is requested, return min travel times instead of avg
                boolean shortestPath = (this.routingProperties.suboptimalMinutes == 0);

                pathOptionsTable = buildPathOptionsTable(fromIds[index], fromLats[index], fromLons[index],
                        toIds[index], toLats[index], toLons[index],
                        maxWalkTime, maxTripDuration, shortestPath, dropItineraryGeometry, response.getOptions());
            } catch (Exception e) {
                LOG.error(String.format("Error while collecting paths between %s and %s", fromIds[index], toIds[index]));
                return null;
            }

            return pathOptionsTable;
        } else {
            return null;
        }
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

    private LinkedHashMap<String, ArrayList<Object>> buildPathOptionsTable(String fromId, double fromLat, double fromLon,
                                                                           String toId, double toLat, double toLon,
                                                                           int maxWalkTime, int maxTripDuration,
                                                                           boolean shortestPath,
                                                                           boolean dropItineraryGeometry,
                                                                           List<ProfileOption> pathOptions) {

        // Build data.frame to return data to R in tabular form
        RDataFrame pathOptionsTable = new RDataFrame();
        pathOptionsTable.addStringColumn("fromId", fromId);
        pathOptionsTable.addDoubleColumn("fromLat", fromLat);
        pathOptionsTable.addDoubleColumn("fromLon", fromLon);
        pathOptionsTable.addStringColumn("toId", toId);
        pathOptionsTable.addDoubleColumn("toLat", toLat);
        pathOptionsTable.addDoubleColumn("toLon", toLon);
        pathOptionsTable.addIntegerColumn("option", 0);
        pathOptionsTable.addIntegerColumn("segment", 0);
        pathOptionsTable.addStringColumn("mode", "");
        pathOptionsTable.addIntegerColumn("total_duration", 0);
        pathOptionsTable.addDoubleColumn("segment_duration", 0.0);
        pathOptionsTable.addDoubleColumn("wait", 0.0);
        pathOptionsTable.addIntegerColumn("distance", 0);
        pathOptionsTable.addStringColumn("route", "");
        pathOptionsTable.addStringColumn("board_time", "");
        pathOptionsTable.addStringColumn("alight_time", "");
        if (!dropItineraryGeometry) pathOptionsTable.addStringColumn("geometry", "");

        LOG.info("Building itinerary options table.");
        LOG.info("{} itineraries found.", pathOptions.size());

        int optionIndex = 0;
        for (ProfileOption option : pathOptions) {
            LOG.info("Itinerary option {} of {}: {}", optionIndex + 1, pathOptions.size(), option.summary);

            LOG.info("travel time min {}, avg {}", option.stats.min, option.stats.avg);
            if (option.stats.avg > (maxTripDuration * 60)) continue;

            if (option.transit == null) { // no transit, maybe has direct access legs
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {

                        // maxStreetTime parameter only affects access and egress walking segments, but no direct trips
                        // if a direct walking trip is found that is longer than maxWalkTime, then drop it
                        LOG.info("segment duration {}", segment.duration);
                        if (segment.mode == LegMode.WALK & (segment.duration / 60) > maxWalkTime) continue;
                        pathOptionsTable.append();

                        LOG.info("  direct {}", segment.toString());

                        optionIndex++;
                        pathOptionsTable.set("option", optionIndex);
                        pathOptionsTable.set("segment", 1);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // segment.distance value is inaccurate, so it's better to get distances from street edges
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

            } else { // option has transit
                optionIndex++;
                int segmentIndex = 0;

                // first leg: access to station
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {
                        pathOptionsTable.append();

                        LOG.info("  access {}", segment.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);

                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }

                for (TransitSegment transit : option.transit) {

                    if (!transit.segmentPatterns.isEmpty()) {
//                    for (SegmentPattern pattern : transit.segmentPatterns) {
                        // Use only first of many possible repeated patterns
                        SegmentPattern pattern = transit.segmentPatterns.get(0);
                        if (pattern != null) {

                            LOG.info("  transit pattern index {}", pattern.patternIdx);

                            TripPattern tripPattern = transportNetwork.transitLayer.tripPatterns.get(pattern.patternIdx);

                            if (tripPattern != null) {
                                pathOptionsTable.append();

                                segmentIndex++;

                                StringBuilder geometry = new StringBuilder();
                                int accDistance = 0;

                                try {
                                    accDistance = buildTransitGeometryAndCalculateDistance(pattern, tripPattern, geometry);
                                } catch (Exception e) {
                                    geometry = new StringBuilder("LINESTRING EMPTY");
                                }

                                pathOptionsTable.set("option", optionIndex);
                                pathOptionsTable.set("segment", segmentIndex);
                                pathOptionsTable.set("mode", transit.mode.toString());

                                if (shortestPath) {
                                    pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                                    pathOptionsTable.set("segment_duration", transit.rideStats.min / 60.0);
                                    pathOptionsTable.set("wait", transit.waitStats.min / 60.0);
                                } else {
                                    pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                                    pathOptionsTable.set("segment_duration", transit.rideStats.avg / 60.0);
                                    pathOptionsTable.set("wait", transit.waitStats.avg / 60.0);
                                }

                                pathOptionsTable.set("distance", accDistance);
                                pathOptionsTable.set("route", tripPattern.routeId);

                                pathOptionsTable.set("board_time", pattern.fromDepartureTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));
                                pathOptionsTable.set("alight_time", pattern.toArrivalTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));

                                if (!dropItineraryGeometry) pathOptionsTable.set("geometry", geometry.toString());
                            }
                        }
//                    }
                    }


                    // middle leg: walk between stops/stations
                    if (transit.middle != null) {
                        pathOptionsTable.append();

                        LOG.info("  middle {}", transit.middle.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", transit.middle.mode.toString());
                        pathOptionsTable.set("segment_duration",transit.middle.duration / 60.0);

                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, which are more accurate than segment.distance
                        int dist = calculateSegmentLength(transit.middle);
                        pathOptionsTable.set("distance", dist / 1000);
                        if (!dropItineraryGeometry)
                            pathOptionsTable.set("geometry", transit.middle.geometry.toString());
                    }
                }

                // last leg: walk to destination
                if (option.egress != null) {
                    for (StreetSegment segment : option.egress) {
                        pathOptionsTable.append();

                        LOG.info("  egress {}", segment.toString());

                        pathOptionsTable.set("option", optionIndex);
                        segmentIndex++;
                        pathOptionsTable.set("segment", segmentIndex);
                        pathOptionsTable.set("mode", segment.mode.toString());
                        pathOptionsTable.set("segment_duration", segment.duration / 60.0);
                        if (shortestPath) {
                            pathOptionsTable.set("total_duration", option.stats.min / 60.0);
                        } else {
                            pathOptionsTable.set("total_duration", option.stats.avg / 60.0);
                        }

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        pathOptionsTable.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) pathOptionsTable.set("geometry", segment.geometry.toString());
                    }
                }
            }
        }

        if (pathOptionsTable.nRow() > 0) {
            return pathOptionsTable.getDataFrame();
        } else {
            return null;
        }

    }

    private int buildTransitGeometryAndCalculateDistance(SegmentPattern segmentPattern,
                                                         TripPattern tripPattern,
                                                         StringBuilder geometry) {
        org.locationtech.jts.geom.Coordinate previousCoordinate = new org.locationtech.jts.geom.Coordinate(0, 0);
        double accDistance = 0;

        if (tripPattern.shape != null) {
            List<LineString> shapeSegments = tripPattern.getHopGeometries(transportNetwork.transitLayer);
            int firstStop = segmentPattern.fromIndex;
            int lastStop = segmentPattern.toIndex;

            for (int i = firstStop; i < lastStop; i++) {
                for (org.locationtech.jts.geom.Coordinate coordinate : shapeSegments.get(i).getCoordinates()) {
                    if (geometry.toString().equals("")) {
                        geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                    } else {
                        geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                        accDistance += GeometryUtils.distance(previousCoordinate.y, previousCoordinate.x, coordinate.y, coordinate.x);
                    }
                    previousCoordinate.x = coordinate.x;
                    previousCoordinate.y = coordinate.y;

                }
            }
            geometry.append(")");

        } else {
            for (int stop = segmentPattern.fromIndex; stop <= segmentPattern.toIndex; stop++) {
                int stopIdx = tripPattern.stops[stop];
                Coordinate coordinate = transportNetwork.transitLayer.getCoordinateForStopFixed(stopIdx);

                coordinate.x = coordinate.x / FIXED_FACTOR;
                coordinate.y = coordinate.y / FIXED_FACTOR;

                if (geometry.toString().equals("")) {
                    geometry.append("LINESTRING (").append(coordinate.x).append(" ").append(coordinate.y);
                } else {
                    geometry.append(", ").append(coordinate.x).append(" ").append(coordinate.y);
                    accDistance += GeometryUtils.distance(previousCoordinate.y, previousCoordinate.x, coordinate.y, coordinate.x);
                }
                previousCoordinate.x = coordinate.x;
                previousCoordinate.y = coordinate.y;
            }
            geometry.append(")");
        }

        return (int) accDistance;
    }

    private int calculateSegmentLength(StreetSegment segment) {
        int sum = 0;
        for (StreetEdgeInfo streetEdgeInfo : segment.streetEdges) {
            sum += streetEdgeInfo.distance;
        }
        return sum;
    }

}
