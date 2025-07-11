#' Calculate access to opportunities
#'
#' Fast computation of access to opportunities given a selected decay function.
#'
#' @template r5r_network
#' @template r5r_core
#' @template common_arguments
#' @template time_window_related_args
#' @template draws_per_minute
#' @template fare_structure
#' @template max_fare
#' @template verbose
#' @param opportunities_colnames A character vector. The names of the columns
#'   in the `destinations` input that tells the number of opportunities in each
#'   location. Several different column names can be passed, in which case the
#'   accessibility to each kind of opportunity will be calculated.
#' @param percentiles An integer vector (max length of 5). Specifies the
#'   percentile to use when returning accessibility estimates within the given
#'   time window. Please note that this parameter is applied to the travel time
#'   estimates that generate the accessibility results, and not to the
#'   accessibility distribution itself (i.e. if the 25th percentile is
#'   specified, the accessibility is calculated from the 25th percentile travel
#'   time, which may or may not be equal to the 25th percentile of the
#'   accessibility distribution itself). Defaults to 50, returning the
#'   accessibility calculated from the median travel time. If a vector with
#'   length bigger than 1 is passed, the output contains an additional column
#'   that specifies the percentile of each accessibility estimate. Due to
#'   upstream restrictions, only 5 percentiles can be specified at a time. For
#'   more details, please see `R5` documentation at
#'   <https://docs.conveyal.com/analysis/methodology#accounting-for-variability>.
#' @param decay_function A string. Which decay function to use when calculating
#'   accessibility. One of `step`, `exponential`, `fixed_exponential`, `linear`
#'   or `logistic`. Defaults to `step`, which is equivalent to a cumulative
#'   opportunities measure. Please see the details to understand how each
#'   alternative works and how they relate to the `cutoffs` and `decay_value`
#'   parameters.
#' @param cutoffs A numeric vector (maximum length of 12). This parameter has
#'   different effects for each decay function: it indicates the cutoff times
#'   in minutes when calculating cumulative opportunities accessibility with
#'   the `step` function, the median (or inflection point) of the decay curves
#'   in the `logistic` and `linear` functions, and the half-life in the
#'   `exponential` function. It has no effect when using the
#'   `fixed_exponential` function.
#' @param decay_value A number. Extra parameter to be passed to the selected
#'   `decay_function`. Has no effects when `decay_function` is either `step` or
#'   `exponential`.
#'
#' @return A `data.table` with accessibility estimates for all origin points.
#'   This `data.table` contain columns listing the origin id, the type of
#'   opportunities to which accessibility was calculated, the travel time
#'   percentile considered in the accessibility estimate and the specified
#'   cutoff values (except in when `decay_function` is `fixed_exponential`, in
#'   which case the `cutoff` parameter is not used). If `output_dir` is not
#'   `NULL`, the function returns the path specified in that parameter, in
#'   which the `.csv` files containing the results are saved.
#'
#' @template decay_functions_section
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template raptor_algorithm_section
#'
#' @family accessibility
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(data_path)
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[1:5, ]
#'
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' access <- accessibility(
#'   r5r_network ,
#'   origins = points,
#'   destinations = points,
#'   opportunities_colnames = "schools",
#'   mode = "WALK",
#'   departure_datetime = departure_datetime,
#'   decay_function = "step",
#'   cutoffs = 30,
#'   max_trip_duration = 30
#' )
#' head(access)
#'
#' # using a different decay function
#' access <- accessibility(
#'   r5r_network ,
#'   origins = points,
#'   destinations = points,
#'   opportunities_colnames = "schools",
#'   mode = "WALK",
#'   departure_datetime = departure_datetime,
#'   decay_function = "logistic",
#'   cutoffs = 30,
#'   decay_value = 1,
#'   max_trip_duration = 30
#' )
#' head(access)
#'
#' # using several cutoff values
#' access <- accessibility(
#'   r5r_network ,
#'   origins = points,
#'   destinations = points,
#'   opportunities_colnames = "schools",
#'   mode = "WALK",
#'   departure_datetime = departure_datetime,
#'   decay_function = "step",
#'   cutoffs = c(15, 30),
#'   max_trip_duration = 30
#' )
#' head(access)
#'
#' # calculating access to different types of opportunities
#' access <- accessibility(
#'   r5r_network ,
#'   origins = points,
#'   destinations = points,
#'   opportunities_colnames = c("schools", "healthcare"),
#'   mode = "WALK",
#'   departure_datetime = departure_datetime,
#'   decay_function = "step",
#'   cutoffs = 30,
#'   max_trip_duration = 30
#' )
#' head(access)
#'
#' stop_r5(r5r_network )
#'
#' @export
accessibility <- function(r5r_network,
                          r5r_core = deprecated(),
                          origins,
                          destinations,
                          opportunities_colnames = "opportunities",
                          mode = "WALK",
                          mode_egress = "WALK",
                          departure_datetime = Sys.time(),
                          time_window = 10L,
                          percentiles = 50L,
                          decay_function = "step",
                          cutoffs = NULL,
                          decay_value = NULL,
                          fare_structure = NULL,
                          max_fare = Inf,
                          max_walk_time = Inf,
                          max_bike_time = Inf,
                          max_car_time = Inf,
                          max_trip_duration = 120L,
                          walk_speed = 3.6,
                          bike_speed = 12,
                          max_rides = 3,
                          max_lts = 2,
                          draws_per_minute = 5L,
                          n_threads = Inf,
                          verbose = FALSE,
                          progress = FALSE,
                          output_dir = NULL) {

  # deprecating r5r_core --------------------------------------
  if (lifecycle::is_present(r5r_core)) {

    cli::cli_warn(c(
      "!" = "The `r5r_core` argument is deprecated as of r5r v2.3.0.",
      "i" = "Please use the `r5r_network` argument instead."
    ))

    r5r_network <- r5r_core
  }

  old_options <- options(datatable.optimize = Inf)
  on.exit(options(old_options), add = TRUE)

  old_dt_threads <- data.table::getDTthreads()
  dt_threads <- ifelse(is.infinite(n_threads), 0, n_threads)
  data.table::setDTthreads(dt_threads)
  on.exit(data.table::setDTthreads(old_dt_threads), add = TRUE)

  # check inputs and set r5r options --------------------------------------

  checkmate::assert_class(r5r_network, "r5r_network")
  r5r_network <- r5r_network@jcore

  origins <- assign_points_input(origins, "origins")
  destinations <- assign_points_input(destinations, "destinations")
  opportunities <- assign_opportunities(destinations, opportunities_colnames)
  mode_list <- assign_mode(mode, mode_egress)
  departure <- assign_departure(departure_datetime)

  # check availability of transit services on the selected date
  if (mode_list$transit_mode %like% 'TRANSIT|TRAM|SUBWAY|RAIL|BUS|CABLE_CAR|GONDOLA|FUNICULAR') {
    check_transit_availability_on_date(r5r_network, departure_date = departure$date)
  }

  # cap trip duration with cutoffs
  set_cutoffs(r5r_network, cutoffs, decay_function)
  checkmate::assert_number(max_trip_duration, lower = 1, finite = TRUE)

  if(!is.null(cutoffs)){
    max_trip_duration <- ifelse(max_trip_duration > max(cutoffs), max(cutoffs), max_trip_duration)

    if(max_trip_duration < max(cutoffs)){stop("'max_trip_duration' cannot be shorter than 'max(cutoffs)'")}
  }

  max_walk_time <- assign_max_street_time(
    max_walk_time,
    walk_speed,
    max_trip_duration,
    "walk"
  )
  max_bike_time <- assign_max_street_time(
    max_bike_time,
    bike_speed,
    max_trip_duration,
    "bike"
  )
  max_car_time <- assign_max_street_time(
    max_car_time,
    8, # 8 km/h, R5's default.
    max_trip_duration,
    "car"
  )
  max_trip_duration <- assign_max_trip_duration(
    max_trip_duration,
    mode_list,
    max_walk_time,
    max_bike_time
  )


  decay_list <- assign_decay_function(decay_function, decay_value)

  set_time_window(r5r_network, time_window)
  set_percentiles(r5r_network, percentiles)
  set_monte_carlo_draws(r5r_network, draws_per_minute, time_window)
  set_speed(r5r_network, walk_speed, "walk")
  set_speed(r5r_network, bike_speed, "bike")
  set_max_rides(r5r_network, max_rides)
  set_max_lts(r5r_network, max_lts)
  set_n_threads(r5r_network, n_threads)
  set_verbose(r5r_network, verbose)
  set_progress(r5r_network, progress)
  set_fare_structure(r5r_network, fare_structure)
  set_max_fare(r5r_network, max_fare)
  set_output_dir(r5r_network, output_dir)

  # call r5r_network method and process results ------------------------------

  # wrap r5r_network inputs in arrays (this helps to simplify the Java code)

  from_id_arr <- rJava::.jarray(origins$id)
  from_lat_arr <- rJava::.jarray(origins$lat)
  from_lon_arr <- rJava::.jarray(origins$lon)

  to_id_arr <- rJava::.jarray(destinations$id)
  to_lat_arr <- rJava::.jarray(destinations$lat)
  to_lon_arr <- rJava::.jarray(destinations$lon)

  opportunities_names <- rJava::.jarray(opportunities_colnames)
  opportunities_values <- rJava::.jarray(opportunities, "[I")

  accessibility <- r5r_network$accessibility(
    from_id_arr,
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
    max_car_time,
    max_trip_duration
  )

  if (!verbose & progress) cat("Preparing final output...", file = stderr())

  accessibility <- java_to_dt(accessibility)

  if (decay_function == "fixed_exponential") accessibility[, cutoff := NULL]

  if (!verbose & progress) cat(" DONE!\n", file = stderr())

  if (!is.null(output_dir)) return(output_dir)
  return(accessibility[])
}
