#' Calculate access to opportunities
#'
#' @description Fast computation of access to opportunities given a selected
#'              decay function. See `details` for the available decay functions.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins,destinations a spatial sf POINT object, or a data.frame
#'                containing the columns 'id', 'lon', 'lat'
#' @param opportunities_colname string. The column name in the `destinations`
#'        input that tells the number of opportunities in each location.
#'        Defaults to "opportunities".
#' @param mode string. Transport modes allowed for the trips. Defaults to
#'             "WALK". See details for other options.
#' @param mode_egress string. Transport mode used after egress from public
#'                    transport. It can be either 'WALK', 'BICYCLE', or 'CAR'.
#'                    Defaults to "WALK".
#' @param departure_datetime POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param time_window numeric. Time window in minutes for which r5r will
#'                    calculate travel times departing each minute. When using
#'                    frequency-based GTFS files, 5 Monte Carlo simulations will
#'                    be run for each minute in the time window. See details for
#'                    further information.
#' @param percentiles numeric vector. Defaults to '50', returning the accessibility
#'                    value for the median travel time computed for a given
#'                    time_window. If a numeric vector is passed, for example
#'                    c(25, 50, 75), the function will return accessibility
#'                    estimates for each percentile, by travel time cutoff. Only
#'                    the first 5 cut points of the percentiles are considered.
#'                    For more details, see R5 documentation at
#'                    'https://docs.conveyal.com/analysis/methodology#accounting-for-variability'
#' @param decay_function string. Choice of one of the following decay functions:
#'                       'step', 'exponential', 'fixed_exponential', 'linear',
#'                       and 'logistic'. Defaults to 'step', which yields
#'                       cumulative opportunities accessibility metrics.
#'                       More info in `details`.
#' @param cutoffs numeric. Cutoff times in minutes for calculating cumulative
#'                opportunities accessibility when using the 'step decay function'.
#'                This parameter has different effects for each of the other decay
#'                functions: it indicates the 'median' (or inflection point) of
#'                the decay curves in the 'logistic' and 'linear' functions, and
#'                the 'half-life' in the 'exponential' function. It has no effect
#'                when using the 'fixed exponential' function.
#' @param decay_value numeric. Extra parameter to be passed to the selected
#'                `decay_function`.
#' @param max_walk_dist numeric. Maximum walking distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on walking, as
#'                      long as \code{max_trip_duration} is respected.
#' @param max_bike_dist numeric. Maximum cycling distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on cycling, as
#'                      long as \code{max_trip_duration} is respected.
#' @param max_trip_duration numeric. Maximum trip duration in minutes. Defaults
#'                          to 120 minutes (2 hours).
#' @param walk_speed numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides numeric. The max number of public transport rides allowed in
#'                  the same trip. Defaults to 3.
#' @param max_lts  numeric (between 1 and 4). The maximum level of traffic stress
#'                 that cyclists will tolerate. A value of 1 means cyclists will
#'                 only travel through the quietest streets, while a value of 4
#'                 indicates cyclists can travel through any road. Defaults to 2.
#'                 See details for more information.
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#' @param verbose logical. `TRUE` to show detailed output messages (the default).
#'                If verbose is set to `FALSE`, r5r prints a progress counter and
#'                eventual `ERROR` messages. Setting `verbose` to  `FALSE` imposes
#'                a small penalty for computation efficiency.
#'
#' @return A data.table with accessibility estimates for all origin points, by
#' a given transport mode, and per travel time cutoff and percentile.
#'
#' @details
#'  # Decay functions:
#'  R5 allows for multiple decay functions. More info at \url{https://docs.conveyal.com/learn-more/decay-functions}
#'  The options include:
#'
#'  ## Step `step` (cumulative opportunities)
#'  A binary decay function used to calculate cumulative opportunities metrics.
#'
#'  ## Logistic CDF `logistic`
#'  This is the logistic function, i.e. the cumulative distribution function of
#'  the logistic distribution, expressed such that its parameters are the median
#'  (inflection point) and standard deviation. This function applies a sigmoid
#'  rolloff that has a convenient relationship to discrete choice theory. Its
#'  parameters can be set to reflect a whole population's tolerance for making
#'  trips with different travel times. The function's value represents the
#'  probability that a randomly chosen member of the population would accept
#'  making a trip, given its duration. Opportunities are then weighted by how
#'  likely it is a person would consider them "reachable".
#'
#'  ### calibration
#'  The median parameter is controlled by the `cutoff` parameter, leaving only
#'  the standard deviation to configure through the `decay_value` parameter.
#'
#'  ## Fixed Exponential `fixed_exponential`
#'  This function is of the form e-Lt where L is a single fixed decay constant
#'  in the range (0, 1). It is constrained to be positive to ensure weights
#'  decrease (rather than grow) with increasing travel time.
#'
#'  ### calibration
#'  This function is controlled exclusively by the L constant, given by the
#'  `decay_value` parameter. Values provided in `cutoffs` are ignored.

#'  ## Half-life Exponential Decay `exponential`
#'  This is similar to the fixed-exponential option above, but in this case the
#'  decay parameter is inferred from the `cutoffs` parameter values, which is
#'  treated as the half-life of the decay.
#'
#'  ## Linear `linear`
#'  This is a simple, vaguely sigmoid option, which may be useful when you have
#'  a sense of a maximum travel time that would be tolerated by any traveler,
#'  and a minimum time below which all travel is perceived to be equally easy.
#'
#'  ### calibration
#'  The transition region is transposable and symmetric around the `cutoffs`
#'  parameter values, taking `decay_value` minutes to taper down from one to zero.
#'
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
#' commonly tagged attributes of OSM ways. See more info about LTS at
#' \url{https://docs.conveyal.com/learn-more/traffic-stress}. In summary:
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
#' # Routing algorithm:
#' The `accessibility()` function uses an R5-specific extension to the RAPTOR
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
#' @family routing
#' @examples if (interactive()) {
#'library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#'
# estimate accessibility
#'   access <- accessibility(r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           opportunities_colname = "schools",
#'                           mode = "WALK",
#'                           cutoffs = c(25, 30),
#'                           max_trip_duration = 30,
#'                           verbose = FALSE)
#'
#' stop_r5(r5r_core)
#'
#' }
#' @export

accessibility <- function(r5r_core,
                          origins,
                          destinations,
                          opportunities_colname = "opportunities",
                          mode = "WALK",
                          mode_egress = "WALK",
                          departure_datetime = Sys.time(),
                          time_window = 1L,
                          percentiles = 50L,
                          decay_function = "step",
                          cutoffs = 30L,
                          decay_value = 1.0,
                          max_walk_dist = Inf,
                          max_bike_dist = Inf,
                          max_trip_duration = 120L,
                          walk_speed = 3.6,
                          bike_speed = 12,
                          max_rides = 3,
                          max_lts = 2,
                          n_threads = Inf,
                          verbose = TRUE) {


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

  # opportunities
  checkmate::assert_character(opportunities_colname)
  checkmate::assert_names(names(destinations), must.include = opportunities_colname,
                          .var.name = "destinations")
  checkmate::assert_numeric(destinations[[opportunities_colname]])
  opportunities_data <- as.integer(destinations[[opportunities_colname]])

  # time window
  checkmate::assert_numeric(time_window)
  time_window <- as.integer(time_window)
  draws <- time_window *5
  draws <- as.integer(draws)

  # percentiles
  percentiles <- percentiles[1:5]
  percentiles <- percentiles[!is.na(percentiles)]
  checkmate::assert_numeric(percentiles)
  percentiles <- as.integer(percentiles)

  # cutoffs
  checkmate::assert_numeric(cutoffs)
  cutoffs <- as.integer(cutoffs)

  # decay
  decay_list <- assert_decay_function(decay_function, decay_value)

  # set r5r_core options ----------------------------------------------------

  # time window
  r5r_core$setTimeWindowSize(time_window)
  r5r_core$setPercentiles(percentiles)
  r5r_core$setCutoffs(cutoffs)

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


  # call r5r_core method ----------------------------------------------------

  accessibility <- r5r_core$accessibility(origins$id,
                                          origins$lat,
                                          origins$lon,
                                          destinations$id,
                                          destinations$lat,
                                          destinations$lon,
                                          opportunities_data,
                                          decay_list$fun,
                                          decay_list$value,
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
  accessibility <- jdx::convertToR(accessibility)
  accessibility <- data.table::rbindlist(accessibility)

  return(accessibility)
}
