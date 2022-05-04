#' Calculate Pareto frontier of the travel matrix between origin destination
#' pairs considering combinations travel time and monetary cost.
#'
#' Fast computation of the Pareto frontier of the travel matrix between origin
#' destination pairs'considering combinations travel time and monetary cost. It
#' can be used to analyze the Pareto frontier between one or multiple origin
#' destination pairs.
#'
#' @template common_arguments
#' @template time_window_related_args
#' @param percentiles An integer vector with length smaller than or equal to 5.
#' Specifies the percentile to use when returning travel time estimates within
#' the given time window. Please note that this parameter is applied to the
#' travel time estimates only (e.g. if the 25th percentile is specified, and
#' the output between A and B is 15 minutes and 10 dollars, 25% of all trips
#' cheaper than 10 dollars taken between these points are shorter than 15
#' minutes). Defaults to 50, returning the median travel time. If a vector with
#' length bigger than 1 is passed, the output contains an additional column
#' that specifies the percentile of each travel time and monetary cost
#' combination. Due to upstream restrictions, only 5 percentiles can be
#' specified at a time. For more details, please see R5 documentation at
#' 'https://docs.conveyal.com/analysis/methodology#accounting-for-variability'.
#'
#' @return A data.table with travel time estimates (in minutes) between origin
#' destination pairs by a given transport mode. Note that origins/destinations
#' that were beyond the maximum travel time, and/or origins that were far from
#' the street network are not returned in the data.table.
#'
#' @details
#'  # Transport modes:
#'  R5 allows for multiple combinations of transport modes. The options include:
#'
#'   ## Transit modes
#'   TRAM, SUBWAY, RAIL, BUS, FERRY, CABLE_CAR, GONDOLA, FUNICULAR. The option
#'   'TRANSIT' automatically considers all public transport modes available.
#'
#'   ## Non transit modes
#'   WALK, BICYCLE, CAR, BICYCLE_RENT, CAR_PARK
#'
#' # max_lts, Maximum Level of Traffic Stress:
#' When cycling is enabled in R5, setting `max_lts` will allow cycling only on
#' streets with a given level of danger/stress. Setting `max_lts` to 1, for example,
#' will allow cycling only on separated bicycle infrastructure or low-traffic
#' streets; routing will revert to walking when traversing any links with LTS
#' exceeding 1. Setting `max_lts` to 3 will allow cycling on links with LTS 1, 2,
#' or 3.
#'
#' The default methodology for assigning LTS values to network edges is based on
#' commonly tagged attributes of OSM ways. See more info about LTS in the original
#' documentation of R5 from Conveyal at \url{https://docs.conveyal.com/learn-more/traffic-stress}.
#' In summary:
#'
#'- **LTS 1**: Tolerable for children. This includes low-speed, low-volume streets,
#'  as well as those with separated bicycle facilities (such as parking-protected
#'  lanes or cycle tracks).
#'- **LTS 2**: Tolerable for the mainstream adult population. This includes streets
#'  where cyclists have dedicated lanes and only have to interact with traffic at
#'  formal crossing.
#'- **LTS 3**: Tolerable for “enthused and confident” cyclists. This includes streets
#'  which may involve close proximity to moderate- or high-speed vehicular traffic.
#'- **LTS 4**: Tolerable for only “strong and fearless” cyclists. This includes streets
#'  where cyclists are required to mix with moderate- to high-speed vehicular traffic.
#'
#'  For advanced users, you can provide custom LTS values by adding a tag
#'  <key = "lts> to the `osm.pbf` file
#'
#' # Routing algorithm:
#' The travel_time_matrix function uses an R5-specific extension to the RAPTOR
#' routing algorithm (see Conway et al., 2017). This RAPTOR extension uses a
#' systematic sample of one departure per minute over the time window set by the
#' user in the 'time_window' parameter. A detailed description of base RAPTOR
#' can be found in Delling et al (2015).
#' - Conway, M. W., Byrd, A., & van der Linden, M. (2017). Evidence-based transit
#'  and land use sketch planning using interactive accessibility methods on
#'  combined schedule and headway-based networks. Transportation Research Record,
#'  2653(1), 45-53.
#'  - Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public transit
#'  routing. Transportation Science, 49(3), 591-604.
#'
#' # Datetime parsing
#'
#' `r5r` ignores the timezone attribute of datetime objects when parsing dates
#' and times, using the study area's timezone instead. For example, let's say
#' you are running some calculations using Rio de Janeiro, Brazil, as your study
#' area. The datetime `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S")` will be parsed as May 13th, 2019, 14:00h in
#' Rio's local time, as expected. But `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S", tz = "Europe/Paris")` will also be parsed as
#' the exact same date and time in Rio's local time, perhaps surprisingly,
#' ignoring the timezone attribute.
#'
#' @family routing
#' @examples if (interactive()) {
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/spo", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path, temp_dir = TRUE)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))[1:5,]
#'
#' departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
#'
#' # estimate travel time matrix
#' pf <- pareto_frontier(r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           mode = c("WALK", "TRANSIT"),
#'                           departure_datetime = departure_datetime)
#'
#' stop_r5(r5r_core)
#'
#' }
#' @export
pareto_frontier <- function(r5r_core,
                            origins,
                            destinations,
                            mode = c("WALK", "TRANSIT"),
                            mode_egress = "WALK",
                            departure_datetime = Sys.time(),
                            time_window = 1L,
                            percentiles = 50L,
                            max_walk_dist = Inf,
                            max_bike_dist = Inf,
                            max_trip_duration = 120L,
                            fare_calculator_settings = NULL,
                            monetary_cost_cutoffs = -1L,
                            walk_speed = 3.6,
                            bike_speed = 12,
                            max_rides = 3,
                            max_lts = 2,
                            draws_per_minute = 5L,
                            n_threads = Inf,
                            verbose = TRUE,
                            progress = TRUE) {


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
  checkmate::assert_numeric(max_trip_duration, lower=1)
  max_trip_duration <- as.integer(max_trip_duration)

  # max_walking_distance, max_bike_distance, and max_street_time
  max_walk_time <- set_max_street_time(max_walk_dist,
                                       walk_speed,
                                       max_trip_duration)
  max_bike_time <- set_max_street_time(max_bike_dist,
                                       bike_speed,
                                       max_trip_duration)

  # origins and destinations
  origins      <- assert_points_input(origins, "origins")
  destinations <- assert_points_input(destinations, "destinations")

  checkmate::assert_subset("id", names(origins))
  checkmate::assert_subset("id", names(destinations))

  # time window
  checkmate::assert_numeric(time_window, lower=1)
  time_window <- as.integer(time_window)

  # montecarlo draws per minute
  draws <- time_window * draws_per_minute
  draws <- as.integer(draws)

  # percentiles
  percentiles <- percentiles[1:5]
  percentiles <- percentiles[!is.na(percentiles)]
  checkmate::assert_numeric(percentiles)
  percentiles <- as.integer(percentiles)

  # set r5r_core options ----------------------------------------------------

  # time window
  r5r_core$setTimeWindowSize(time_window)
  r5r_core$setPercentiles(percentiles)
  r5r_core$setNumberOfMonteCarloDraws(draws)

  # set bike and walk speed
  set_speed(r5r_core, walk_speed, "walk")
  set_speed(r5r_core, bike_speed, "bike")

  # set max transfers
  set_max_rides(r5r_core, max_rides)

  # set max lts (level of traffic stress)
  set_max_lts(r5r_core, max_lts)

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # set verbose
  set_verbose(r5r_core, verbose)

  # set progress
  set_progress(r5r_core, progress)

  # fare calculator settings
  set_fare_calculator(r5r_core, fare_calculator_settings)

  # set fare cutoffs
  r5r_core$setFareCutoffs(rJava::.jfloat(monetary_cost_cutoffs))

  # call r5r_core method ----------------------------------------------------

  travel_times <- r5r_core$paretoFrontier(origins$id,
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
                                            max_trip_duration)


  # process results ---------------------------------------------------------

  # convert travel_times from java object to data.table
  if (!verbose & progress) { cat("Preparing final output...") }

  travel_times <- java_to_dt(travel_times)

  # only perform following operations when result is not empty
  if (nrow(travel_times) > 0) {
    # replace travel-times of nonviable trips with NAs
    travel_times[travel_time > max_trip_duration, travel_time := NA_integer_]
  }

  if (!verbose & progress) { cat(" DONE!\n") }
  return(travel_times)
}
