#' Output Fareto-format JSON for visualization with Fareto
#' 
#' This is primarily intended for debugging the fare system code. Fareto is an external tool
#' that provides visualization for R5's McRAPTOR fare calculator. To use this,
#' run faretoJson(...) as if you were running paretoFrontier(...). The return value is a JSON-formatted
#' string. Clone the fareto-examples repository (https://github.com/mattwigway/fareto-examples) and put
#' that output into the results/ directory. Serve the repository over http (e.g. python -m http.server),
#' and browse to http://localhost:post/?load=file-name-without-dot-json. So for instance if you called it
#' r5r.json, you would browse to http://localhost:port/?load=r5r
fareto_debug <- function(r5r_core,
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
                            walk_speed = 3.6,
                            bike_speed = 12,
                            max_rides = 3,
                            max_lts = 2,
                            n_threads = Inf,
                            verbose = FALSE,
                            progress = FALSE) {

  checkmate::assert_class(r5r_core, "jobjRef")

  origins <- assign_points_input(origins, "origins")
  destinations <- assign_points_input(destinations, "destinations")
  mode_list <- assign_mode(mode, mode_egress)
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

  if (nrow(origins) != 1 || nrow(destinations) != 1) {
    stop("fareto_debug requires exactly one origin and one destination")
  }

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

  # call r5r_core method and process result -------------------------------
  result <- r5r_core$faretoJson(
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

  return(result)
}