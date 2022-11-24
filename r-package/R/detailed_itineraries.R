#' Detailed itineraries between origin-destination pairs
#'
#' Returns detailed trip information between origin-destination pairs. The
#' output includes the waiting and moving time in each trip leg, as well as some
#' info such as the distance traveled, the routes used and the geometry of each
#' leg. Please note that this function was originally conceptualized as a trip
#' planning functionality, similar to other commercial and non-commercial APIs
#' and apps (e.g. Moovit, Google's Directions API, OpenTripPlanning's
#' PlannerResource API). Thus, it consumes much more time and memory than the
#' other (more analytical) routing functions included in the package.
#'
#' @template r5r_core
#' @template common_arguments
#' @template verbose
#' @template fare_structure
#' @template max_fare
#' @param time_window An integer. The time window in minutes for which `r5r`
#'   will calculate multiple itineraries departing each minute. Defaults to 1
#'   minute. If the same sequence of routes appear in different minutes of the
#'   time window, only the fastest of them will be kept in the output. This
#'   happens because the result is not aggregated by percentile, as opposed to
#'   other routing functions in the package. Because of that, the output may
#'   contain trips departing after the specified `departure_datetime`, but
#'   still within the time window. Please read the time window vignette for
#'   more details on how this argument affects the results of each routing
#'   function: `vignette("time_window", package = "r5r")`.
#' @param suboptimal_minutes A number. The difference in minutes that each
#'   non-optimal RAPTOR branch can have from the optimal branch without being
#'   disregarded by the routing algorithm. This argument emulates the real-life
#'   behaviour that makes people want to take a path that is technically not
#'   optimal (in terms of travel time, for example) for some practical reasons
#'   (e.g. mode preference, safety, etc). In practice, the higher this value,
#'   the more itineraries will be returned in the final result.
#' @param shortest_path A logical. Whether the function should only return the
#'   fastest itinerary between each origin and destination pair (the default)
#'   or multiple alternatives.
#' @param all_to_all A logical. Whether to query routes between the 1st origin
#'   to the 1st destination, then the 2nd origin to the 2nd destination, and so
#'   on (`FALSE`, the default) or to query routes between all origins to all
#'   destinations (`TRUE`).
#' @param drop_geometry A logical. Whether the output should include the
#'   geometry of each trip leg or not. The default value of `FALSE` keeps the
#'   geometry column in the result.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template mcraptor_algorithm_section
#'
#' @return When `drop_geometry` is `FALSE`, the function outputs a `LINESTRING
#'   sf` with detailed information on the itineraries between the specified
#'   origins and destinations. When `TRUE`, the output is a `data.table`. All
#'   distances are in meters and travel times are in minutes. If `output_dir`
#'   is not `NULL`, the function returns the path specified in that parameter,
#'   in which the `.csv` files containing the results are saved.
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
#' # inputs
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#' det <- detailed_itineraries(
#'   r5r_core,
#'   origins = points[10,],
#'   destinations = points[12,],
#'   mode = c("WALK", "TRANSIT"),
#'   departure_datetime = departure_datetime,
#'   max_trip_duration = 60
#' )
#' head(det)
#'
#' stop_r5(r5r_core)
#' @export
detailed_itineraries <- function(r5r_core,
                                 origins,
                                 destinations,
                                 mode = "WALK",
                                 mode_egress = "WALK",
                                 departure_datetime = Sys.time(),
                                 time_window = 1L,
                                 suboptimal_minutes = 0L,
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
                                 shortest_path = TRUE,
                                 all_to_all = FALSE,
                                 n_threads = Inf,
                                 verbose = FALSE,
                                 progress = FALSE,
                                 drop_geometry = FALSE,
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
  od_list <- expand_od_pairs(origins, destinations, all_to_all)
  origins <- od_list$origins
  destinations <- od_list$destinations

  mode_list <- assign_mode(mode, mode_egress)

  # detailed itineraries via public transport cannot be computed on frequencies-based GTFS
  if (mode_list$transit_mode != "" & r5r_core$hasFrequencies()) {
    stop(
      "Assertion on 'r5r_core' failed: None of the GTFS feeds used to create ",
      "the transit network can contain a 'frequencies' table. Try using ",
      "gtfstools::frequencies_to_stop_times() to create a suitable feed."
    )
  }

  departure <- assign_departure(departure_datetime)
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
  shortest_path <- assign_shortest_path(shortest_path)
  drop_geometry <- assign_drop_geometry(drop_geometry)

  set_time_window(r5r_core, time_window)
  set_monte_carlo_draws(r5r_core, 1, time_window)
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")
  set_max_rides(r5r_core, max_rides)
  set_max_lts(r5r_core, max_lts)
  set_n_threads(r5r_core, n_threads)
  set_verbose(r5r_core, verbose)
  set_progress(r5r_core, progress)
  set_fare_structure(r5r_core, fare_structure)
  set_max_fare(r5r_core, max_fare)
  set_output_dir(r5r_core, output_dir)
  set_suboptimal_minutes(
    r5r_core,
    suboptimal_minutes,
    fare_structure,
    shortest_path
  )

  # call r5r_core method and process result -------------------------------

  path_options <- r5r_core$detailedItineraries(
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
    max_trip_duration,
    drop_geometry,
    shortest_path
  )

  if (!is.null(output_dir)) return(output_dir)

  path_options <- java_to_dt(path_options)

  if (!drop_geometry) {
    if (nrow(path_options) > 0) {
      path_options[, geometry := sf::st_as_sfc(geometry)]
    } else {
      path_options[, geometry := sf::st_sfc(sf::st_linestring(), crs = 4326)[0]]
    }

    path_options <- sf::st_sf(path_options, crs = 4326)
  }

  return(path_options)
}
