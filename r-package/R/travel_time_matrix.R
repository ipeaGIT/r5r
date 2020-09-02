#' Calculate travel time matrix between origin destination pairs
#'
#' @description Fast computation of travel time estimates between one or
#'              multiple origin destination pairs.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins,destinations a spatial sf POINT object, or a data.frame
#'                containing the columns 'id', 'lon', 'lat'
#' @param mode string. Transport modes allowed for the trips. Defaults to
#'             "WALK". See details for other options.
#' @param departure_datetime POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param max_walk_dist numeric. Maximum walking distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on walking, as
#'                      long as \code{max_trip_duration} is respected.
#' @param max_trip_duration numeric. Maximum trip duration in minutes. Defaults
#'                          to 120 minutes (2 hours).
#' @param walk_speed numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides numeric. The max number of public transport rides allowed in
#'                  the same trip. Defaults to 3.
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#' @param verbose logical. TRUE to show detailed output messages (the default)
#'                or FALSE to show only eventual ERROR messages.
#'
#' @return A data.table with travel time estimates (in minutes) between origin
#' destination pairs by a given transport mode.
#'
#' @details R5 allows for multiple combinations of transport modes. The options
#'          include:
#'
#'   ## Transit modes
#'   TRAM, SUBWAY, RAIL, BUS, FERRY, CABLE_CAR, GONDOLA, FUNICULAR. The option
#'   'TRANSIT' automatically considers all public transport modes available.
#'
#'   ## Non transit modes
#'   WALK, BICYCLE, CAR, BICYCLE_RENT, CAR_PARK
#'
#'
#' @family routing
#' @examples \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata", package = "r5r")
#' r5r_obj <- setup_r5(data_path = data_path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
#'
#' mode <- c("WALK", "TRANSIT")
#' max_walk_dist <- Inf
#' max_trip_duration <- 120L
#' departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
#'                                  format = "%d-%m-%Y %H:%M:%S",
#'                                  tz = "America/Sao_Paulo")
#'
#' # estimate travel time matrix
#' ttm <- travel_time_matrix(r5r_obj,
#'                           origins = points,
#'                           destinations = points,
#'                           mode,
#'                           departure_datetime,
#'                           max_walk_dist,
#'                           max_trip_duration)
#'
#' stop_r5(r5r_obj)
#' rJava::.jgc(R.gc = TRUE)
#'
#' }
#' @export

travel_time_matrix <- function(r5r_core,
                               origins,
                               destinations,
                               mode = "WALK",
                               departure_datetime = Sys.time(),
                               max_walk_dist = Inf,
                               max_trip_duration = 120L,
                               walk_speed = 3.6,
                               bike_speed = 12,
                               max_rides = 3,
                               n_threads = Inf,
                               verbose = TRUE) {


  # set data.table options --------------------------------------------------

  old_options <- options()
  old_dt_threads <- data.table::getDTthreads()

  on.exit({
    options(old_options)
    data.table::setDTthreads(old_dt_threads)
  })

  options(datatable.optimize = Inf)


  # check inputs ------------------------------------------------------------

  # r5r_core
  checkmate::assert_class(r5r_core, "jobjRef")

  # modes
  mode_list <- select_mode(mode)

  # departure time
  departure <- posix_to_string(departure_datetime)

  # max trip duration
  checkmate::assert_numeric(max_trip_duration)
  max_trip_duration <- as.integer(max_trip_duration)

  # max_walking_distance and max_street_time
  max_street_time <- set_max_street_time(max_walk_dist,
                                         walk_speed,
                                         max_trip_duration)

  # origins and destinations
  origins      <- assert_points_input(origins, "origins")
  destinations <- assert_points_input(destinations, "destinations")


  # set r5r_core options ----------------------------------------------------

  # set bike and walk speed
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")

  # set max transfers
  set_max_rides(r5r_core, max_rides)

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)


  # call r5r_core method ----------------------------------------------------

  travel_times <- r5r_core$travelTimeMatrixParallel(origins$id,
                                                    origins$lat,
                                                    origins$lon,
                                                    destinations$id,
                                                    destinations$lat,
                                                    destinations$lon,
                                                    mode_list$direct_modes,
                                                    mode_list$transit_mode,
                                                    mode_list$access_mode,
                                                    mode_list$egress_mode,
                                                    departure$date,
                                                    departure$time,
                                                    max_street_time,
                                                    max_trip_duration)


  # process results ---------------------------------------------------------

  # convert travel_times from java object to data.table
  travel_times <- jdx::convertToR(travel_times)
  travel_times <- data.table::rbindlist(travel_times)

  return(travel_times)

}
