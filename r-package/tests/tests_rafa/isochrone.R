### TO DO
# allow users to pass an sf points or polygons as "destination" input
# update entire documentation based on latest docs of r5r
# expose to users the same parameters available in travel_time_matrix()
  # max_trip_duration should be == to max(cutoffs)



#' Estimate the isochrones from a given location
#'
#' @description Fast computation of isochrones from a given location.
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
#' @param walk_speed numeric. Average walk speed in km/h. Defaults to 3.6 km/h.
#' @param bike_speed numeric. Average cycling speed in km/h. Defaults to 12 km/h.
#' @param max_rides numeric. The max number of public transport rides allowed in
#'                  the same trip. Defaults to 3.
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#' @param verbose logical. TRUE to show detailed output messages (the default)
#'                or FALSE to show only eventual ERROR messages.
#'
#' @return A `POLYGON  "sf" "data.frame"`
#'
#'
#' @family Isochrone
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
#' departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
#'                                  format = "%d-%m-%Y %H:%M:%S")
#'
#'# estimate travel time matrix
#'iso <- isochrone(r5r_core,
#'                 origin = origin,
#'                 mode = c("WALK", "TRANSIT"),
#'                 departure_datetime = departure_datetime,
#'                 cutoffs = c(0, 15, 30, 45, 60, 75, 90, 120),
#'                 max_walk_dist = Inf)
#'                 }
#'
#'
#'# prep grid with destinations
#'dest_points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
#'grid <- h3jsr::cell_to_polygon(input = dest_points$id, simple = FALSE)
#'grid$id <- dest_points$id
#'
#'
#'
#' @export

isochrone <- function(r5r_core,
                      origin,
                      destinations = NULL,
                      mode = "WALK",
                      departure_datetime = Sys.time(),
                      cutoffs = c(0, 15, 30, 45, 60),
                      max_walk_dist = Inf,
                      walk_speed = 3.6,
                      bike_speed = 12,
                      max_rides = 3,
                      n_threads = Inf,
                      verbose = TRUE){

# check inputs ------------------------------------------------------------

  # check cutoffs
  checkmate::assert_numeric(cutoffs, lower = 0)

  # max cutoff is used as max_trip_duration
  max_trip_duration = as.integer(max(cutoffs))

  # include 0 in cutoffs
  if (min(cutoffs) >0) {cutoffs <- sort(c(0, cutoffs))}


# IF no destinations input ------------------------------------------------------------

  if(is.null(destinations)){

    # use all network nodes as destination points
    network <- street_network_to_sf(r5r_core)
    destinations = network$vertices

    # sample proportion of nodes to reduce computation ?
    sample_size <- ifelse(nrow(destinations) < 10000, 1, .33) #
    index_sample <- sample(1:nrow(destinations), size = nrow(destinations) * sample_size, replace = FALSE)
    destinations <- destinations[index_sample,]

    names(destinations)[1] <- 'id'
    destinations$id <- as.character(destinations$id)


    # estimate travel time matrix
    ttm <- travel_time_matrix(r5r_core=r5r_core,
                                origins = origin,
                                destinations = destinations,
                                mode = mode,
                                departure_datetime = departure_datetime,
                                # max_walk_dist = max_walk_dist,
                                max_trip_duration = max_trip_duration,
                                progress = TRUE
                                # walk_speed = 3.6,
                                # bike_speed = 12,
                                # max_rides = max_rides,
                                # n_threads = n_threads,
                                # verbose = verbose
                              )


    # aggregate travel-times
    ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs)]

    # join ttm results to destinations
    dest <- subset(destinations, id %in% ttm$to_id)
    data.table::setDT(dest)[, id := as.character(id)]
    dest[ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]

    # # # points
    # dest[, .(geometry = st_union(geometry)) , by = isochrone] |>
    #   st_sf() |> sf::st_cast("POLYGON") |>
    #   ggplot(aes(geometry=geometry, color=isochrone)) +
    #   geom_sf() +
    #   coord_sf(crs=4326)
    #


    # build polygons with {concaveman}
    # obs. {isoband} is much slower
    dest <- sf::st_as_sf(dest)
    get_poly <- function(cut){ # cut = 45
      temp <- subset(dest, travel_time_p50 <= cut)
      temp_iso <- concaveman::concaveman(temp)
      temp_iso$isochrone <- cut
      return(temp_iso)
    }

    iso_list <- lapply(X=cutoffs[cutoffs>0], FUN=get_poly)
    iso <- data.table::rbindlist(iso_list)
    iso <- sf::st_sf(iso)
    iso <- iso[ order(-iso$isochrone), ]

    return(iso)
  }


# IF destinations input are polygons ------------------------------------------------------------

  if(!is.null(destinations)){

    # check input
    if (!any(class(destinations) %like% 'sf')) {stop("'destinations' must be of class 'sf' or 'sfc'")}
    if (!any(sf::st_geometry_type(destinations) %like% 'POLYGON')) {stop("'destinations' must have geometry type 'POLYGON'")}
    if (!'id' %in% names(destinations)) {stop("'destinations' must have an 'id' colum")}

    centroids <- sf::st_centroid(destinations)

    # estimate travel time matrix
    ttm <- travel_time_matrix(r5r_core=r5r_core,
                              origins = origin,
                              destinations = centroids,
                              mode = mode,
                              departure_datetime = departure_datetime,
                              # max_walk_dist = max_walk_dist,
                              max_trip_duration = max_trip_duration,
                              progress = TRUE
                              # walk_speed = 3.6,
                              # bike_speed = 12,
                              # max_rides = max_rides,
                              # n_threads = n_threads,
                              # verbose = verbose
                              )

    # aggregate travel-times
    ttm[, isochrone := cut(x=travel_time_p50, breaks=cutoffs)]

    # add isochrone cat to polygon of origin

    # join ttm results to destinations
    data.table::setDT(destinations)
    destinations[ttm, on=c('id' ='to_id'), c('travel_time_p50', 'isochrone') := list(i.travel_time_p50, i.isochrone)]

    destinations <- sf::st_as_sf(destinations)
    # ggplot() + geom_sf(data=destinations, aes(fill=isochrone), color=NA)

    return(destinations)
  }

}




