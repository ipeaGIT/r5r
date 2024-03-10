#' Estimate isochrones from a given location
#'
#' @description Fast computation of isochrones from a given location. The
#' function estimates isochrones based on the travel times from the trip origin
#' to all nodes in the road network.
#'
#'
#' @template r5r_core
#' @param origins Either a `POINT sf` object with WGS84 CRS, or a
#'        `data.frame` containing the columns `id`, `lon` and `lat`.
#' @param cutoffs numeric vector. Number of minutes to define the time span of
#'        each Isochrone. Defaults to `c(0, 15, 30)`.
#' @param sample_size numeric. Sample size of nodes in the road network used to
#'        estimate isochrones. Defaults to `0.8` (80% of all nodes in the
#'        transport network). Value can range between `0.2` and `1`. Smaller
#'        values increase computation speed but return results with lower
#'        precision.
#' @param mode A character vector. The transport modes allowed for access,
#'        transfer and vehicle legs of the trips. Defaults to `WALK`. Please see
#'        details for other options.
#' @param mode_egress A character vector. The transport mode used after egress
#'        from the last public transport. It can be either `WALK`, `BICYCLE` or
#'        `CAR`. Defaults to `WALK`. Ignored when public transport is not used.
#' @param departure_datetime A POSIXct object. Please note that the departure
#'        time only influences public transport legs. When working with public
#'        transport networks, please check the `calendar.txt` within your GTFS
#'        feeds for valid dates. Please see details for further information on
#'        how datetimes are parsed.
#' @param time_window An integer. The time window in minutes for which `r5r`
#'        will calculate multiple travel time matrices departing each minute.
#'        Defaults to 10 minutes. The function returns the result based on
#'        median travel times. Please read the time window vignette for more
#'        details on its usage `vignette("time_window", package = "r5r")`
#' @param max_walk_time An integer. The maximum walking time (in minutes) to
#'        access and egress the transit network, or to make transfers within the
#'        network. Defaults to no restrictions, as long as `max_trip_duration`
#'        is respected. The max time is considered separately for each leg (e.g.
#'        if you set `max_walk_time` to 15, you could potentially walk up to 15
#'        minutes to reach transit, and up to _another_ 15 minutes to reach the
#'        destination after leaving transit). Defaults to `Inf`, no limit.
#' @param max_bike_time An integer. The maximum cycling time (in minutes) to
#'        access and egress the transit network. Defaults to no restrictions, as
#'        long as `max_trip_duration` is respected. The max time is considered
#'        separately for each leg (e.g. if you set `max_bike_time` to 15 minutes,
#'        you could potentially cycle up to 15 minutes to reach transit, and up
#'        to _another_ 15 minutes to reach the destination after leaving
#'        transit). Defaults to `Inf`, no limit.
#' @param max_car_time An integer. The maximum driving time (in minutes) to
#'        access and egress the transit network. Defaults to no restrictions, as
#'        long as `max_trip_duration` is respected. The max time is considered
#'        separately for each leg (e.g. if you set `max_car_time` to 15 minutes,
#'        you could potentially drive up to 15 minutes to reach transit, and up
#'        to _another_ 15 minutes to reach the destination after leaving transit).
#'        Defaults to `Inf`, no limit.
#' @param max_trip_duration An integer. The maximum trip duration in minutes.
#'        Defaults to 120 minutes (2 hours).
#' @param walk_speed A numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed A numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides An integer. The maximum number of public transport rides
#'        allowed in the same trip. Defaults to 3.
#' @param max_lts An integer between 1 and 4. The maximum level of traffic
#'        stress that cyclists will tolerate. A value of 1 means cyclists will
#'        only travel through the quietest streets, while a value of 4 indicates
#'        cyclists can travel through any road. Defaults to 2. Please see
#'        details for more information.
#' @template draws_per_minute
#' @param n_threads An integer. The number of threads to use when running the
#'        router in parallel. Defaults to use all available threads (`Inf`).
#' @param progress A logical. Whether to show a progress counter when running
#'        the router. Defaults to `FALSE`. Only works when `verbose` is set to
#'        `FALSE`, so the progress counter does not interfere with `R5`'s output
#'        messages. Setting `progress` to `TRUE` may impose a small penalty for
#'        computation efficiency, because the progress counter must be
#'        synchronized among all active threads.
#' @template verbose
#'
#' @return A `POLYGON  "sf" "data.frame"` for each isochrone of each origin.
#'
#' @template transport_modes_section
#' @template lts_section
#' @template datetime_parsing_section
#' @template raptor_algorithm_section
#'
#' @family Isochrone
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' options(java.parameters = "-Xmx2G")
#' library(r5r)
#'
#' # build transport network
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = data_path)
#'
#' # load origin/point of interest
#' points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#' origin_1 <- points[936,]
#'
#' departure_datetime <- as.POSIXct(
#'   "13-05-2019 14:00:00",
#'   format = "%d-%m-%Y %H:%M:%S"
#' )
#'
#'# estimate isochrone from origin_1
#'iso1 <- isochrone(r5r_core,
#'                 origins = origin_1,
#'                 mode = c("walk"),
#'                 departure_datetime = departure_datetime,
#'                 cutoffs = seq(0, 100, 10)
#'                 )
#'head(iso1)
#'
#'colors <- c('#ffe0a5','#ffcb69','#ffa600','#ff7c43','#f95d6a',
#'            '#d45087','#a05195','#665191','#2f4b7c','#003f5c')
#'plot(iso1['isochrone'], col = colors)
#'
#'stop_r5(r5r_core)
#'
#' @export
isochrone <- function(r5r_core,
                      origins,
                      mode = "transit",
                      mode_egress = "WALK",
                      cutoffs = c(0, 15, 30),
                      sample_size = 0.8,
                      departure_datetime = Sys.time(),
                      time_window = 10L,
                      max_walk_time = Inf,
                      max_bike_time = Inf,
                      max_car_time = Inf,
                      max_trip_duration = 120L,
                      walk_speed = 3.6,
                      bike_speed = 12,
                      max_rides = 3,
                      max_lts = 2,
                      draws_per_minute = 5L,
                      n_threads = Inf,
                      verbose = FALSE,
                      progress = TRUE){


# check inputs ------------------------------------------------------------

  # check cutoffs
  checkmate::assert_numeric(cutoffs, lower = 0)

  # check sample_size
  checkmate::assert_numeric(sample_size, lower = 0.2, upper = 1, max.len = 1)


  # max cutoff is used as max_trip_duration
  max_trip_duration = as.integer(max(cutoffs))

  # include 0 in cutoffs
  if (min(cutoffs) > 0) {cutoffs <- sort(c(0, cutoffs))}


# IF no destinations input ------------------------------------------------------------

    # use all network nodes as destination points
    network <- r5r::street_network_to_sf(r5r_core)
    destinations = network$vertices

    # sample size: proportion of nodes to be considered
    index_sample <- sample(1:nrow(destinations),
                           size = nrow(destinations) * sample_size,
                           replace = FALSE)
    destinations <- destinations[index_sample,]
    on.exit(rm(.Random.seed, envir=globalenv()))


    names(destinations)[1] <- 'id'
    destinations$id <- as.character(destinations$id)


    # estimate travel time matrix
    ttm <- travel_time_matrix(r5r_core = r5r_core,
                              origins = origins,
                              destinations = destinations,
                              mode = mode,
                              mode_egress = mode_egress,
                              departure_datetime = departure_datetime,
                              time_window = time_window,
                              # percentiles = percentiles,
                              max_walk_time = max_walk_time,
                              max_bike_time = max_bike_time,
                              max_car_time = max_car_time,
                              max_trip_duration = max_trip_duration,
                              walk_speed = walk_speed,
                              bike_speed = bike_speed,
                              max_rides = max_rides,
                              max_lts = max_lts,
                              draws_per_minute = draws_per_minute,
                              n_threads = n_threads,
                              verbose = verbose,
                              progress = progress
                              )


    # aggregate travel-times
    ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs)]

    # fun to get isochrones for each origin
    prep_iso <- function(orig){ # orig = '89a901280b7ffff'

      temp_ttm <- subset(ttm, from_id == orig)

      # join ttm results to destinations
      dest <- subset(destinations, id %in% temp_ttm$to_id)
      data.table::setDT(dest)[, id := as.character(id)]
      dest[temp_ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]

      # build polygons with {concaveman}
      # obs. {isoband} is much slower
      dest <- sf::st_as_sf(dest)

      get_poly <- function(cut){ # cut = 30
        temp <- subset(dest, travel_time_p50 <= cut)
        temp_iso <- concaveman::concaveman(temp)
        temp_iso$isochrone <- cut
        return(temp_iso)
      }

      iso_list <- lapply(X=cutoffs[cutoffs>0], FUN=get_poly)
      iso <- data.table::rbindlist(iso_list)
      iso$id <- orig
      iso <- sf::st_sf(iso)
      iso <- iso[ order(-iso$isochrone), ]
      data.table::setcolorder(iso, c('id', 'isochrone'))
      # plot(iso)
      return(iso)
    }

    # get the isocrhone from each origin
    iso_list <- lapply(X = unique(origins$id), FUN = prep_iso)

    # put output together
    iso <- data.table::rbindlist(iso_list)
    iso <- sf::st_sf(iso)

    # remove data.table from class
    class(iso) <- c("sf", "data.frame")
    return(iso)
  }
