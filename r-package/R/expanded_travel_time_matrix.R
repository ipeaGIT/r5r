#' Calculate minute-by-minute travel times between origin destination pairs
#'
#' Detailed computation of travel time estimates between one or multiple origin
#' destination pairs. Results show the travel time of the fastest route
#' alternative departing each minute within a specified time window. Please
#' note this function can be very memory intensive for large data sets and time
#' windows.
#'
#' @template r5r_core
#' @template common_arguments
#' @param time_window An integer. The time window in minutes for which `r5r`
#'   will calculate multiple travel time matrices departing each minute.
#'   Defaults to 10 minutes. The function returns the result based on median
#'   travel times. Please read the time window vignette for more details on its
#'   usage `vignette("time_window", package = "r5r")`
#' @template draws_per_minute
#' @template verbose
#' @param breakdown A logical. Whether to include detailed information about
#'   each trip in the output. If `FALSE` (the default), the output lists the
#'   total time between each origin-destination pair and the routes used to
#'   complete the trip for each minute of the specified time window. If `TRUE`,
#'   the output includes the total access, waiting, in-vehicle and transfer
#'   time of each trip. Please note that setting this parameter to `TRUE` makes
#'   the function significantly slower.
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
#' r5r_core <- setup_r5(data_path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#'
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' # by default only returns the total time between each pair in each minute of
#' # the specified time window
#' ettm <- expanded_travel_time_matrix(
#'   r5r_core,
#'   origins = points,
#'   destinations = points,
#'   mode = c("WALK", "TRANSIT"),
#'   time_window = 20,
#'   departure_datetime = departure_datetime,
#'   max_trip_duration = 60
#' )
#' head(ettm)
#'
#' # when breakdown = TRUE the output contains much more information
#' ettm <- expanded_travel_time_matrix(
#'   r5r_core,
#'   origins = points,
#'   destinations = points,
#'   mode = c("WALK", "TRANSIT"),
#'   time_window = 20,
#'   departure_datetime = departure_datetime,
#'   max_trip_duration = 60,
#'   breakdown = TRUE
#' )
#' head(ettm)
#'
#' stop_r5(r5r_core)
#' @export
expanded_travel_time_matrix <- function(r5r_core,
                                        origins,
                                        destinations,
                                        mode = "WALK",
                                        mode_egress = "WALK",
                                        departure_datetime = Sys.time(),
                                        time_window = 10L,
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
  set_monte_carlo_draws(r5r_core, draws_per_minute, time_window)
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")
  set_max_rides(r5r_core, max_rides)
  set_max_lts(r5r_core, max_lts)
  set_n_threads(r5r_core, n_threads)
  set_verbose(r5r_core, verbose)
  set_progress(r5r_core, progress)
  set_output_dir(r5r_core, output_dir)
  set_expanded_travel_times(r5r_core, TRUE)
  set_breakdown(r5r_core, breakdown)
  set_fare_structure(r5r_core, NULL)

  # call r5r_core method and process result -------------------------------

  travel_times <- r5r_core$travelTimeMatrix(
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
