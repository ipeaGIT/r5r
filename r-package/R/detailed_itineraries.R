#' Plan multiple itineraries
#'
#' @description Returns multiple detailed itineraries between specified origins
#' and destinations.
#'
#' @param r5r_core A rJava object to connect with R5 routing engine
#' @param origins,destinations A dataframe with 3 columns: \code{id}, \code{lat},
#'                    \code{lon}.
#' @param direct_modes A character vector that can assume any combination of
#'                     \code{"WALK"}, \code{"BICYCLE"} and \code{"CAR"}.
#' @param transit_modes A character vector that can assume any combination of
#'                     \code{"WALK"}, \code{"BICYCLE"} and \code{"CAR"}.
#' @param trip_date A string in the format "yyyy-mm-dd". If working with public
#'                  transport networks, please check \code{calendar.txt} within
#'                  the GTFS file for valid dates.
#' @param departure_time A string in the format "hh:mm:ss".
#' @param max_street_time An integer representing the maximum total travel time
#'                        allowed (in minutes).
#' @param shortest_path A logical. Whether the function should only return the
#'                      fastest route alternative (default) or multiple
#'                      alternatives.
#'
#' @return
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
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <- "BUS"
#' departure_time <- "14:00:00"
#' trip_date <- "2019-03-15"
#' max_street_time <- 30L
#'
#' df <- detailed_itineraries(r5r_core,
#'                            origins, destinations,
#'                            direct_modes, transit_modes,
#'                            trip_date, departure_time,
#'                            max_street_time)
#'
#' }
#' @export

detailed_itineraries <- function(r5r_core,
                                 origins,
                                 destinations,
                                 direct_modes,
                                 transit_modes,
                                 trip_date,
                                 departure_time,
                                 max_street_time,
                                 shortest_path = TRUE) {

  # collapses mode lists into single strings before passing argument to Java

  direct_modes  <- paste0(toupper(direct_modes),  collapse = ";")
  transit_modes <- paste0(toupper(transit_modes), collapse = ";")

  # java expects street times to be integers

  max_street_time = as.integer(max_street_time)

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

  # call to method inside R5RCore object
  # if a single origin is provided, calls sequential function planSingleTrip
  # else, calls parallel function planMultipleTrips

  if (n_origs == 1 && n_dests == 1) {

    path_options <- r5r_core$planSingleTrip(requests_ids,
                                            origins$lat, origins$lon,
                                            destinations$lat, destinations$lon,
                                            direct_modes, transit_modes,
                                            trip_date, departure_time,
                                            max_street_time)

  } else {

    path_options <- r5r_core$planMultipleTrips(requests_ids,
                                               origins$lat, origins$lon,
                                               destinations$lat, destinations$lon,
                                               direct_modes, transit_modes,
                                               trip_date, departure_time,
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

