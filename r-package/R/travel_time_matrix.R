#' Calculate travel time matrix between origin destination pairs
#'
#' @description Fast function to calculate travel time estimates between one or
#'              multiple origin destination pairs.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins,destinations a spatial sf POINT object, or a data.frame
#'                containing the columns 'id', 'lon', 'lat'
#' @param trip_date character string, date in format "yyyy-mm-dd". If working
#'                  with public transport networks, check the GTFS.zip
#'                  (calendar.txt file) for dates with service.
#' @param departure_datetime A POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param mode character string, defaults to "WALK". See details for other options.
#' @param max_walk_dist numeric, Maximum walking distance (in Km) for the whole trip.
#' @param max_trip_duration numeric, Maximum trip duration in minutes. Defaults
#'                          to 120 minutes (2 hours).
#' @param walk_speed numeric, Average walk speed in Km/h. Defaults to 3.6 Km/h.
#' @param bike_speed numeric, Average cycling speed in Km/h. Defaults to 12 Km/h.
#' @param nThread numeric, The number of threads to use in parallel computing.
#'                Defaults to use all available threads (Inf).
#' @param verbose logical, TRUE to show detailed output messages (Default) or
#'                FALSE to show only eventual ERROR messages.
#'
#' @return A data.table with travel-time estimates (in seconds) between origin
#' destination pairs.
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
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata", package = "r5r")
#' r5r_obj <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
#'
#' # estimate travel time matrix
#' df <- travel_time_matrix( r5r_obj,
#'                           origins = points,
#'                           destinations = points,
#'                           departure_datetime = as.POSIXct("13-03-2019 14:00:00",
#'                                                format = "%d-%m-%Y %H:%M:%S"),
#'                           mode = c('WALK', 'TRANSIT'),
#'                           max_walk_dist = 5,
#'                           max_trip_duration = 7200
#'                           )
#'
#' }
#' @export

travel_time_matrix <- function(r5r_core,
                               origins,
                               destinations,
                               mode = "WALK",
                               departure_datetime = Sys.time(),
                               max_walk_dist = Inf,
                               max_trip_duration = 120L,
                               walk_speed = 3.6,
                               bike_speed = 12,
                               n_threads = Inf,
                               verbose = TRUE){


  # set r5r_core options ----------------------------------------------------


  # set bike and walk speed
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")

  # set number of threads
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)


  # check inputs ------------------------------------------------------------



  # modes
  mode_list <- select_mode(mode)

  # departure time
  departure <- posix_to_string(departure_datetime)

  # max trip duration
  max_trip_duration <- assert_really_integer(max_trip_duration, "max_trip_duration")

  # max_walking_distance and max_street_time
  max_street_time <- set_max_walk_distance(max_walk_dist,
                                           walk_speed,
                                           max_trip_duration)

  # origins and destinations
  origins      <- assert_points_input(origins, "origins")
  destinations <- assert_points_input(destinations, "destinations")


  # call r5r_core method ----------------------------------------------------


  travel_times <- r5r_core$travelTimeMatrixParallel(origins$id,
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


  # process results ---------------------------------------------------------

  # convert travel_times from java object to data.table
  travel_times <- jdx::convertToR(travel_times)
  travel_times <- data.table::rbindlist(travel_times)

  # add mode column for reference
  modes_string <- paste(unique(mode_list),collapse = " ")
  travel_times[, 'mode' := modes_string ]

  return(travel_times)

}
