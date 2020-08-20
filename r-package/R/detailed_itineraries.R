#' Plan multiple itineraries
#'
#' @description Returns multiple detailed itineraries between specified origins
#' and destinations.
#'
#' @param r5r_core A rJava object to connect with R5 routing engine
#' @param origins,destinations Either a spatial sf POINT or a data.frame
#'                             containing the columns \code{id}, \code{lon} and
#'                             \code{lat}.
#' @param departure_datetime A POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param max_walk_dist numeric, Maximum walking distance (in Km) for the whole trip.
#' @param mode A string, defaults to "WALK". See details for other options.
#' @param max_trip_duration An integer. Maximum trip duration in minutes.
#'                          Defaults to 120 minutes (2 hours).
#' @param walk_speed numeric, Average walk speed in Km/h. Defaults to 3.6 Km/h.
#' @param bike_speed numeric, Average cycling speed in Km/h. Defaults to 12 Km/h.
#' @param shortest_path A logical. Whether the function should only return the
#'                      fastest route alternative (default) or multiple
#'                      alternatives.
#' @param nThread numeric, The number of threads to use in parallel computing.
#'                Defaults to use all available threads (Inf).
#' @return
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
#' @family routing

#' @examples
#' \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load and set origin/destination points
#' points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#'
#' origins <- points[10,]
#' destinations <- points[12,]
#'
#' # inputs
#' mode = c("WALK", "BUS")
#' max_walk_dist <- 1
#' departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
#'                                  format = "%d-%m-%Y %H:%M:%S")
#'
#' df <- detailed_itineraries(r5r_core,
#'                            origins,
#'                            destinations,
#'                            departure_datetime,
#'                            max_walk_dist,
#'                            mode)
#'
#' }
#' @export

detailed_itineraries <- function(r5r_core,
                                 origins,
                                 destinations,
                                 max_walk_dist,
                                 mode = "WALK",
                                 departure_datetime = Sys.time(),
                                 max_trip_duration = 3600L,
                                 walk_speed = 3.6,
                                 bike_speed = 12,
                                 shortest_path = TRUE,
                                 nThread = Inf) {



  # check inputs ------------------------------------------------------------


  # modes

  mode_list <- select_mode(mode)

  # bike and walk speed
  # must be converted from km/h to m/s

  if (!is.numeric(walk_speed)){ stop("walk_speed must be numeric.")
  } else{ r5r_core$setWalkSpeed(walk_speed * 5 / 18) }

  if (!is.numeric(bike_speed)){ stop("bike_speed must be numeric.")
  } else{ r5r_core$setBikeSpeed(bike_speed * 5 / 18) }


  # departure date_time
  departure <- posix_to_string(departure_datetime)

  # origins and destinations

  test_points_input(origins)
  test_points_input(destinations)

  # if origins/destinations are 'sf' objects, convert them to 'data.frame'

  if(sum(class(origins) %in% "sf") > 0) origins <- sf_to_df_r5r(origins)
  if(sum(class(destinations) %in% "sf") > 0) destinations <- sf_to_df_r5r(destinations)

  # either 'origins' and 'destinations' have the same number of rows or one of
  # them has only one entry, in which case the smaller dataframe is expanded

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

  # max walking distance - also set max_street_time
    max_street_time <- set_max_walk_distance(max_walk_dist,
                                             walk_speed,
                                             max_trip_duration)

  # set number of threads
  if(nThread == Inf){ r5r_core$setNumberOfThreadsToMax()
  } else if(!is.numeric(nThread)){stop("nThread must be numeric.")
  } else { r5r_core$setNumberOfThreads(as.integer(nThread))}


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
                                            max_trip_duration)

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
                                               max_trip_duration)

  }


  # process results ---------------------------------------------------------


  # check if any itineraries have been found - if not, raises an error
  # if there are any results, convert those to a data.frame. if only one pair of
  # origin and destination has been passed, then the result is already a df

  if (is.null(path_options)) {

    stop("No itineraries have been found.")

  } else {

    path_options <- jdx::convertToR(path_options)

    if (!is.data.frame(path_options)) {

      path_options <- data.table::rbindlist(path_options)

      if (length(path_options) == 0) stop("No itineraries have been found.")

    }

  }

  # convert path_options from data.frame to data.table with sfc column

  data.table::setDT(path_options)[, geometry := sf::st_as_sfc(geometry)]

  # return either the fastest or multiple itineraries between an o-d pair

  if (shortest_path) {

    path_options[, temp_duration := sum(duration), by = .(fromId, toId, option)]
    path_options <- path_options[, .SD[temp_duration == min(temp_duration)], by = .(fromId, toId)]

  } else {

    # R5 often returns multiple itineraries between an origin and a destination
    # with the same basic structure, but with minor differences in the walking
    # segments at the start and end of the trip.
    # itineraries with the same signature (sequence of routes) are filtered to
    # keep the one with the shortest duration

    path_options[, temp_route := ifelse(route == "", mode, route)]
    path_options[, temp_sign := paste(temp_route, collapse = "_"), by = .(fromId, toId, option)]
    path_options[, temp_duration := sum(duration), by = .(fromId, toId, option)]

    path_options <- path_options[, .SD[temp_duration == min(temp_duration)], by = .(fromId, toId, temp_sign)]

  }

  path_options[, grep("temp_", names(path_options), value = TRUE) := NULL]

  # convert path_options from data.table to sf with CRS WGS 84 (EPSG 4326)

  path_options <- sf::st_sf(path_options, crs = 4326)

  return(path_options)

}
