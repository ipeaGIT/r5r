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
#' @param time_window numeric. Time window in minutes for which r5r will
#'                    calculate multiple travel time matrices departing each
#'                    minute. By default, the number of simulations is 5 times
#'                    the size of 'time_window' set by the user. Defaults window
#'                    size to '1', the function only considers 5 departure times.
#'                    This parameter is only used with frequency-based GTFS files.
#'                    See details for further information.
#' @param percentiles numeric vector. Defaults to '50', returning the median
#'                    travel time for a given time_window. If a numeric vector is passed,
#'                    for example c(25, 50, 75), the function will return
#'                    additional columns with the travel times within percentiles
#'                    of trips. For example, if the 25 percentile of trips between
#'                    A and B is 15 minutes, this means that 25% of all trips
#'                    taken between A and B within the set time window are shorter
#'                    than 15 minutes. For more details, see R5 documentation at
#'                    'https://docs.conveyal.com/analysis/methodology#accounting-for-variability'
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
#' # Routing algorithm:
#' The travel_time_matrix function uses an R5-specific extension to the RAPTOR
#' routing algorithm (see Conway et al., 2017). This RAPTOR extension uses a
#' systematic sample of one departure per minute over the time window set by the
#' user in the 'time_window' parameter. A detailed description of base RAPTOR
#' can be found in Delling et al (2015).
#' - Conway, M. W., Byrd, A., & van der Linden, M. (2017). Evidence-based transit
#'  and land use sketch planning using interactive accessibility methods on
#'  combined schedule and headway-based networks. Transportation Research Record,
#'  2653(1), 45-53.
#'  - Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public transit
#'  routing. Transportation Science, 49(3), 591-604.
#'
#' @family routing
#' @examples \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/spo", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))[1:5,]
#'
#' departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
#'
#' # estimate travel time matrix
#' ttm <- travel_time_matrix(r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           mode = c("WALK", "TRANSIT"),
#'                           departure_datetime = departure_datetime,
#'                           max_walk_dist = Inf,
#'                           max_trip_duration = 120L)
#'
#' stop_r5(r5r_core)
#'
#' }
#' @export

travel_time_matrix <- function(r5r_core,
                               origins,
                               destinations,
                               mode = "WALK",
                               departure_datetime = Sys.time(),
                               time_window = 1L,
                               percentiles = 50L,
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


  # time window
  checkmate::assert_numeric(time_window)
  time_window <- as.integer(time_window)
  draws <- time_window *5
  draws <- as.integer(draws)

  # percentiles
  checkmate::assert_numeric(percentiles)
  percentiles <- as.integer(percentiles)


  # set r5r_core options ----------------------------------------------------

  # time window
  r5r_core$setTimeWindowSize(time_window)
  r5r_core$setPercentiles(percentiles)
  r5r_core$setNumberOfMonteCarloDraws(draws)

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

  # convert eventual list columns to integer
  for(j1 in seq_along(travel_times)) {
    cl1 <- class(travel_times[[j1]])
    if(cl1 == 'list') {
      data.table::set(travel_times, i = NULL, j = j1, value = unlist(travel_times[[j1]]))}
    }

  # replace travel-times of inviable trips with NAs
  for(j in seq(from = 3, to = length(travel_times))){
    data.table::set(travel_times, i=which(travel_times[[j]]>max_trip_duration), j=j, value=NA_integer_)
    }

return(travel_times)
}
