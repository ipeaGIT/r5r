#' Title
#'
#' @param r5r_core
#' @param origins
#' @param destinations
#' @param direct_modes
#' @param transit_modes
#' @param trip_date
#' @param departure_time
#' @param max_street_time
#' @param max_trip_duration
#'
#' @return
#' @export
#'
#' @examples
r5_travel_time_matrix <- function(r5r_core, origins, destinations,
                                        direct_modes, transit_modes, trip_date, departure_time,
                                        max_street_time, max_trip_duration) {
  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(direct_modes, collapse = ";")
  transit_modes <- paste0(transit_modes, collapse = ";")

  # Call to method inside R5RCore object
  travel_times <- r5r_core$travelTimeMatrixParallel(origins$id, origins$lat, origins$lon,
                                                    destinations$id, destinations$lat, destinations$lon,
                                                    direct_modes, transit_modes, trip_date, departure_time,
                                                    max_street_time, max_trip_duration)

  # travel_times <- rJava::.jcall(r5r_core, returnSig = "V", method = "travelTimesFromOrigin",
  #                               fromId, fromLat, fromLon, jdx::convertToJava(destinations),
  #                               direct_modes, transit_modes, trip_date, departure_time,
  #                               max_street_time, max_trip_duration)

  travel_times
  travel_times <- jdx::convertToR(travel_times)
  travel_times <- data.table::rbindlist(travel_times)
  travel_times$direct_modes = direct_modes
  travel_times$transit_modes = transit_modes;

  return(travel_times)
}
