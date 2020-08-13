r5_travel_times_from_origin <- function(r5r_core, fromId, fromLat, fromLon, destinations,
                                        direct_modes, transit_modes, trip_date, departure_time,
                                        max_street_time, max_trip_duration) {
  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(direct_modes, collapse = ";")
  transit_modes <- paste0(transit_modes, collapse = ";")

  # Call to method inside R5RCore object
  travel_times <- r5r_core$travelTimesFromOrigin(fromId, fromLat, fromLon,
                                                 destinations$id, destinations$lat, destinations$lon,
                                                 direct_modes, transit_modes, trip_date, departure_time,
                                                 max_street_time, max_trip_duration)

  # travel_times <- rJava::.jcall(r5r_core, returnSig = "V", method = "travelTimesFromOrigin",
  #                               fromId, fromLat, fromLon, jdx::convertToJava(destinations),
  #                               direct_modes, transit_modes, trip_date, departure_time,
  #                               max_street_time, max_trip_duration)

  travel_times <- jdx::convertToR(travel_times)
  travel_times$fromId = fromId;
  travel_times$fromLat = fromLat;
  travel_times$fromLon = fromLon;
  travel_times$direct_modes = direct_modes;
  travel_times$transit_modes = transit_modes;

  travel_times <- travel_times %>%
    filter(travel_time <= max_trip_duration) %>%
    select(fromId, fromLat, fromLon,
           toId = id, toLat = lat, toLon=lon,
           direct_modes, transit_modes, travel_time)

  return(travel_times)
}
