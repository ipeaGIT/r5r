#' Calculate travel time matrix between origin destination pairs considering a
#' time of arrival
#'
#' Computation of travel time estimates between one or multiple origin
#' destination pairs considering a time of arrival. This function considers a
#' time of arrival set by the user. The function returns the travel time of the
#' trip with the latest departure time that arrives before the arrival time set
#' by the user. If you want to calculate travel times considering a departure
#' time, have a' look at the [travel_time_matrix()] function. This function is a
#' wrapper around [expanded_travel_time_matrix()]. On one hand, this means this
#' the output of this function has more columns (more info) compared the output
#' of [travel_time_matrix()]. On the other hand, this function can be very memory
#' intensive if the user allows for really long max trip duration.
#'
#' @inheritParams expanded_travel_time_matrix
#' @param arrival_datetime A POSIXct object.
#'
#' @return A `data.table` with travel time estimates (in minutes) and the
#'   routes used in each trip between origin and destination pairs, for each
#'   minute of the specified time window. Each set of origin, destination and
#'   departure minute can appear up to N times, where N is the number of Monte
#'   Carlo draws specified in the function arguments (please note that this
#'   only applies when the GTFS feeds that describe the transit network include
#'   a frequencies table, otherwise only a single draw is performed). A pair is
#'   completely absent from the final output if no trips could be completed in
#'   any of the minutes of the time window. If for a single pair trips could be
#'   completed in some of the minutes of the time window, but not for all of
#'   them, the minutes in which trips couldn't be completed will have `NA`
#'   travel time and routes used. If `output_dir` is not `NULL`, the function
#'   returns the path specified in that parameter, in which the `.csv` files
#'   containing the results are saved.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template raptor_algorithm_section
#'
#' @family routing
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(data_path )
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#'
#' arrival_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' # by default only returns the total time between each pair in each minute of
#' # the specified time window
#' arrival_ttm <- arrival_travel_time_matrix(
#'   r5r_network,
#'   origins = points,
#'   destinations = points,
#'   mode = c("WALK", "TRANSIT"),
#'   arrival_datetime = arrival_datetime,
#'   max_trip_duration = 60
#' )
#'
#' head(arrival_ttm)
#'
#' # when breakdown = TRUE the output contains much more information
#' arrival_ttm2 <- arrival_travel_time_matrix(
#'   r5r_network,
#'   origins = points,
#'   destinations = points,
#'   mode = c("WALK", "TRANSIT"),
#'   arrival_datetime = arrival_datetime,
#'   max_trip_duration = 60,
#'   breakdown = TRUE
#' )
#'
#' head(arrival_ttm2)
#'
#' stop_r5(r5r_network)
#' @export
arrival_travel_time_matrix <- function(r5r_network,
                                       r5r_core = deprecated(),
                                       origins,
                                       destinations,
                                       mode = "WALK",
                                       mode_egress = "WALK",
                                       arrival_datetime = Sys.time(),
                                       breakdown = FALSE,
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
  checkmate::assert_number(n_threads, lower = 1)
  old_dt_threads <- data.table::getDTthreads()
  dt_threads <- ifelse(is.infinite(n_threads), 0, n_threads)
  data.table::setDTthreads(dt_threads)
  on.exit(data.table::setDTthreads(old_dt_threads), add = TRUE)

  # check inputs and set r5r options --------------------------------------

  checkmate::assert_class(r5r_network, "r5r_network")
  r5r_network <- r5r_network@jcore

  origins <- assign_points_input(origins, "origins")
  destinations <- assign_points_input(destinations, "destinations")
  mode_list <- assign_mode(mode, mode_egress)

  # calculate departure datetime
  departure_datetime <- arrival_datetime - as.difftime(max_trip_duration, units = "mins")
  departure <- assign_departure(departure_datetime)

  # in direct modes reverse origin/destination to take advantage of R5's One to Many algorithm
  data_path <- r5r_network$getDataPath()
  res <- reverse_if_direct_mode(origins, destinations, mode_list, data_path)
  origins <- res$origins
  destinations <- res$destinations

  # check availability of transit services on the selected date
  if (mode_list$transit_mode %like% 'TRANSIT|TRAM|SUBWAY|RAIL|BUS|CABLE_CAR|GONDOLA|FUNICULAR') {
    check_transit_availability_on_date(r5r_network, departure_date = departure$date)
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

  set_time_window(r5r_network, max_trip_duration)
  set_monte_carlo_draws(r5r_network, draws_per_minute, max_trip_duration)
  set_speed(r5r_network, walk_speed, "walk")
  set_speed(r5r_network, bike_speed, "bike")
  set_max_rides(r5r_network, max_rides)
  set_max_lts(r5r_network, max_lts)
  set_n_threads(r5r_network, n_threads)
  set_verbose(r5r_network, verbose)
  set_progress(r5r_network, progress)
  set_output_dir(r5r_network, output_dir)
  set_expanded_travel_times(r5r_network, TRUE)
  r5r_network$setSearchType("ARRIVE_BY")
  set_breakdown(r5r_network, breakdown)
  set_fare_structure(r5r_network, NULL)

  # call r5r_network method and process result -------------------------------

  travel_times <- r5r_network$travelTimeMatrix(
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

  travel_times <- java_to_dt(travel_times)

  # replace travel-times of non-viable trips with NAs
  # if breakdown is TRUE, there are more columns in the output

  if (nrow(travel_times) > 0) {
    if (breakdown) {
      travel_times[
        total_time > max_trip_duration,
        `:=`(
          access_time = NA_integer_,
          wait_time = NA_integer_,
          ride_time = NA_integer_,
          transfer_time = NA_integer_,
          egress_time = NA_integer_,
          routes = NA_character_,
          n_rides = NA_integer_,
          total_time = NA_integer_
        )
      ]
    } else {
      travel_times[
        total_time > max_trip_duration,
        `:=`(routes = NA_character_, total_time = NA_integer_)
      ]
    }
  }

  if (!verbose & progress) cat(" DONE!\n", file = stderr())

  if (!is.null(output_dir)) return(output_dir)
  return(travel_times[])
}
