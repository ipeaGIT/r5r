#' Calculate detailed itineraries between origin destination pairs
#'
#' Fast computation of (multiple) detailed itineraries between one or many
#' origin destination pairs.
#'
#' @template r5r_core
#' @template common_arguments
#' @template verbose
#' @param shortest_path A logical. Whether the function should only return the
#' fastest itinerary between each origin and destination pair (the default) or
#' multiple alternatives.
#' @param all_to_all A logical. Whether to query routes between the 1st origin
#' to the 1st destination, then the 2nd origin to the 2nd destination, and so
#' on (`FALSE`, the default) or to query routes between all origins to all
#' destinations (`TRUE`).
#' @param drop_geometry A logical. Whether the output should include the
#' geometry of each segment or not. The default value of `FALSE` keeps the
#' geometry column in the result.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template mcraptor_algorithm_section
#'
#' @return When `drop_geometry` is `FALSE`, the function outputs a `LINESTRING
#' sf` with detailed information on the itineraries between the specified
#' origins and destinations. When `TRUE`, the output is a `data.table`. All
#' distances are in meters and travel times are in minutes.
#'
#' @family routing
#'
#' @examplesIf interactive()
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
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
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
                                 all_to_all = FALSE,
                                 n_threads = Inf,
                                 verbose = FALSE,
                                 progress = FALSE,
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


  # check if user wants to route all possible combinations of origin-destination pairs
  if( all_to_all == TRUE){
    df <- get_all_od_combinations(origins, destinations)
         origins <- df[, .('id'=id_orig, 'lon'=lon_orig,'lat'=lat_orig)]
    destinations <- df[, .('id'=id_dest, 'lon'=lon_dest,'lat'=lat_dest)]
    }

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
    }
  }

  # If there is no result, return empty simple feature
  if (nrow(path_options) == 0) {
    if (!drop_geometry) {
      path_options[, geometry := sf::st_sfc(sf::st_linestring(), crs = 4326)[0]]
      path_options <- sf::st_sf(path_options, crs = 4326)
    }
    return(path_options)
  }

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

    path_options[, temp_route := data.table::fifelse(route == "", mode, route)]
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
