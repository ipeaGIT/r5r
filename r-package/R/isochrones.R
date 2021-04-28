#' Produce isochrones for a set of origin points and cutoff travel times
#'
#' @description Creation of isochrones.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param origins a spatial sf POINT object, or a data.frame
#'                containing the columns 'id', 'lon', 'lat'
#' @param mode string. Transport modes allowed for the trips. Defaults to
#'             "WALK". See details for other options.
#' @param mode_egress string. Transport mode used after egress from public
#'                    transport. It can be either 'WALK', 'BICYCLE', or 'CAR'.
#'                    Defaults to "WALK".
#' @param departure_datetime POSIXct object. If working with public transport
#'                           networks, please check \code{calendar.txt} within
#'                           the GTFS file for valid dates.
#' @param max_walk_dist numeric. Maximum walking distance (in meters) for the
#'                      whole trip. Defaults to no restrictions on walking, as
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
#' @param verbose logical. TRUE to show detailed output messages (the default)
#'                or FALSE to show only eventual ERROR messages.
#' @param cutoffs numeric. Cutoff times, in minutes, for isochrone calculation.
#' @param zoom numeric. Scale of the Web Mercator grid where travel times will
#'             be computed. Defaults to 11.
#'
#' @return A data.table with travel time estimates (in minutes) between origin
#' destination pairs by a given transport mode. Note that origins/destinations
#' that were beyond the maximum travel time, and/or origins that were far from
#' the street network are not returned in the data.table.
#'
#' @details
#'  # Transpor modes:
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
#' @family routing
#' @examples if (interactive()) {
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/spo", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))[1:5,]
#'
#' departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
#'
#' # estimate travel time matrix
#' ttm <- travel_time_matrix(r5r_core,
#'                           origins = points,
#'                           destinations = points,
#'                           mode = c("WALK", "TRANSIT"),
#'                           departure_datetime = departure_datetime,
#'                           max_walk_dist = Inf,
#'                           max_trip_duration = 120L)
#'
#' stop_r5(r5r_core)
#'
#' }
#' @export

isochrones <- function(r5r_core,
                      origins,
                      cutoffs = c(15L, 30L, 45L, 60L),
                      zoom = 11,
                      mode = "WALK",
                      mode_egress = "WALK",
                      departure_datetime = Sys.time(),
                      max_walk_dist = Inf,
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

  # max_walking_distance and max_street_time
  max_street_time <- set_max_street_time(max_walk_dist,
                                         walk_speed,
                                         max_trip_duration)

  # origins and destinations
  origins <- assert_points_input(origins, "origins")

  # cutoff times
  checkmate::assert_numeric(cutoffs)
  cutoffs = as.integer(cutoffs)

  # zoom
  checkmate::assert_numeric(zoom)
  zoom = as.integer(zoom)

  # set r5r_core options ----------------------------------------------------

  # time window
  r5r_core$setTimeWindowSize(1L)
  r5r_core$setPercentiles(50L)
  r5r_core$setNumberOfMonteCarloDraws(1L)

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
  isochrones <- r5r_core$isochrones(origins$id,
                                    origins$lat,
                                    origins$lon,
                                    cutoffs,
                                    zoom,
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
  isochrones <- jdx::convertToR(isochrones)
  # r5r_core returns a list when multiple origins are provided, in which case
  # they need to be combined into a single data.table
  if (!is.data.frame(isochrones)) isochrones <- data.table::rbindlist(isochrones)

  # convert to SF and fix geometries (sometimes, R5 produces self-intersecting
  # polygons)
  isochrones$geometry <- sf::st_as_sfc(isochrones$geometry)
  isochrones <- sf::st_as_sf(isochrones) %>% sf::st_make_valid()

  # each isochrone is a full polygon which contains all lower cutoff isochrones
  # we need to cut holes isochrone to avoid overlapping geometries
  isochrones <- isochrones %>%
    dplyr::group_by(from_id) %>%
    dplyr::mutate(geom = dplyr::lag(geometry)) %>%
    dplyr::mutate(geometry = purrr::map2(geometry, geom, sf::st_difference)) %>%
    dplyr::select(-geom) %>%
    dplyr::filter(!sf::st_is_empty(geometry))
  # CRS = WGS 84
  sf::st_crs(isochrones) <- 4326

  return(isochrones)
}
