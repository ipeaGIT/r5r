#' Calculate travel time matrix between origin destination pairs
#'
#' @description Fast function to calculate travel time estimates between one or
#'              multiple origin destination pairs.
#'
#' @param r5_core a rJava object to connect with R5 routing engine
#' @param origins a data.frame containing the columns 'id', 'lat', 'lat'
#' @param destinations a data.frame containing the columns 'id', 'lat', 'lat'
#' @param trip_date character string, date in format "yyyy-mm-dd". If working
#'                  with public transport networks, check the GTFS.zip
#'                  (calendar.txt file) for dates with service.
#' @param departure_time character string, time in format "hh:mm:ss"
#' @param direct_modes
#' @param transit_modes
#' @param max_street_time integer,
#' @param max_trip_duration integer, Maximum trip duration in seconds. Defaults
#'                           to 7200 seconds (2 hours).
#'
#' @return A data.table with travel-time estimates (in seconds) between origin
#' destination pairs
#'
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
#' df <- travel_time_matrix( r5_core = r5_core,
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

travel_time_matrix <- function( r5_core,
                                origins,
                                destinations,
                                trip_date,
                                departure_time,
                                direct_modes,
                                transit_modes,
                                max_street_time,
                                max_trip_duration = 7200L){

  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(toupper(direct_modes), collapse = ";")
  transit_modes <- paste0(toupper(transit_modes), collapse = ";")

  # Forcefully cast integer parameters before passing them to Java
  max_street_time = as.integer(max_street_time)
  max_trip_duration = as.integer(max_trip_duration)

  # Call to method inside R5RCore object
  travel_times <- r5_core$travelTimeMatrixParallel(origins$id,
                                                    origins$lat,
                                                    origins$lon,
                                                    destinations$id,
                                                    destinations$lat,
                                                    destinations$lon,
                                                    direct_modes,
                                                    transit_modes,
                                                    trip_date,
                                                    departure_time,
                                                    max_street_time,
                                                    max_trip_duration
                                                    )

  # travel_times <- rJava::.jcall(r5_core, returnSig = "V", method = "travelTimesFromOrigin",
  #                               fromId, fromLat, fromLon, jdx::convertToJava(destinations),
  #                               direct_modes, transit_modes, trip_date, departure_time,
  #                               max_street_time, max_trip_duration)

  travel_times <- jdx::convertToR(travel_times)
  travel_times <- data.table::rbindlist(travel_times)
  travel_times[, direct_modes := direct_modes ]
  travel_times[, transit_modes := transit_modes]

  return(travel_times)
}
