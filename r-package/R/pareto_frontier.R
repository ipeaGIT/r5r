#' Calculate travel time and monetary cost Pareto frontier
#'
#' Fast computation of travel time and monetary cost Pareto frontier between
#' origin and destination pairs.
#'
#' @template r5r_core
#' @template common_arguments
#' @template time_window_related_args
#' @template fare_structure
#' @template verbose
#' @param percentiles An integer vector (max length of 5). Specifies the
#'   percentile to use when returning travel time estimates within the given
#'   time window. Please note that this parameter is applied to the travel time
#'   estimates only (e.g. if the 25th percentile is specified, and the output
#'   between A and B is 15 minutes and 10 dollars, 25% of all trips cheaper
#'   than 10 dollars taken between these points are shorter than 15 minutes).
#'   Defaults to 50, returning the median travel time. If a vector with length
#'   bigger than 1 is passed, the output contains an additional column that
#'   specifies the percentile of each travel time and monetary cost
#'   combination. Due to upstream restrictions, only 5 percentiles can be
#'   specified at a time. For more details, please see R5 documentation at
#'   <https://docs.conveyal.com/analysis/methodology#accounting-for-variability>.
#' @param fare_cutoffs A numeric vector. The monetary cutoffs that
#'   should be considered when calculating the Pareto frontier. Most of the
#'   time you'll want this parameter to be the combination of all possible
#'   fares listed in you `fare_structure`. Choosing a coarse distribution of
#'   cutoffs may result in many different trips falling within the same cutoff.
#'   For example, if you have two different routes in your GTFS, one costing $3
#'   and the other costing $4, and you set this parameter to `5`, the output
#'   will tell you the fastest trips that costed up to $5, but you won't be
#'   able to identify which route was used to complete such trips. In this
#'   case, it would be more beneficial to set the parameter as `c(3, 4)` (you
#'   could also specify combinations of such values, such as 6, 7, 8 and so on,
#'   because a transit user could hypothetically benefit from making transfers
#'   between the available routes).
#'
#' @return A `data.table` with the travel time and monetary cost Pareto frontier
#'   between the specified origins and destinations. An additional column
#'   identifying the travel time percentile is present if more than one value
#'   was passed to `percentiles`. Origin and destination pairs whose trips
#'   couldn't be completed within the maximum travel time using less money than
#'   the specified monetary cutoffs are not returned in the `data.table`. If
#'   `output_dir` is not `NULL`, the function returns the path specified in
#'   that parameter, in which the `.csv` files containing the results are
#'   saved.
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
#'   fare_cutoffs = c(4.5, 4.8, 9, 9.3, 9.6)
#' )
#' head(pf)
#'
#' stop_r5(r5r_core)
#' @export
pareto_frontier <- function(r5r_core,
                            origins,
                            destinations,
                            mode = c("WALK", "TRANSIT"),
                            mode_egress = "WALK",
                            departure_datetime = Sys.time(),
                            time_window = 10L,
                            percentiles = 50L,
                            max_walk_time = Inf,
                            max_bike_time = Inf,
                            max_car_time = Inf,
                            max_trip_duration = 120L,
                            fare_structure = NULL,
                            fare_cutoffs = -1L,
                            walk_speed = 3.6,
                            bike_speed = 12,
                            max_rides = 3,
                            max_lts = 2,
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

  # check inputs and set r5r options --------------------------------------

  checkmate::assert_class(r5r_core, "jobjRef")

  origins <- assign_points_input(origins, "origins")
  destinations <- assign_points_input(destinations, "destinations")
  mode_list <- assign_mode(mode, mode_egress)
  departure <- assign_departure(departure_datetime)

  # check availability of transit services on the selected date
  if (mode_list$transit_mode %like% 'TRANSIT|TRAM|SUBWAY|RAIL|BUS|CABLE_CAR|GONDOLA|FUNICULAR') {
    check_transit_availability_on_date(r5r_core, departure_date = departure$date)
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

  set_time_window(r5r_core, time_window)
  set_percentiles(r5r_core, percentiles)
  set_monte_carlo_draws(r5r_core, 1, time_window)
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")
  set_max_rides(r5r_core, max_rides)
  set_max_lts(r5r_core, max_lts)
  set_n_threads(r5r_core, n_threads)
  set_verbose(r5r_core, verbose)
  set_progress(r5r_core, progress)
  set_fare_structure(r5r_core, fare_structure)
  set_output_dir(r5r_core, output_dir)
  set_fare_cutoffs(r5r_core, fare_cutoffs)

  # call r5r_core method and process result -------------------------------

  frontier <- r5r_core$paretoFrontier(
    origins$id,
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
    max_car_time,
    max_trip_duration
  )

  if (!verbose & progress) cat("Preparing final output...", file = stderr())

  frontier <- java_to_dt(frontier)

  if (nrow(frontier) > 0) {
    # replace travel-times of nonviable trips with NAs
    frontier[travel_time > max_trip_duration, travel_time := NA_integer_]
  }

  if (!verbose & progress) cat(" DONE!\n", file = stderr())

  if (!is.null(output_dir)) return(output_dir)
  return(frontier[])
}
