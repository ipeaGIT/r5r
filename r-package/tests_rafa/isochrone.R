#' Estimate the isochrones from a given location
#'
#' @description Fast computation of the isochrones from a given location.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins,destinations a spatial sf POINT object, or a data.frame
#'                containing the columns 'id', 'lon', 'lat'
#' @param mode string. Transport modes allowed for the trips. Defaults to
#'             "WALK". See details for other options.
#' @param departure_datetime POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param cutoffs numeric vector. Number of minutes to define time span of each
#'                each Isochrone. Defaults to c(0, 15, 30, 45, 60).
#' @param max_walk_dist numeric. Maximum walking distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on walking, as
#'                      long as \code{max_trip_duration} is respected.
#' @param max_trip_duration numeric. Maximum trip duration in minutes. Defaults
#'                          to 120 minutes (2 hours).
#' @param walk_speed numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides numeric. The max number of public transport rides allowed in
#'                  the same trip. Defaults to 3.
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#' @param verbose logical. TRUE to show detailed output messages (the default)
#'                or FALSE to show only eventual ERROR messages.
#'
#' @return ????????????????????An  data.table with travel time estimates (in minutes) between origin
#' destination pairs by a given transport mode.
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
#' See the documentation of the travel_time_matrix function for details.
#'
#' @family routing
#' @examples \donttest{
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/point of interest
#' origin <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[500,]
#'
#' departure_datetime <- as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
#'
#'# estimate travel time matrix
#'iso <- isochrone(r5r_core,
#'                 origin = origin,
#'                 mode = c("WALK", "TRANSIT"),
#'                 departure_datetime = departure_datetime,
#'                 cutoffs = c(0, 15, 30, 45, 60, 75, 90, 120),
#'                 max_walk_dist = Inf,
#'                 max_trip_duration = 120L)
#'                 }
#' @export

isochrone <- function(r5r_core,
                      origin,
                      destinations = NULL,
                      mode = "WALK",
                      departure_datetime = Sys.time(),
                      cutoffs = c(0, 15, 30, 45, 60),
                      max_walk_dist = Inf,
                      max_trip_duration = 120L,
                      walk_speed = 3.6,
                      bike_speed = 12,
                      max_rides = 3,
                      n_threads = Inf,
                      verbose = TRUE){

# check inputs ------------------------------------------------------------

  # check cutoffs
  checkmate::assert_numeric(cutoffs, lower = 0)



# get destinations ------------------------------------------------------------

  # if no 'destinations' are passed, use all network nodes as destination points
  if(is.null(destinations)){
    network <- street_network_to_sf(r5r_core)
    destinations = network[[1]]
  }


# estimate travel time matrix ------------------------------------------------------------

ttm <- travel_time_matrix(r5r_core=r5r_core,
                            origins = origin,
                            destinations = destinations,
                            mode = mode,
                            departure_datetime = departure_datetime,
                            max_walk_dist = max_walk_dist,
                            max_trip_duration = max_trip_duration,
                            walk_speed = 3.6,
                            bike_speed = 12,
                            max_rides = 3,
                            n_threads = Inf,
                            verbose = TRUE)

# aggregate isocrhones ------------------------------------------------------------

  # include 0 in cutoffs
  if(min(cutoffs) >0){cutoffs <- sort(c(0, cutoffs))}

  # aggregate travel-times
  ttm[, isocrhones := cut(x=travel_time, breaks=cutoffs)]


  # join ttm results to destinations
  setDT(destinations)[, index := as.character(index)]
  destinations[ttm, on=c('index' ='toId'), isocrhones := i.isocrhones]

  # back to sf
  destinations_sf <- st_as_sf(destinations)

  return(destinations_sf)
}
