package org.ipea.r5r;

import com.conveyal.r5.api.ProfileResponse;
import com.conveyal.r5.api.util.*;
import com.conveyal.r5.common.GeometryUtils;
import com.conveyal.r5.transit.TransportNetwork;
import com.conveyal.r5.transit.TripPattern;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.LineString;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;

import static com.conveyal.r5.streets.VertexStore.FIXED_FACTOR;

public class PathOptionsTable {

    private static final org.slf4j.Logger LOG = LoggerFactory.getLogger(PathOptionsTable.class);

    private final TransportNetwork transportNetwork;
    private final ProfileResponse response;
    private RDataFrame optionsDataFrame;

    // origin-destination
    private String fromId;
    private double fromLat;
    private double fromLon;

    public void setOrigin(String fromId, double fromLat, double fromLon) {
        this.fromId = fromId;
        this.fromLat = fromLat;
        this.fromLon = fromLon;
    }

    private String toId;
    private double toLat;
    private double toLon;

    public void setDestination(String toId, double toLat, double toLon) {
        this.toId = toId;
        this.toLat = toLat;
        this.toLon = toLon;
    }
    private int maxWalkTime;
    private int maxBikeTime;
    private int maxTripDuration;

    public void setTripDuration(int walkTime, int bikeTime, int tripDuration) {
        this.maxWalkTime = walkTime;
        this.maxBikeTime = bikeTime;
        this.maxTripDuration = tripDuration;
    }

    private boolean dropItineraryGeometry = false;
    public void dropItineraryGeometry() { this.dropItineraryGeometry = true; }

    public LinkedHashMap<String, ArrayList<Object>> getDataFrame() { return optionsDataFrame.getDataFrame(); }

    public PathOptionsTable(TransportNetwork transportNetwork, ProfileResponse response) {
        this.transportNetwork = transportNetwork;
        this.response = response;
    }

    public void build() {
        buildDataFrameStructure();

        try {
            populateDataFrame();
        } catch (Exception e) {
            LOG.error(String.format("Error while collecting paths between %s and %s", fromId, toId));
        }
    }

    void buildDataFrameStructure() {
        // Build data.frame to return data to R in tabular form
        optionsDataFrame = new RDataFrame();
        optionsDataFrame.addStringColumn("fromId", fromId);
        optionsDataFrame.addDoubleColumn("fromLat", fromLat);
        optionsDataFrame.addDoubleColumn("fromLon", fromLon);
        optionsDataFrame.addStringColumn("toId", toId);
        optionsDataFrame.addDoubleColumn("toLat", toLat);
        optionsDataFrame.addDoubleColumn("toLon", toLon);
        optionsDataFrame.addIntegerColumn("option", 0);
        optionsDataFrame.addIntegerColumn("segment", 0);
        optionsDataFrame.addStringColumn("mode", "");
        optionsDataFrame.addIntegerColumn("total_duration", 0);
        optionsDataFrame.addDoubleColumn("segment_duration", 0.0);
        optionsDataFrame.addDoubleColumn("wait", 0.0);
        optionsDataFrame.addIntegerColumn("distance", 0);
        optionsDataFrame.addStringColumn("route", "");
//        optionsDataFrame.addStringColumn("board_time", "");
//        optionsDataFrame.addStringColumn("alight_time", "");
        if (!dropItineraryGeometry) optionsDataFrame.addStringColumn("geometry", "");
    }

    private void populateDataFrame() {
        LOG.info("Building itinerary options table.");
        LOG.info("{} itineraries found.", response.getOptions().size());

        int optionIndex = 0;
        for (ProfileOption option : response.getOptions()) {
            LOG.info("Itinerary option {} of {}: {}", optionIndex + 1, response.getOptions().size(), option.summary);

            LOG.info("travel time min {}, avg {}", option.stats.min, option.stats.avg);
            if (option.stats.avg > (maxTripDuration * 60)) continue;

            if (option.transit == null) { // no transit, maybe has direct access legs
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {

                        // maxStreetTime parameter only affects access and egress walking segments, but no direct trips
                        // if a direct walking trip is found that is longer than maxWalkTime, then drop it
                        LOG.info("segment duration {}", segment.duration);
                        if (segment.mode == LegMode.WALK & (segment.duration / 60) > maxWalkTime) continue;
                        if (segment.mode == LegMode.BICYCLE & (segment.duration / 60) > maxBikeTime) continue;
                        optionsDataFrame.append();

                        LOG.info("  direct {}", segment.toString());

                        optionIndex++;
                        optionsDataFrame.set("option", optionIndex);
                        optionsDataFrame.set("segment", 1);
                        optionsDataFrame.set("mode", segment.mode.toString());
                        optionsDataFrame.set("segment_duration", segment.duration / 60.0);
                        optionsDataFrame.set("total_duration", option.stats.avg / 60.0);

                        // segment.distance value is inaccurate, so it's better to get distances from street edges
                        int dist = calculateSegmentLength(segment);
                        optionsDataFrame.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) optionsDataFrame.set("geometry", segment.geometry.toString());
                    }
                }

            } else { // option has transit
                optionIndex++;
                int segmentIndex = 0;

                // first leg: access to station
                if (option.access != null) {
                    for (StreetSegment segment : option.access) {
                        optionsDataFrame.append();

                        LOG.info("  access {}", segment.toString());

                        optionsDataFrame.set("option", optionIndex);
                        segmentIndex++;
                        optionsDataFrame.set("segment", segmentIndex);
                        optionsDataFrame.set("mode", segment.mode.toString());
                        optionsDataFrame.set("segment_duration", segment.duration / 60.0);
                        optionsDataFrame.set("total_duration", option.stats.avg / 60.0);

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        optionsDataFrame.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) optionsDataFrame.set("geometry", segment.geometry.toString());
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
                                optionsDataFrame.append();

                                segmentIndex++;

                                StringBuilder geometry = new StringBuilder();
                                int accDistance = 0;

                                try {
                                    accDistance = buildTransitGeometryAndCalculateDistance(pattern, tripPattern, geometry);
                                } catch (Exception e) {
                                    geometry = new StringBuilder("LINESTRING EMPTY");
                                }

                                optionsDataFrame.set("option", optionIndex);
                                optionsDataFrame.set("segment", segmentIndex);
                                optionsDataFrame.set("mode", transit.mode.toString());

                                optionsDataFrame.set("total_duration", option.stats.avg / 60.0);
                                optionsDataFrame.set("segment_duration", transit.rideStats.avg / 60.0);
                                optionsDataFrame.set("wait", transit.waitStats.avg / 60.0);

                                optionsDataFrame.set("distance", accDistance);
                                optionsDataFrame.set("route", tripPattern.routeId);

//                                optionsDataFrame.set("board_time", pattern.fromDepartureTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));
//                                optionsDataFrame.set("alight_time", pattern.toArrivalTime.get(0).format(DateTimeFormatter.ISO_LOCAL_TIME));

                                if (!dropItineraryGeometry) optionsDataFrame.set("geometry", geometry.toString());
                            }
                        }
//                    }
                    }


                    // middle leg: walk between stops/stations
                    if (transit.middle != null) {
                        optionsDataFrame.append();

                        LOG.info("  middle {}", transit.middle.toString());

                        optionsDataFrame.set("option", optionIndex);
                        segmentIndex++;
                        optionsDataFrame.set("segment", segmentIndex);
                        optionsDataFrame.set("mode", transit.middle.mode.toString());
                        optionsDataFrame.set("segment_duration",transit.middle.duration / 60.0);
                        optionsDataFrame.set("total_duration", option.stats.avg / 60.0);

                        // getting distances from street edges, which are more accurate than segment.distance
                        int dist = calculateSegmentLength(transit.middle);
                        optionsDataFrame.set("distance", dist / 1000);
                        if (!dropItineraryGeometry)
                            optionsDataFrame.set("geometry", transit.middle.geometry.toString());
                    }
                }

                // last leg: walk to destination
                if (option.egress != null) {
                    for (StreetSegment segment : option.egress) {
                        optionsDataFrame.append();

                        LOG.info("  egress {}", segment.toString());

                        optionsDataFrame.set("option", optionIndex);
                        segmentIndex++;
                        optionsDataFrame.set("segment", segmentIndex);
                        optionsDataFrame.set("mode", segment.mode.toString());
                        optionsDataFrame.set("segment_duration", segment.duration / 60.0);
                        optionsDataFrame.set("total_duration", option.stats.avg / 60.0);

                        // getting distances from street edges, that are more accurate than segment.distance
                        int dist = calculateSegmentLength(segment);
                        optionsDataFrame.set("distance", dist / 1000);

                        if (!dropItineraryGeometry) optionsDataFrame.set("geometry", segment.geometry.toString());
                    }
                }
            }
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
        }
        // close geometry definition with )
        geometry.append(")");

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
