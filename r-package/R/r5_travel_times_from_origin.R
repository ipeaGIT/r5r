#' Title
#'
#' @description description
#'
#'
#' @param r5_core a rJava object to connect with R5 routing engine
#' @param fromId 99999999
#' @param fromLat 99999999
#' @param fromLon 99999999
#' @param destinations 99999999
#' @param direct_modes 99999999
#' @param transit_modes 99999999
#' @param trip_date 99999999
#' @param departure_time 99999999
#' @param max_street_time 99999999
#' @param max_trip_duration 99999999
#'
#' @return
#' @family routing
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata", package = "r5r")
#' r5_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
#'
#' # input
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <-"BUS"
#' departure_time <- "14:00:00"
#' trip_date <- "2019-05-20"
#' street_time = 15L
#' max_street_time = 30L
#' max_trip_duration = 300L
#'
#' df <- multiple_detailed_itineraries( r5_core = r5_core,
#'                           origins = points,
#'                           destinations = points,
#'                           trip_date = trip_date,
#'                           departure_time = departure_time,
#'                           direct_modes = direct_modes,
#'                           transit_modes = transit_modes,
#'                           max_street_time = max_street_time,
#'                           max_trip_duration = max_trip_duration
#'                           )
#'
#' }
#' @export

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
  # travel_times$fromId = fromId;
  # travel_times$fromLat = fromLat;
  # travel_times$fromLon = fromLon;
  travel_times$direct_modes = direct_modes;
  travel_times$transit_modes = transit_modes;

  # travel_times <- travel_times %>%
  #   filter(travel_time <= max_trip_duration) %>%
  #   select(fromId, fromLat, fromLon,
  #          toId = id, toLat = lat, toLon=lon,
  #          direct_modes, transit_modes, travel_time)

  return(travel_times)
}
