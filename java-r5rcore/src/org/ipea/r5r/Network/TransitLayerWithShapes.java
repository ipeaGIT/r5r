package org.ipea.r5r.Network;

import com.conveyal.gtfs.GTFSFeed;
import com.conveyal.gtfs.model.*;
import com.conveyal.r5.transit.*;
import com.conveyal.r5.util.LocationIndexedLineInLocalCoordinateSystem;
import com.google.common.base.Strings;
import com.google.common.collect.HashMultimap;
import com.google.common.collect.Multimap;
import gnu.trove.list.TIntList;
import gnu.trove.list.array.TIntArrayList;
import gnu.trove.map.TObjectIntMap;
import gnu.trove.map.hash.TObjectIntHashMap;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.linearref.LinearLocation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.DateTimeException;
import java.time.ZoneId;
import java.time.zone.ZoneRulesException;
import java.util.*;
import java.util.stream.DoubleStream;
import java.util.stream.StreamSupport;

public class TransitLayerWithShapes extends TransitLayer {

    public static final boolean SAVE_SHAPES = true;

    private static final Logger LOG = LoggerFactory.getLogger(TransitLayerWithShapes.class);

    /**
     * Load data from a GTFS feed. Call multiple times to load multiple feeds.
     * The supplied feed is treated as read-only, and is not closed after being loaded.
     * This method requires findPatterns() to have been called on the feed before it's passed in.
     */
    public void loadFromGtfs (GTFSFeed gtfs, TransitLayer.LoadLevel level) throws DuplicateFeedException {
        if (feedChecksums.containsKey(gtfs.feedId)) {
            throw new DuplicateFeedException(gtfs.feedId);
        }

        // checksum feed and add to checksum cache
        feedChecksums.put(gtfs.feedId, gtfs.checksum);

        // Load stops.
        // ID is the GTFS string ID, stopIndex is the zero-based index, stopVertexIndex is the index in the street layer.
        TObjectIntMap<String> indexForUnscopedStopId = new TObjectIntHashMap<>();
        stopsWheelchair = new BitSet(gtfs.stops.size());
        for (Stop stop : gtfs.stops.values()) {
            int stopIndex = stopIdForIndex.size();
            String scopedStopId = String.join(":", stop.feed_id, stop.stop_id);
            // This is only used while building the TransitNetwork to look up StopTimes from the same feed.
            indexForUnscopedStopId.put(stop.stop_id, stopIndex);
            stopIdForIndex.add(scopedStopId);
            // intern zone IDs to save memory
            fareZoneForStop.add(stop.zone_id);
            parentStationIdForStop.add(stop.parent_station);
            stopForIndex.add(stop);
            if (stop.wheelchair_boarding != null && stop.wheelchair_boarding.trim().equals("1")) {
                stopsWheelchair.set(stopIndex);
            }
            if (level == TransitLayer.LoadLevel.FULL) {
                stopNames.add(stop.stop_name);
            }
        }

        // Load service periods, assigning integer codes which will be referenced by trips and patterns.
        TObjectIntMap<String> serviceCodeNumber = new TObjectIntHashMap<>(20, 0.5f, -1);
        gtfs.services.forEach((serviceId, service) -> {
            int serviceIndex = services.size();
            services.add(service);
            serviceCodeNumber.put(serviceId, serviceIndex);
            LOG.debug("Service {} has ID {}", serviceIndex, serviceId);
        });

        LOG.info("Creating trip patterns and schedules.");

        // These are temporary maps used only for grouping purposes.
        Map<String, TripPattern> tripPatternForPatternId = new HashMap<>();
        Multimap<String, TripSchedule> tripsForBlock = HashMultimap.create();

        // Keyed with unscoped route_id, which is fine as this is for a single GTFS feed
        TObjectIntMap<String> routeIndexForRoute = new TObjectIntHashMap<>();
        int nTripsAdded = 0;
        int nZeroDurationHops = 0;
        TRIPS: for (String tripId : gtfs.trips.keySet()) {
            Trip trip = gtfs.trips.get(tripId);
            Route route = gtfs.routes.get(trip.route_id);
            // Construct the stop pattern and schedule for this trip.
            String scopedRouteId = String.join(":", gtfs.feedId, trip.route_id);
            TIntList arrivals = new TIntArrayList(TYPICAL_NUMBER_OF_STOPS_PER_TRIP);
            TIntList departures = new TIntArrayList(TYPICAL_NUMBER_OF_STOPS_PER_TRIP);
            TIntList stopSequences = new TIntArrayList(TYPICAL_NUMBER_OF_STOPS_PER_TRIP);

            int previousDeparture = Integer.MIN_VALUE;

            int nStops = 0;

            Iterable<StopTime> stopTimes;

            try {
                stopTimes = gtfs.getInterpolatedStopTimesForTrip(tripId);
            } catch (GTFSFeed.FirstAndLastStopsDoNotHaveTimes e) {
                LOG.warn("First and last stops do not both have times specified on trip {} on route {}, skipping this as interpolation is impossible", trip.trip_id, trip.route_id);
                continue TRIPS;
            }

            for (StopTime st : stopTimes) {
                arrivals.add(st.arrival_time);
                departures.add(st.departure_time);
                stopSequences.add(st.stop_sequence);

                if (previousDeparture > st.arrival_time || st.arrival_time > st.departure_time) {
                    LOG.warn("Negative-time travel at stop {} on trip {} on route {}, skipping this trip as it will wreak havoc with routing", st.stop_id, trip.trip_id, trip.route_id);
                    continue TRIPS;
                }

                if (previousDeparture == st.arrival_time) { //Teleportation: arrive at downstream stop immediately after departing upstream
                    //often the result of a stop_times input with time values rounded to the nearest minute.
                    //TODO check if the distance of the hop is reasonably traveled in less than 60 seconds, which may vary by mode.
                    nZeroDurationHops++;
                }

                previousDeparture = st.departure_time;

                nStops++;
            }

            if (nStops == 0) {
                LOG.warn("Trip {} on route {} {} has no stops, it will not be used", trip.trip_id, trip.route_id, route.route_short_name);
                continue;
            }

            String patternId = gtfs.patternForTrip.get(tripId);

            TripPattern tripPattern = tripPatternForPatternId.get(patternId);
            if (tripPattern == null) {
                tripPattern = new TripPattern(String.format("%s:%s", gtfs.feedId, route.route_id), stopTimes, indexForUnscopedStopId);

                // if we haven't seen the route yet _from this feed_ (as IDs are only feed-unique)
                // create it.
                if (level == TransitLayer.LoadLevel.FULL) {
                    if (!routeIndexForRoute.containsKey(trip.route_id)) {
                        int routeIndex = routes.size();
                        RouteInfo ri = new RouteInfo(route, gtfs.agency.get(route.agency_id));
                        routes.add(ri);
                        routeIndexForRoute.put(trip.route_id, routeIndex);
                    }

                    tripPattern.routeIndex = routeIndexForRoute.get(trip.route_id);

                    if (trip.shape_id != null && SAVE_SHAPES) {
                        Shape shape = gtfs.getShape(trip.shape_id);
                        if (shape == null) LOG.warn("Shape {} for trip {} was missing", trip.shape_id, trip.trip_id);
                        else {
                            // TODO this will not work if some trips in the pattern don't have shapes
                            tripPattern.shape = shape.geometry;

                            // project stops onto shape
                            boolean stopsHaveShapeDistTraveled = StreamSupport.stream(stopTimes.spliterator(), false)
                                    .noneMatch(st -> Double.isNaN(st.shape_dist_traveled));
                            boolean shapePointsHaveDistTraveled = DoubleStream.of(shape.shape_dist_traveled)
                                    .noneMatch(Double::isNaN);

                            LinearLocation[] locations;

                            if (stopsHaveShapeDistTraveled && shapePointsHaveDistTraveled) {
                                // create linear locations from dist traveled
                                locations = StreamSupport.stream(stopTimes.spliterator(), false)
                                        .map(st -> {
                                            double dist = st.shape_dist_traveled;

                                            int segment = 0;

                                            while (segment < shape.shape_dist_traveled.length - 2 &&
                                                    dist > shape.shape_dist_traveled[segment + 1]
                                            ) segment++;

                                            double endSegment = shape.shape_dist_traveled[segment + 1];
                                            double beginSegment = shape.shape_dist_traveled[segment];
                                            double proportion = (dist - beginSegment) / (endSegment - beginSegment);

                                            return new LinearLocation(segment, proportion);
                                        }).toArray(LinearLocation[]::new);
                            } else {
                                // naive snapping
                                LocationIndexedLineInLocalCoordinateSystem line =
                                        new LocationIndexedLineInLocalCoordinateSystem(shape.geometry.getCoordinates());

                                locations = StreamSupport.stream(stopTimes.spliterator(), false)
                                        .map(st -> {
                                            Stop stop = gtfs.stops.get(st.stop_id);
                                            return line.project(new Coordinate(stop.stop_lon, stop.stop_lat));
                                        })
                                        .toArray(LinearLocation[]::new);
                            }

                            tripPattern.stopShapeSegment = new int[locations.length];
                            tripPattern.stopShapeFraction = new float[locations.length];

                            for (int i = 0; i < locations.length; i++) {
                                tripPattern.stopShapeSegment[i] = locations[i].getSegmentIndex();
                                tripPattern.stopShapeFraction[i] = (float) locations[i].getSegmentFraction();
                            }
                        }
                    }
                }

                tripPatternForPatternId.put(patternId, tripPattern);
                tripPattern.originalId = tripPatterns.size();
                tripPatterns.add(tripPattern);
            }
            tripPattern.setOrVerifyDirection(trip.direction_id);
            int serviceCode = serviceCodeNumber.get(trip.service_id);

            // TODO there's no reason why we can't just filter trips like this, correct?
            // TODO this means that invalid trips still have empty patterns created
            Collection<Frequency> frequencies = gtfs.getFrequencies(trip.trip_id);
            TripSchedule tripSchedule = TripSchedule.create(trip, arrivals.toArray(), departures.toArray(), frequencies, stopSequences.toArray(), serviceCode);
            if (tripSchedule == null) continue;

            tripPattern.addTrip(tripSchedule);

            this.hasFrequencies = this.hasFrequencies || tripSchedule.headwaySeconds != null;
            this.hasSchedules = this.hasSchedules || tripSchedule.headwaySeconds == null;

            nTripsAdded += 1;
            // Record which block this trip belongs to, if any.
            if ( ! Strings.isNullOrEmpty(trip.block_id)) {
                tripsForBlock.put(trip.block_id, tripSchedule);
            }
        }
        LOG.info("Done creating {} trips on {} patterns.", nTripsAdded, tripPatternForPatternId.size());

        LOG.info("{} zero-duration hops found.", nZeroDurationHops);

        LOG.info("Chaining trips together according to blocks to model interlining...");
        // Chain together trips served by the same vehicle that allow transfers by simply staying on board.
        // Elsewhere this is done by grouping by (serviceId, blockId) but this is not supported by the spec.
        // Discussion started on gtfs-changes.
        tripsForBlock.asMap().forEach((blockId, trips) -> {
            TripSchedule[] schedules = trips.toArray(new TripSchedule[trips.size()]);
            Arrays.sort(schedules); // Sorts on first departure time
            for (int i = 0; i < schedules.length - 1; i++) {
                schedules[i].chainTo(schedules[i + 1]);
            }
        });
        LOG.info("Done chaining trips together according to blocks.");

        LOG.info("Sorting trips on each pattern");
        for (TripPattern tripPattern : tripPatternForPatternId.values()) {
            Collections.sort(tripPattern.tripSchedules);
        }
        LOG.info("done sorting");

        LOG.info("Finding the approximate center of the transport network...");
        findCenter(gtfs.stops.values());

        //Set transportNetwork timezone
        //If there are no agencies (which is strange) it is GMT
        //Otherwise it is set to first valid agency timezone and warning is shown if agencies have different timezones
        if (gtfs.agency.size() == 0) {
            timeZone = ZoneId.of("GMT");
            LOG.warn("graph contains no agencies; API request times will be interpreted as GMT.");
        } else {
            for (Agency agency : gtfs.agency.values()) {
                if (agency.agency_timezone == null) {
                    LOG.warn("Agency {} is without timezone", agency.agency_name);
                    continue;
                }
                ZoneId tz;
                try {
                    tz = ZoneId.of(agency.agency_timezone);
                } catch (ZoneRulesException z) {
                    LOG.error("Agency {} in GTFS with timezone '{}' wasn't found in timezone database reason: {}", agency.agency_name, agency.agency_timezone, z.getMessage());
                    //timezone will be set to GMT if it is still empty after for loop
                    continue;
                } catch (DateTimeException dt) {
                    LOG.error("Agency {} in GTFS has timezone in wrong format:'{}'. Expected format: area/city ", agency.agency_name, agency.agency_timezone);
                    //timezone will be set to GMT if it is still empty after for loop
                    continue;
                }
                //First time setting timezone
                if (timeZone == null) {
                    LOG.info("TransportNetwork time zone set to {} from agency '{}' and agency_timezone:{}", tz,
                            agency.agency_name, agency.agency_timezone);
                    timeZone = tz;
                } else if (!timeZone.equals(tz)) {
                    LOG.error("agency time zone {} differs from TransportNetwork time zone: {}. This will be problematic.", tz,
                            timeZone);
                }
            }

            //This can only happen if all agencies have empty timezones
            if (timeZone == null) {
                timeZone = ZoneId.of("GMT");
                LOG.warn(
                        "No agency in graph had valid timezone; API request times will be interpreted as GMT.");
            }
        }

        if (level == TransitLayer.LoadLevel.FULL) {
            this.fares = new HashMap<>(gtfs.fares);
        }

        // Will be useful in naming patterns.
//        LOG.info("Finding topology of each route/direction...");
//        Multimap<T2<String, Integer>, TripPattern> patternsForRouteDirection = HashMultimap.create();
//        tripPatterns.forEach(tp -> patternsForRouteDirection.put(new T2(tp.routeId, tp.directionId), tp));
//        for (T2<String, Integer> routeAndDirection : patternsForRouteDirection.keySet()) {
//            RouteTopology topology = new RouteTopology(routeAndDirection.first, routeAndDirection.second, patternsForRouteDirection.get(routeAndDirection));
//        }

    }

    // The median of all stopTimes would be best but that involves sorting a huge list of numbers.
    // So we just use the mean of all stops for now.
    private void findCenter (Collection<Stop> stops) {
        double lonSum = 0;
        double latSum = 0;
        for (Stop stop : stops) {
            latSum += stop.stop_lat;
            lonSum += stop.stop_lon;
        }
        // Stops is a HashMap so size() is fast. If it ever becomes a MapDB BTree, we may want to do this differently.
        centerLat = latSum / stops.size();
        centerLon = lonSum / stops.size();
    }
}
