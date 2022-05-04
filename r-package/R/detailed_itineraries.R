#' Calculate detailed itineraries between origin destination pairs
#'
#' Fast computation of (multiple) detailed itineraries between one or many
#' origin destination pairs.
#'
#' @template common_arguments
#' @param shortest_path logical. Whether the function should only return the
#'                      fastest route alternative (the default) or multiple
#'                      alternatives.
#' @param drop_geometry logical. Indicates whether R5 should drop segment's
#'                      geometry column. It can be helpful for saving memory.
#'
#' @details
#'  # Transport modes:
#'  R5 allows for multiple combinations of transport modes. The options include:
#'
#'   ## Transit modes
#'   TRAM, SUBWAY, RAIL, BUS, FERRY, CABLE_CAR, GONDOLA, FUNICULAR. The option
#'   'TRANSIT' automatically considers all public transport modes available.
#'
#'   ## Non transit modes
#'   WALK, BICYCLE, CAR, BICYCLE_RENT, CAR_PARK
#'
#' # max_lts, Maximum Level of Traffic Stress:
#' When cycling is enabled in R5, setting `max_lts` will allow cycling only on
#' streets with a given level of danger/stress. Setting `max_lts` to 1, for example,
#' will allow cycling only on separated bicycle infrastructure or low-traffic
#' streets; routing will revert to walking when traversing any links with LTS
#' exceeding 1. Setting `max_lts` to 3 will allow cycling on links with LTS 1, 2,
#' or 3.
#'
#' The default methodology for assigning LTS values to network edges is based on
#' commonly tagged attributes of OSM ways. See more info about LTS in the original
#' documentation of R5 from Conveyal at \url{https://docs.conveyal.com/learn-more/traffic-stress}.
#' In summary:
#'
#'- **LTS 1**: Tolerable for children. This includes low-speed, low-volume streets,
#'  as well as those with separated bicycle facilities (such as parking-protected
#'  lanes or cycle tracks).
#'- **LTS 2**: Tolerable for the mainstream adult population. This includes streets
#'  where cyclists have dedicated lanes and only have to interact with traffic at
#'  formal crossing.
#'- **LTS 3**: Tolerable for “enthused and confident” cyclists. This includes streets
#'  which may involve close proximity to moderate- or high-speed vehicular traffic.
#'- **LTS 4**: Tolerable for only “strong and fearless” cyclists. This includes streets
#'  where cyclists are required to mix with moderate- to high-speed vehicular traffic.
#'
#'  For advanced users, you can provide custom LTS values by adding a tag
#'  <key = "lts> to the `osm.pbf` file
#'
#' # Routing algorithm:
#'  The detailed_itineraries function uses an R5-specific extension to the
#'  McRAPTOR routing algorithm to find paths that are optimal or less than
#'  optimal, with some heuristics around multiple access modes, riding the same
#'  patterns, etc. The specific extension to McRAPTOR to do suboptimal
#'  path routing are not documented yet, but a detailed description of base
#'  McRAPTOR can be found in Delling et al (2015).
#'  - Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public transit
#'   routing. Transportation Science, 49(3), 591-604.
#'
#' # Datetime parsing
#'
#' `r5r` ignores the timezone attribute of datetime objects when parsing dates
#' and times, using the study area's timezone instead. For example, let's say
#' you are running some calculations using Rio de Janeiro, Brazil, as your study
#' area. The datetime `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S")` will be parsed as May 13th, 2019, 14:00h in
#' Rio's local time, as expected. But `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S", tz = "Europe/Paris")` will also be parsed as
#' the exact same date and time in Rio's local time, perhaps surprisingly,
#' ignoring the timezone attribute.
#'
#' @return A LINESTRING sf with detailed information about the itineraries
#'         between specified origins and destinations. Distances are in meters
#'         and travel times are in minutes.
#'
#' @family routing
#'
#' @examples if (interactive()) {
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path, temp_dir = TRUE)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#'
#' # inputs
#' departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
#'
#' dit <- detailed_itineraries(r5r_core,
#'                             origins = points[10,],
#'                             destinations = points[12,],
#'                             mode = c("WALK", "TRANSIT"),
#'                             departure_datetime = departure_datetime,
#'                             max_walk_dist = 1000,
#'                             max_trip_duration = 120L)
#'
#' stop_r5(r5r_core)
#' }
#' @export

detailed_itineraries <- function(r5r_core,
                                 origins,
                                 destinations,
                                 mode = "WALK",
                                 mode_egress = "WALK",
                                 departure_datetime = Sys.time(),
                                 max_walk_dist = Inf,
                                 max_bike_dist = Inf,
                                 max_trip_duration = 120L,
                                 walk_speed = 3.6,
                                 bike_speed = 12,
                                 max_rides = 3,
                                 max_lts = 2,
                                 shortest_path = TRUE,
                                 n_threads = Inf,
                                 verbose = TRUE,
                                 progress = TRUE,
                                 drop_geometry = FALSE) {


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

  # max_walking_distance and max_street_time
  max_walk_time <- set_max_street_time(max_walk_dist,
                                       walk_speed,
                                       max_trip_duration)
  max_bike_time <- set_max_street_time(max_bike_dist,
                                       bike_speed,
                                       max_trip_duration)

  # shortest_path
  checkmate::assert_logical(shortest_path)

  # drop_geometry
  checkmate::assert_logical(drop_geometry)

  # origins and destinations
  # either they have the same number of rows or one of them has only one row,
  # in which case the smaller dataframe is expanded
  origins      <- assert_points_input(origins, "origins")
  destinations <- assert_points_input(destinations, "destinations")

  n_origs <- nrow(origins)
  n_dests <- nrow(destinations)

  if (n_origs != n_dests) {

    if ((n_origs > 1) && (n_dests > 1)) {

      stop(paste("Origins and destinations dataframes must either have the",
                 "same size or one of them must have only one entry."))

    } else {

      if (n_origs > n_dests) {

        destinations <- destinations[rep(1, n_origs), ]
        message("Destinations dataframe expanded to match the number of origins.")

      } else {

        origins <- origins[rep(1, n_dests), ]
        message("Origins dataframe expanded to match the number of destinations.")

      }

    }

  }


  # set r5r_core options ----------------------------------------------------

  # set bike and walk speed
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")

  # set max transfers
  set_max_rides(r5r_core, max_rides)

  # max_lts
  set_max_lts(r5r_core, max_lts)

  # set suboptimal minutes
  # if only the shortest path is requested, set suboptimal minutes to 0 minutes,
  # else revert back to the 5 minutes default.
  if (shortest_path) {
    set_suboptimal_minutes(r5r_core, 0L)
  } else {
    set_suboptimal_minutes(r5r_core, 5L)
  }

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)

  # set progress
  set_progress(r5r_core, progress)

  # call r5r_core method ----------------------------------------------------

  path_options <- r5r_core$detailedItineraries(origins$id,
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
                                               max_trip_duration,
                                               drop_geometry)


  # process results ---------------------------------------------------------


  # check if any itineraries have been found - if not, raises an error
  # if there are any results, convert those to a data.frame. if only one pair of
  # origin and destination has been passed, then the result is already a df

  if (is.null(path_options)) {

    return(data.table::data.table(path_options))

  } else {

    path_options <- java_to_dt(path_options)

    if (!is.data.frame(path_options)) {

      path_options <- data.table::rbindlist(path_options)

      if (nrow(path_options) == 0) return(path_options)

    }

  }

  if (nrow(path_options) == 0) return(path_options)

  # return either the fastest or multiple itineraries between an o-d pair (untie
  # it by the option number, if necessary)

  path_options[, total_duration := sum(segment_duration, wait), by = .(from_id, to_id, option)]

  if (shortest_path) {

    path_options <- path_options[path_options[, .I[total_duration == min(total_duration)], by = .(from_id, to_id)]$V1]
    path_options <- path_options[path_options[, .I[option == min(option)], by = .(from_id, to_id)]$V1]

  } else {

    # R5 often returns multiple itineraries between an origin and a destination
    # with the same basic structure, but with minor differences in the walking
    # segments at the start and end of the trip.
    # itineraries with the same signature (sequence of routes) are filtered to
    # keep the one with the shortest duration

    path_options[, temp_route := fifelse(route == "", mode, route)]
    path_options[, temp_sign := paste(temp_route, collapse = "_"), by = .(from_id, to_id, option)]

    path_options <- path_options[path_options[, .I[total_duration == min(total_duration)],by = .(from_id, to_id, temp_sign)]$V1]
    path_options <- path_options[path_options[, .I[option == min(option)], by = .(from_id, to_id, temp_sign)]$V1]

    # remove temporary columns
    path_options[, grep("temp_", names(path_options), value = TRUE) := NULL]

  }

  # substitute 'option' id assigned by r5 to a run-length id from 1 to number of
  # options
  path_options[, option := data.table::rleid(option), by = .(from_id, to_id)]

  # if results include the geometry, convert path_options from data.frame to
  # data.table with sfc column
  if (!drop_geometry) {

    # convert path_options from data.table to sf with CRS WGS 84 (EPSG 4326)
    path_options[, geometry := sf::st_as_sfc(geometry)]
    path_options <- sf::st_sf(path_options, crs = 4326)

  }

  return(path_options)

}
