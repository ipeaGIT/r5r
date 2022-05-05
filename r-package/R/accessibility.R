#' Calculate access to opportunities
#'
#' Fast computation of access to opportunities given a selected decay function.
#' See `details` for the available decay functions.
#'
#' @template common_arguments
#' @template time_window_related_args
#' @template fare_calculator_settings
#' @template max_fare
#' @param percentiles An integer vector with length smaller than or equal to 5.
#' Specifies the percentile to use when returning accessibility estimates
#' within the given time window. Please note that this parameter is applied to
#' the travel time estimates that generate the accessibility results, and not
#' to the accessibility distribution itself (i.e. if the 25th percentile is
#' specified, the accessibility is calculated from the 25th percentile travel
#' time, which may or may not be equal to the 25th percentile of the
#' accessibility distribution itself). Defaults to 50, returning the
#' accessibility calculated from the median travel time. If a vector with
#' length bigger than 1 is passed, the output contains an additional column
#' that specifies the percentile of each accessibility estimate. Due to
#' upstream restrictions, only 5 percentiles can be specified at a time. For
#' more details, please see R5 documentation at
#' 'https://docs.conveyal.com/analysis/methodology#accounting-for-variability'.
#' @param decay_function string. Choice of one of the following decay functions:
#'                       'step', 'exponential', 'fixed_exponential', 'linear',
#'                       and 'logistic'. Defaults to 'step', which yields
#'                       cumulative opportunities accessibility metrics.
#'                       More info in `details`.
#' @param cutoffs numeric. Cutoff times in minutes for calculating cumulative
#'                opportunities accessibility when using the 'step decay function'.
#'                This parameter has different effects for each of the other decay
#'                functions: it indicates the 'median' (or inflection point) of
#'                the decay curves in the 'logistic' and 'linear' functions, and
#'                the 'half-life' in the 'exponential' function. It has no effect
#'                when using the 'fixed exponential' function.
#' @param decay_value numeric. Extra parameter to be passed to the selected
#'                `decay_function`.
#'
#' @return A data.table with accessibility estimates for all origin points, by
#' a given transport mode, and per travel time cutoff and percentile.
#'
#' @template decay_functions_section
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template raptor_algorithm_section
#' @details
#'
#' @family routing
#' @examples if (interactive()) {
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path, temp_dir = TRUE)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#'
#' # estimate accessibility
#'   access <- accessibility(r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           opportunities_colnames = "schools",
#'                           mode = "WALK",
#'                           cutoffs = c(25, 30),
#'                           max_trip_duration = 30,
#'                           verbose = FALSE)
#'
#' stop_r5(r5r_core)
#'
#' }
#' @export

accessibility <- function(r5r_core,
                          origins,
                          destinations,
                          opportunities_colnames = "opportunities",
                          mode = "WALK",
                          mode_egress = "WALK",
                          departure_datetime = Sys.time(),
                          time_window = 1L,
                          percentiles = 50L,
                          decay_function = "step",
                          cutoffs = 30L,
                          decay_value = 1.0,
                          fare_calculator_settings = NULL,
                          max_fare = Inf,
                          max_walk_dist = Inf,
                          max_bike_dist = Inf,
                          max_trip_duration = 120L,
                          walk_speed = 3.6,
                          bike_speed = 12,
                          max_rides = 3,
                          max_lts = 2,
                          draws_per_minute = 5L,
                          n_threads = Inf,
                          verbose = TRUE,
                          progress = TRUE) {


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
  mode_list <- select_mode(mode, mode_egress)

  # departure time
  departure <- posix_to_string(departure_datetime)

  # max trip duration
  checkmate::assert_numeric(max_trip_duration)
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

  # opportunities
  checkmate::assert_character(opportunities_colnames)
  checkmate::assert_names(names(destinations), must.include = opportunities_colnames,
                          .var.name = "destinations")

  opportunities_data <- lapply(opportunities_colnames, function(colname) {
    ## check if provided column contains numeric values only
    checkmate::assert_numeric(destinations[[colname]])

    ## convert to Java compatible array
    opp_array <- as.integer(destinations[[colname]])
    opp_array <- rJava::.jarray(opp_array)

    return(opp_array)
  })

  # time window
  checkmate::assert_numeric(time_window)
  time_window <- as.integer(time_window)

  # montecarlo draws per minute
  draws <- time_window * draws_per_minute
  draws <- as.integer(draws)

  # percentiles
  percentiles <- percentiles[1:5]
  percentiles <- percentiles[!is.na(percentiles)]
  checkmate::assert_numeric(percentiles)
  percentiles <- as.integer(percentiles)

  # cutoffs
  checkmate::assert_numeric(cutoffs)
  cutoffs <- as.integer(cutoffs)

  # decay
  decay_list <- assert_decay_function(decay_function, decay_value)

  # set r5r_core options ----------------------------------------------------

  # time window
  r5r_core$setTimeWindowSize(time_window)
  r5r_core$setPercentiles(percentiles)
  r5r_core$setCutoffs(cutoffs)

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

  # configure fare calculator
  set_fare_calculator(r5r_core, fare_calculator_settings)

  # set max fare
  # Inf and NULL values are not allowed in Java,
  # so -1 is used to indicate max_fare is unconstrained
  if (max_fare != Inf) {
    r5r_core$setMaxFare(rJava::.jfloat(max_fare))
  } else {
    r5r_core$setMaxFare(rJava::.jfloat(-1.0))
  }


  # call r5r_core method ----------------------------------------------------

  ## wrap r5r_core inputs in arrays
  ## this helps to simplify the Java code
  from_id_arr <- rJava::.jarray(origins$id)
  from_lat_arr <- rJava::.jarray(origins$lat)
  from_lon_arr <- rJava::.jarray(origins$lon)

  to_id_arr <- rJava::.jarray(destinations$id)
  to_lat_arr <- rJava::.jarray(destinations$lat)
  to_lon_arr <- rJava::.jarray(destinations$lon)


  opportunities_names <- rJava::.jarray(opportunities_colnames)
  opportunities_values <- rJava::.jarray(opportunities_data, "[I")

  accessibility <- r5r_core$accessibility(from_id_arr,
                                          from_lat_arr,
                                          from_lon_arr,
                                          to_id_arr,
                                          to_lat_arr,
                                          to_lon_arr,
                                          opportunities_names,
                                          opportunities_values,
                                          decay_list$fun,
                                          decay_list$value,
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
  accessibility <- java_to_dt(accessibility)
  if (!verbose & progress) { cat(" DONE!\n") }

  return(accessibility)
}
