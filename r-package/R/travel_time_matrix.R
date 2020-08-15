#' travel_time_matrix
#'
#' @param r5_core A rJava object to connect with R5 routing engine
#' @param origins
#' @param destinations
#' @param direct_modes
#' @param transit_modes
#' @param trip_date
#' @param departure_time
#' @param max_street_time
#' @param max_trip_duration
#'
#' @return Returns a data.table with travel-time estimates between pairs of
#' origin-destinations
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
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
#'
#'
#' # input
#' trip_date <- "2019-05-20"
#' departure_time <- "14:00:00"
#' street_time = 15L
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <-"BUS"
#' max_street_time = 30L
#' max_trip_duration = 300L
#'
#' travel_time_matrix( origins = from,
#'                        destinations = from,
#'                        r5_core = r5_core,
#'                        trip_date = trip_date,
#'                        departure_time = departure_time,
#'                        direct_modes = direct_modes,
#'                        transit_modes = transit_modes,
#'                        max_street_time = max_street_time,
#'                        max_trip_duration = max_trip_duration
#'                        )
#'
#' }
#' @export

travel_time_matrix <- function( r5_core,
                                origins,
                                destinations,
                                direct_modes,
                                transit_modes,
                                trip_date,
                                departure_time,
                                max_street_time,
                                max_trip_duration){

  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(direct_modes, collapse = ";")
  transit_modes <- paste0(transit_modes, collapse = ";")

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
