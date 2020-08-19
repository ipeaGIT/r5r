#' Calculate travel time matrix between origin destination pairs
#'
#' @description Fast function to calculate travel time estimates between one or
#'              multiple origin destination pairs.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins a spatial sf MULTIPOINT object, or a data.frame containing the
#'                columns 'id', 'lon', 'lat'
#' @param destinations a spatial sf MULTIPOINT object, or a data.frame
#'                     containing the columns 'id', 'lon', 'lat'
#' @param trip_date character string, date in format "yyyy-mm-dd". If working
#'                  with public transport networks, check the GTFS.zip
#'                  (calendar.txt file) for dates with service.
#' @param departure_time character string, time in format "hh:mm:ss"
#' @param mode character string, defaults to "WALK". See details for other options.
#' @param max_street_time numeric,
#' @param max_trip_duration numeric, Maximum trip duration in seconds. Defaults
#'                          to 7200 seconds (2 hours).
#' @param walk_speed numeric, Average walk speed in Km/h. Defaults to 3.6 Km/h.
#' @param bike_speed numeric, Average cycling speed in Km/h. Defaults to 12 Km/h.
#' @param nThread numeric, The number of threads to use in parallel computing.
#'                Defaults to use all available threads (Inf).
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
#' r5r_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
#'
#' # estimate travel time matrix
#' df <- travel_time_matrix( r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           trip_date = "2019-05-20",
#'                           departure_time = "14:00:00",
#'                           mode = c('WALK', 'TRANSIT'),
#'                           max_trip_duration = 7200
#'                           )
#'
#' }
#' @export

travel_time_matrix <- function( r5r_core,
                                origins,
                                destinations,
                                trip_date,
                                departure_time,
                                mode = "WALK",
                                max_street_time = 7200,
                                max_trip_duration = 7200,
                                walk_speed = 3.6,
                                bike_speed = 12,
                                nThread = Inf){

### check inputs

  # max_trip_duration & max_street_time
  if(! is.numeric(max_street_time)){stop(message('max_street_time must be of class interger'))}
  if(! is.numeric(max_trip_duration)){stop(message('max_trip_duration must be of class interger'))}

    # Forcefully cast integer parameters before passing them to Java
    max_street_time = as.integer(max_street_time)
    max_trip_duration = as.integer(max_trip_duration)

  # Modes
    mode_list <- select_mode(mode)

  # Origins / Destinations
    test_points_input(origins)
    test_points_input(destinations)

    # if origins/destinations are a spatial 'sf' objects, convert them to data.frame
    if(sum(class(origins) %in% 'sf')>0){origins <- sf_to_df_r5r(origins)}
    if(sum(class(destinations) %in% 'sf')>0){destinations <- sf_to_df_r5r(destinations)}

  # set bike and walk speed in meters per second
    r5r_core$setWalkSpeed(walk_speed*5/18)
    r5r_core$setBikeSpeed(bike_speed*5/18)

  # set number of threads
    if(nThread == Inf){ r5r_core$setNumberOfThreadsToMax()
      } else if(!is.numeric(nThread)){stop("nThread must be numeric")
        } else { r5r_core$setNumberOfThreads(as.integer(nThread))}

  # Call to method inside r5r_core object
    travel_times <- r5r_core$travelTimeMatrixParallel(origins$id,
                                                      origins$lat,
                                                      origins$lon,
                                                      destinations$id,
                                                      destinations$lat,
                                                      destinations$lon,
                                                      direct_modes= mode_list$direct_modes,
                                                      transit_modes= mode_list$transit_mode,
                                                      access_mode= mode_list$access_mode,
                                                      egress_mode= mode_list$egress_mode,
                                                      trip_date,
                                                      departure_time,
                                                      max_street_time,
                                                      max_trip_duration
                                                      )

  # travel_times <- rJava::.jcall(r5r_core, returnSig = "V", method = "travelTimesFromOrigin",
  #                               fromId, fromLat, fromLon, jdx::convertToJava(destinations),
  #                               direct_modes, transit_modes, trip_date, departure_time,
  #                               max_street_time, max_trip_duration)

  travel_times <- jdx::convertToR(travel_times)
  travel_times <- data.table::rbindlist(travel_times)

  modes_string <- paste(unique(mode_list),collapse = " ")
  travel_times[, 'mode' := modes_string ]

  return(travel_times)
}
