#' Title
#'
#' @param r5_core
#' @param fromLat
#' @param fromLon
#' @param toLat
#' @param toLon
#' @param direct_modes
#' @param transit_modes
#' @param trip_date
#' @param departure_time
#' @param filter_paths
#' @param max_street_time
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
#'
#' # input
#' fromLat <- points[1,]$lat
#' fromLon <- points[1,]$lon
#' toLat <- points[100,]$lat
#' toLon <- points[100,]$lon
#' trip_date <- "2019-05-20"
#' departure_time <- "14:00:00"
#' street_time = 15L
#' direct_modes <- c("WALK", "BICYCLE", "CAR")
#' transit_modes <-"BUS"
#' max_street_time = 30
#'
#' trip <- detailed_itineraries( fromLat = fromLat,
#'                              fromLon = fromLon,
#'                              toLat = toLat,
#'                              toLon = toLon,
#'                              r5_core = r5_core,
#'                              trip_date = trip_date,
#'                              departure_time = departure_time,
#'                              direct_modes = direct_modes,
#'                              transit_modes = transit_modes,
#'                              max_street_time = max_street_time)
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
                                filter_paths = TRUE) {

  # Collapses list into single string before passing argument to Java
  direct_modes <- paste0(direct_modes, collapse = ";")
  transit_modes <- paste0(transit_modes, collapse = ";")

  # Call to method inside R5RCore object
  path_options <- r5_core$planSingleTrip(fromLat, fromLon, toLat, toLon,
                                             direct_modes, transit_modes,
                                             trip_date, departure_time, max_street_time)
    # rJava::.jcall(r5_core, returnSig = "O", method = "planSingleTrip",
    #               fromLat, fromLon, toLat, toLon, direct_modes, transit_modes, trip_date, departure_time, max_street_time)

  # Collects results from R5 and transforms them into simple features objects
  path_options_df <- jdx::convertToR(path_options) %>%
    mutate(geometry = st_as_sfc(geometry)) %>%
    st_sf(crs = 4326) # WGS 84

  # R5 often returns multiple options with the basic structure, with minor
  # changes to the walking segments at the start and end of the trip.
  # This section filters out paths with the same signature, leaving only the one
  # with the shortest duration
  if (filter_paths) {
    distinct_options <- path_options_df %>%
      select(-geometry) %>%
      mutate(route = if_else(route == "", mode, route)) %>%
      group_by(option) %>%
      summarise(signature = paste(route, collapse = " "), duration = sum(duration), .groups = "drop") %>%
      group_by(signature) %>%
      arrange(duration) %>%
      slice(1)

    path_options_df <- path_options_df %>%
      filter(option %in% distinct_options$option)
  }

  return(path_options_df)
}
