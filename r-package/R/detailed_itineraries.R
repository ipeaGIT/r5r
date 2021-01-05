#' Calculate detailed itineraries between origin destination pairs
#'
#' @description Fast computation of (multiple) detailed itineraries between one
#'              or many origin destination pairs.
#'
#' @param r5r_core rJava object to connect with R5 routing engine
#' @param origins,destinations either a spatial sf POINT object or a data.frame
#'                            containing the columns 'id', 'lon', 'lat'
#' @param mode string. Transport modes allowed for the trips. Defaults to
#'             "WALK". See details for other options.
#' @param mode_egress string. Transport mode used after egress from public
#'                    transport. It can be either 'WALK', 'BICYCLE', or 'CAR'.
#'                    Defaults to "WALK". Ignored when public transport is not
#'                    used.
#' @param departure_datetime POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param max_walk_dist numeric. Maximum walking distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on walking, as
#'                      long as \code{max_trip_duration} is respected.
#' @param max_trip_duration numeric. Maximum trip duration in minutes. Defaults
#'                          to 120 minutes (2 hours).
#' @param walk_speed numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides numeric. The max number of public transport rides allowed in
#'                  the same trip. Defaults to 3.
#' @param shortest_path logical. Whether the function should only return the
#'                      fastest route alternative (the default) or multiple
#'                      alternatives.
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#' @param verbose logical. TRUE to show detailed output messages (the default)
#'                or FALSE to show only eventual ERROR messages.
#' @param drop_geometry logical. Indicates whether R5 should drop segment's
#'                      geometry column. It can be helpful for saving memory.
#'
#' @details R5 allows for multiple combinations of transport modes. The options
#'          include:
#'
#'   ## Transit modes
#'   TRAM, SUBWAY, RAIL, BUS, FERRY, CABLE_CAR, GONDOLA, FUNICULAR. The option
#'   'TRANSIT' automatically considers all public transport modes available.
#'
#'   ## Non transit modes
#'   WALK, BICYCLE, CAR, BICYCLE_RENT, CAR_PARK
#'
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
#' @return A LINESTRING sf with detailed information about the itineraries
#'         between specified origins and destinations. Distances are in meters
#'         and travel times are in minutes.
#'
#' @family routing
#'
#' @examples
#' \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
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
                                 max_trip_duration = 120L,
                                 walk_speed = 3.6,
                                 bike_speed = 12,
                                 max_rides = 3,
                                 shortest_path = TRUE,
                                 n_threads = Inf,
                                 verbose = TRUE,
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
  max_street_time <- set_max_street_time(max_walk_dist,
                                        walk_speed,
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

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)


  # call r5r_core method ----------------------------------------------------

  # if a single origin is provided, calls sequential function planSingleTrip
  # else, calls parallel function planMultipleTrips

  if (n_origs == 1 && n_dests == 1) {

    path_options <- r5r_core$planSingleTrip(origins$id,
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
                                            max_street_time,
                                            max_trip_duration,
                                            drop_geometry)

  } else {

    path_options <- r5r_core$planMultipleTrips(origins$id,
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
                                               max_street_time,
                                               max_trip_duration,
                                               drop_geometry)

  }


  # process results ---------------------------------------------------------


  # check if any itineraries have been found - if not, raises an error
  # if there are any results, convert those to a data.frame. if only one pair of
  # origin and destination has been passed, then the result is already a df

  if (is.null(path_options)) {

    return(data.table::data.table(path_options))

  } else {

    path_options <- jdx::convertToR(path_options)

    if (!is.data.frame(path_options)) {

      path_options <- data.table::rbindlist(path_options)

      if (length(path_options) == 0) return(path_options)

    }

  }

  # return either the fastest or multiple itineraries between an o-d pair (untie
  # it by the option number, if necessary)

  data.table::setDT(path_options)

  path_options[, total_duration := sum(segment_duration, wait), by = .(fromId, toId, option)]

  if (shortest_path) {

    path_options <- path_options[path_options[, .I[total_duration == min(total_duration)], by = .(fromId, toId)]$V1]
    path_options <- path_options[path_options[, .I[option == min(option)], by = .(fromId, toId)]$V1]

  } else {

    # R5 often returns multiple itineraries between an origin and a destination
    # with the same basic structure, but with minor differences in the walking
    # segments at the start and end of the trip.
    # itineraries with the same signature (sequence of routes) are filtered to
    # keep the one with the shortest duration

    path_options[, temp_route := ifelse(route == "", mode, route)]
    path_options[, temp_sign := paste(temp_route, collapse = "_"), by = .(fromId, toId, option)]

    path_options <- path_options[path_options[, .I[total_duration == min(total_duration)],by = .(fromId, toId, temp_sign)]$V1]
    path_options <- path_options[path_options[, .I[option == min(option)], by = .(fromId, toId, temp_sign)]$V1]

    # remove temporary columns
    path_options[, grep("temp_", names(path_options), value = TRUE) := NULL]

  }

  # substitute 'option' id assigned by r5 to a run-length id from 1 to number of
  # options
  path_options[, option := data.table::rleid(option), by = .(fromId, toId)]

  # if results includes the geometry, convert path_options from data.frame to
  # data.table with sfc column
  if (!drop_geometry) {

    # convert path_options from data.table to sf with CRS WGS 84 (EPSG 4326)
    path_options[, geometry := sf::st_as_sfc(geometry)]
    path_options <- sf::st_sf(path_options, crs = 4326)

  }

  return(path_options)

}
