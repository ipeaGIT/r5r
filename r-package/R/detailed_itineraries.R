#' Plan multiple itineraries
#'
#' @description Returns multiple detailed itineraries between specified origins
#' and destinations.
#'
#' @param r5r_core A rJava object to connect with R5 routing engine
#' @param origins,destinations A dataframe with 3 columns: \code{id}, \code{lat},
#'                    \code{lon}.
#' @param mode character string, defaults to "WALK". See details for
#'                     other options.
#' @param trip_date A string in the format "yyyy-mm-dd". If working with public
#'                  transport networks, please check \code{calendar.txt} within
#'                  the GTFS file for valid dates.
#' @param departure_time A string in the format "hh:mm:ss".
#' @param max_street_time An integer representing the maximum total travel time
#'                        allowed (in minutes).
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
#' \donttest{library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load and set origin/destination points
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#'
#' origins <- head(points, 5)
#' destinations <- tail(points, 5)
#'
#' # input
#' mode = c('WALK', 'TRANSIT')
#' departure_time <- "14:00:00"
#' trip_date <- "2019-03-15"
#' max_street_time <- 30L
#'
#' df <- detailed_itineraries(r5r_core,
#'                            origins,
#'                            destinations,
#'                            mode,
#'                            trip_date,
#'                            departure_time,
#'                            max_street_time)
#'
#' }
#' @export

detailed_itineraries <- function(r5r_core,
                                 origins,
                                 destinations,
                                 mode = "WALK",
                                 trip_date,
                                 departure_time,
                                 max_street_time,
                                 walk_speed = 3.6,
                                 bike_speed = 12,
                                 shortest_path = TRUE,
                                 nThread = Inf) {

  ### check inputs
  # max_trip_duration & max_street_time
  if(! is.numeric(max_street_time)){stop(message('max_street_time must be of class interger'))}
  # if(! is.numeric(max_trip_duration)){stop(message('max_trip_duration must be of class interger'))}

  # Forcefully cast integer parameters before passing them to Java
  max_street_time = as.integer(max_street_time)
  # max_trip_duration = as.integer(max_trip_duration)

  # Modes
  mode_list <- select_mode(mode)

  # set bike and walk speed in meters per second
  r5r_core$setWalkSpeed(walk_speed*5/18)
  r5r_core$setBikeSpeed(bike_speed*5/18)

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

  requests_ids <- paste0(origins$id, "_", destinations$id)

  # set number of threads
  if(nThread == Inf){ r5r_core$setNumberOfThreadsToMax()
  } else if(!is.numeric(nThread)){stop("nThread must be numeric")
  } else { r5r_core$setNumberOfThreads(as.integer(nThread))}


  # call to method inside R5RCore object
  # if a single origin is provided, calls sequential function planSingleTrip
  # else, calls parallel function planMultipleTrips

  if (n_origs == 1 && n_dests == 1) {

    path_options <- r5r_core$planSingleTrip(requests_ids,
                                            origins$lat,
                                            origins$lon,
                                            destinations$lat,
                                            destinations$lon,
                                            direct_modes= mode_list$direct_modes,
                                            transit_modes= mode_list$transit_mode,
                                            access_mode= mode_list$access_mode,
                                            egress_mode= mode_list$egress_mode,
                                            trip_date,
                                            departure_time,
                                            max_street_time)

  } else {

    path_options <- r5r_core$planMultipleTrips(requests_ids,
                                               origins$lat,
                                               origins$lon,
                                               destinations$lat,
                                               destinations$lon,
                                               direct_modes= mode_list$direct_modes,
                                               transit_modes= mode_list$transit_mode,
                                               access_mode= mode_list$access_mode,
                                               egress_mode= mode_list$egress_mode,
                                               trip_date,
                                               departure_time,
                                               max_street_time)

  }

  # convert result into a data.frame. if only one pair of origin and destination
  # has been sent then the result is already a df

  path_options <- jdx::convertToR(path_options)

  if (!is.data.frame(path_options)) {
    path_options <- data.table::rbindlist(path_options)
  }

  # convert from data.frame to sf with CRS WGS 84 (EPSG 4326)

  data.table::setDT(path_options)[, geometry := sf::st_as_sfc(geometry)]
  path_options <- sf::st_sf(path_options, crs = 4326)

  return(path_options)

}

