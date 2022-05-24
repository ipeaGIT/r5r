#' Calculate travel time and monetary cost Pareto frontier
#'
#' Fast computation of travel time and monetary cost Pareto frontier between
#' origin and destination pairs.
#'
#' @template r5r_core
#' @template common_arguments
#' @template time_window_related_args
#' @template fare_structure
#' @template max_fare
#' @template verbose
#'
#' @return A `data.table` with the travel time and monetary cost Pareto
#' frontier between the specified origins and destinations. An additional
#' column identifying the travel time percentile is present if more than one
#' value was passed to `percentiles`. Origin and destination pairs whose trips
#' couldn't be completed within the maximum travel time using less money than
#' the specified monetary cutoffs are not returned in the `data.table`. If
#' `output_dir` is not `NULL`, the function returns the path specified in that
#' parameter, in which the `.csv` files containing the results are saved.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template mcraptor_algorithm_section
#'
#' @family routing
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[1:5,]
#'
#' # load fare structure object
#' fare_structure_path <- system.file(
#'   "extdata/poa/fares/fares_poa.zip",
#'   package = "r5r"
#' )
#' fare_structure <- read_fare_structure(fare_structure_path)
#'
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' pf <- pareto_frontier(
#'   r5r_core,
#'   origins = points,
#'   destinations = points,
#'   mode = c("WALK", "TRANSIT"),
#'   departure_datetime = departure_datetime,
#'   fare_structure = fare_structure,
#'   monetary_cost_cutoffs = c(4.5, 4.8, 9, 9.3, 9.6)
#' )
#' head(pf)
#'
#' stop_r5(r5r_core)
#' @export
pareto_itineraries <- function(r5r_core,
                            origins,
                            destinations,
                            mode = c("WALK", "TRANSIT"),
                            mode_egress = "WALK",
                            departure_datetime = Sys.time(),
                            time_window = 1L,
                            percentiles = 50L,
                            max_walk_dist = Inf,
                            max_bike_dist = Inf,
                            max_trip_duration = 120L,
                            fare_structure = NULL,
                            max_fare = Inf,
                            walk_speed = 3.6,
                            bike_speed = 12,
                            max_rides = 3,
                            max_lts = 2,
                            draws_per_minute = 5L,
                            n_threads = Inf,
                            verbose = FALSE,
                            progress = FALSE,
                            output_dir = NULL) {

  old_options <- options(datatable.optimize = Inf)
  on.exit(options(old_options), add = TRUE)

  old_dt_threads <- data.table::getDTthreads()
  dt_threads <- ifelse(is.infinite(n_threads), 0, n_threads)
  data.table::setDTthreads(dt_threads)
  on.exit(data.table::setDTthreads(old_dt_threads), add = TRUE)


  # check inputs ------------------------------------------------------------

  # r5r_core
  checkmate::assert_class(r5r_core, "jobjRef")

  # modes
  mode_list <- select_mode(mode, mode_egress)

  # departure time
  departure <- posix_to_string(departure_datetime)

  # max trip duration
  checkmate::assert_numeric(max_trip_duration, lower=1)
  max_trip_duration <- as.integer(max_trip_duration)

  # max_walking_distance, max_bike_distance, and max_street_time
  max_walk_time <- set_max_street_time(max_walk_dist,
                                       walk_speed,
                                       max_trip_duration)
  max_bike_time <- set_max_street_time(max_bike_dist,
                                       bike_speed,
                                       max_trip_duration)

  # origins and destinations
  origins      <- assert_points_input(origins, "origins")
  destinations <- assert_points_input(destinations, "destinations")

  checkmate::assert_subset("id", names(origins))
  checkmate::assert_subset("id", names(destinations))

  # time window
  checkmate::assert_numeric(time_window, lower=1)
  time_window <- as.integer(time_window)

  # montecarlo draws per minute
  draws <- time_window * draws_per_minute
  draws <- as.integer(draws)

  # percentiles
  if (length(percentiles) > 5) {
    stop("Maximum number of percentiles allowed is 5.")
  }
  percentiles <- percentiles[!is.na(percentiles)]
  checkmate::assert_numeric(percentiles)
  percentiles <- as.integer(percentiles)

  # set r5r_core options ----------------------------------------------------

  if (!is.null(output_dir)) r5r_core$setCsvOutput(output_dir)
  on.exit(r5r_core$setCsvOutput(""), add = TRUE)

  # time window
  r5r_core$setTimeWindowSize(time_window)
  r5r_core$setPercentiles(percentiles)
  r5r_core$setNumberOfMonteCarloDraws(draws)

  # set bike and walk speed
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")

  # set max transfers
  set_max_rides(r5r_core, max_rides)

  # set max lts (level of traffic stress)
  set_max_lts(r5r_core, max_lts)

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)

  # set progress
  set_progress(r5r_core, progress)

  # fare structure
  set_fare_structure(r5r_core, fare_structure)

  # set max fare
  # Inf and NULL values are not allowed in Java,
  # so -1 is used to indicate max_fare is unconstrained
  if (max_fare != Inf) {
    r5r_core$setMaxFare(rJava::.jfloat(max_fare))
  } else {
    r5r_core$setMaxFare(rJava::.jfloat(-1.0))
  }

  # call r5r_core method ----------------------------------------------------

  travel_times <- r5r_core$paretoItineraries(origins$id,
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
                                            max_walk_time,
                                            max_bike_time,
                                            max_trip_duration)


  # process results ---------------------------------------------------------

  # convert travel_times from java object to data.table
  if (!verbose & progress) { cat("Preparing final output...") }

  travel_times <- java_to_dt(travel_times)

  if (!verbose & progress) { cat(" DONE!\n") }

  if (!is.null(output_dir)) return(output_dir)
  return(travel_times)
}
