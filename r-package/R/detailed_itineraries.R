#' Detailed itineraries between origin destination pairs
#'
#' @description Estimate one or multiple alternative routes between one or
#' multiple origin destination pairs. The data output brings detailed information
#' on transport mode, travel time, walked distance etc. for each trip section
#'
#' @param r5_core a rJava object to connect with R5 routing engine
#' @param fromLat 99999999
#' @param fromLon 99999999
#' @param toLat 99999999
#' @param toLon 99999999
#' @param direct_modes 99999999
#' @param transit_modes 99999999
#' @param trip_date character string, date in format "yyyy-mm-dd". If working
#'                  with public transport networks, check the GTFS.zip
#'                  (calendar.txt file) for dates with service.
#' @param departure_time character string, time in format "hh:mm:ss"
#' @param shortest_path logical, whether the function should only return the
#'                      fastest route alternative (default) or multiple alternative.
#' @param max_street_time integer,
#'
#' @return A 'data.frame sf LINESTRING'
#'
#' @family routing
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata", package = "r5r")
#' r5_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
#'
#' # input
#' fromLat <- points[1,]$lat
#' fromLon <- points[1,]$lon
#' toLat <- points[100,]$lat
#' toLon <- points[100,]$lon
#' trip_date <- "2019-05-20"
#' departure_time <- "14:00:00"
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <-"BUS"
#' street_time = 15L
#' max_street_time = 30L
#'
#' trips <- detailed_itineraries( fromLat = fromLat,
#'                                fromLon = fromLon,
#'                                toLat = toLat,
#'                                toLon = toLon,
#'                                r5_core = r5_core,
#'                                trip_date = trip_date,
#'                                departure_time = departure_time,
#'                                direct_modes = direct_modes,
#'                                transit_modes = transit_modes,
#'                                max_street_time = max_street_time)
#'
#' }
#' @export

detailed_itineraries <- function(r5_core,
                                 fromLat,
                                 fromLon,
                                 toLat,
                                 toLon,
                                 direct_modes,
                                 transit_modes,
                                 trip_date,
                                 departure_time,
                                 max_street_time,
                                 shortest_path = TRUE){

  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(toupper(direct_modes), collapse = ";")
  transit_modes <- paste0(toupper(transit_modes), collapse = ";")

  # Java expects street times to be integers. Casting the parameter to integer to make sure it works.
  max_street_time = as.integer(max_street_time)

  # Call to method inside R5RCore object
  path_options <- r5_core$planSingleTrip(fromLat, fromLon, toLat, toLon,
                                             direct_modes, transit_modes,
                                             trip_date, departure_time, max_street_time)
    # rJava::.jcall(r5_core, returnSig = "O", method = "planSingleTrip",
    #               fromLat, fromLon, toLat, toLon, direct_modes, transit_modes, trip_date, departure_time, max_street_time)

  # Collects results from R5 and transforms them into simple features objects
  path_options_df <- jdx::convertToR(path_options)

  data.table::setDT(path_options_df)[, geometry := sf::st_as_sfc(geometry)]
  path_options_sf <- sf::st_sf(path_options_df, crs = 4326) # WGS 84

  # R5 often returns multiple options with the basic structure, with minor
  # changes to the walking segments at the start and end of the trip.
  # This section filters out paths with the same signature, leaving only the one
  # with the shortest duration
  if (shortest_path) {
    distinct_options <- path_options_sf %>%
      select(-geometry) %>%
      mutate(route = if_else(route == "", mode, route)) %>%
      group_by(option) %>%
      summarise(signature = paste(route, collapse = " "), duration = sum(duration), .groups = "drop") %>%
      group_by(signature) %>%
      arrange(duration) %>%
      slice(1)

    path_options_sf <- subset(path_options_sf, option %in% distinct_options$option)
  }

  return(path_options_sf)
}

#' Plan multiple itineraries in parallel
#'
#' @description description
#'
#' @param r5_core a rJava object to connect with R5 routing engine
#' @param requests A dataframe with 5 columns: id, fromLat, fromLon, toLat and toLon
#' @param direct_modes 99999999
#' @param transit_modes 99999999
#' @param trip_date 99999999
#' @param departure_time 99999999
#' @param max_street_time 99999999
#' @param shortest_path 99999999
#'
#' @return
#' @family routing
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata", package = "r5r")
#' r5_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
#'
#' # input
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <-"BUS"
#' departure_time <- "14:00:00"
#' trip_date <- "2019-05-20"
#' street_time = 15L
#' max_street_time = 30L
#' max_trip_duration = 300L
#'
#' df <- multiple_detailed_itineraries( r5_core = r5_core,
#'                           origins = points,
#'                           destinations = points,
#'                           trip_date = trip_date,
#'                           departure_time = departure_time,
#'                           direct_modes = direct_modes,
#'                           transit_modes = transit_modes,
#'                           max_street_time = max_street_time,
#'                           max_trip_duration = max_trip_duration
#'                           )
#'
#' }
#' @export

multiple_detailed_itineraries <- function(r5_core,
                                          requests,
                                          direct_modes,
                                          transit_modes,
                                          trip_date,
                                          departure_time,
                                          max_street_time,
                                          shortest_path = TRUE) {

  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(toupper(direct_modes), collapse = ";")
  transit_modes <- paste0(toupper(transit_modes), collapse = ";")

  # Java expects street times to be integers. Casting the parameter to integer to make sure it works.
  max_street_time = as.integer(max_street_time)

  requests$id = as.character(requests$id)

  # Call to method inside R5RCore object
  path_options <- r5_core$planMultipleTrips(requests$id, requests$fromLat, requests$fromLon,
                                            requests$toLat, requests$toLon,
                                            direct_modes, transit_modes,
                                            trip_date, departure_time, max_street_time)
  # rJava::.jcall(r5_core, returnSig = "O", method = "planSingleTrip",
  #               fromLat, fromLon, toLat, toLon, direct_modes, transit_modes, trip_date, departure_time, max_street_time)

  # Collects results from R5 and transforms them into simple features objects
  # path_options_df <- jdx::convertToR(path_options) %>%
  #   data.table::rbindlist() %>%
  #   mutate(geometry = st_as_sfc(geometry)) %>%
  #   st_sf(crs = 4326) # WGS 84

  path_options <- jdx::convertToR(path_options)
  path_options_df <- data.table::rbindlist(path_options)

  data.table::setDT(path_options_df)[, geometry := sf::st_as_sfc(geometry)]
  path_options_sf <- sf::st_sf(path_options_df, crs = 4326) # WGS 84


  # R5 often returns multiple options with the basic structure, with minor
  # changes to the walking segments at the start and end of the trip.
  # This section filters out paths with the same signature, leaving only the one
  # with the shortest duration
  ####
  #### filter paths not working... we need to consider both request and option ids
  ####
  # if (shortest_path) {
  #   distinct_options <- path_options_df %>%
  #     select(-geometry) %>%
  #     mutate(route = if_else(route == "", mode, route)) %>%
  #     group_by(request, option) %>%
  #     summarise(signature = paste(route, collapse = " "), duration = sum(duration), .groups = "drop") %>%
  #     group_by(request, signature) %>%
  #     arrange(duration) %>%
  #     slice(1)
  #
  #   path_options_df <- path_options_df %>%
  #     filter(option %in% distinct_options$option)
  # }

  return(path_options_df)
}

