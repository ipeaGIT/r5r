tobler_hiking <- function(slope) {
  if (is.na(slope)) {slope = 0}
  if (slope < -1.0) {slope = 0}
  if (slope > 1.0) {slope = 0}

  C <- 1.19403

  tobler_factor <- C * exp(-3.5 * abs(slope+0.05))

  if (is.na(tobler_factor)) {
    return(1.0)
  } else {
    return(1 / tobler_factor)
  }
}

bike_climbing <- function(slope) {
  if (is.na(slope)) {slope = 0}
  # if (slope < 0) {slope = 0}
  # if (slope > 0.58) {slope = 0.58}

  bike_factor <- 1 + (11 * slope)

  if (is.na(bike_factor)) {
    return(1.0)
  } else {
    return(bike_factor)
  }
}

limit_slopes <- function(slope) {
  if (is.na(slope)) {slope = 0.0}
  if (slope < -1.0) {slope = 0.0}
  if (slope > 1.0) {slope = 0.0}
  return(slope)
}

# r5r_core = setup; raster_file = elev_file[1]; r5r_core$resetEdges()

apply_elevation <- function(r5r_core, raster_file) {
  elev <- raster(raster_file)

  edges <- r5r_core$getEdges()
  edges <- jdx::convertToR(edges)

  start_elev  <- raster::extract(elev, edges %>% dplyr::select(start_lon, start_lat))
  end_elev <- raster::extract(elev, edges %>% dplyr::select(end_lon, end_lat))

  edges$start_elev <- start_elev
  edges$end_elev <- end_elev

  edges <- edges %>% mutate(slope = (end_elev - start_elev) / length) %>%
    mutate(slope = map_dbl(slope, limit_slopes))

  edges <- edges %>% mutate(walk_multiplier = map_dbl(slope, tobler_hiking))

  bike_multipliers <- r5r_core$slopeSpeedCoefficient(edges$slope, edges$start_elev)
  edges$bike_multiplier <- 1 / bike_multipliers



  id <- as.integer(edges$edge_index)
  fct_walk <- as.double(edges$walk_multiplier)
  fct_bike <- as.double(edges$bike_multiplier)
  r5r_core$updateEdges(id, fct_walk, fct_bike)
}

# elev <- raster(system.file("extdata/poa/poa_elevation.tif", package = "r5r"))
# plot(elev)
#
# edges <- r5r_core$getEdges()
# edges <- jdx::convertToR(edges)
#
# start_elev  <- raster::extract(elev, edges %>% dplyr::select(start_lon, start_lat))
# end_elev <- raster::extract(elev, edges %>% dplyr::select(end_lon, end_lat))
#
# edges$start_elev <- start_elev
# edges$end_elev <- end_elev
#
# edges <- edges %>% mutate(slope = (end_elev - start_elev) / length,
#                           walk_multiplier = map_dbl(slope, tobler_hiking),
#                           bike_multiplier = map_dbl(slope, bike_climbing))
#
# edges %>%
#   ggplot(aes(x=slope, y=walk_multiplier)) +
#   geom_line() +
#   geom_vline(xintercept = 0)
# # edges %>%
# # Tobler's law
# # Formula: Speed = C * V * EXP(-3,5 * ABS(dh/dx+0,05))
# # Where:
# #
# #   C=1,19403 The maximum speed factor at -2,86 degrees.
# # V=1,33 The speed at flat terrain.
# # dx/dh The gradient (slope factor).
#
#
#
# id <- as.integer(edges$edge_index)
# fct_walk <- as.double(edges$walk_multiplier)
# fct_bike <- as.double(edges$bike_multiplier)
# r5r_core$updateEdges(id, fct_walk, fct_bike)
# r5r_core$resetEdges()
#
#
# edges %>%
#   filter(diff > 0) %>%
#   ggplot(aes(x=start_lon, y=start_lat, colour = dz)) +
#   geom_point(shape = ".") +
#   coord_map() +
#   scale_color_distiller(palette = "Spectral", trans = "log")
#
# # routing inputs
# mode <- c("BICYCLE")
# max_walk_dist <- 1000 # in meters
# max_trip_duration <- 60 # in minutes
# departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
#                                  format = "%d-%m-%Y %H:%M:%S")
#
# time_window <- 1 # in minutes
# percentiles <- 50
#
# plot_elev()
#
#
#
# plot_elev <- function() {
#
#   # calculate travel time matrix
#   computation_time <- system.time(ttm <- travel_time_matrix(r5r_core,
#                                                             origins = start_pt,
#                                                             destinations = points,
#                                                             mode = mode,
#                                                             departure_datetime = departure_datetime,
#                                                             max_walk_dist = max_walk_dist,
#                                                             max_trip_duration = max_trip_duration,
#                                                             time_window = time_window,
#                                                             percentiles = percentiles,
#                                                             verbose = FALSE))
#   print(paste('travel time matrix computed in', computation_time[['elapsed']], 'seconds'))
#   head(ttm)
#
#
#   # extract OSM network
#   street_net <- street_network_to_sf(r5r_core)
#
#   # select trips departing the bus central station and add coordinates of destinations
#   travel_times <- ttm[fromId %in% start_pt$id]
#   travel_times[points, on=c('toId' ='id'), `:=`(lon = i.lon, lat = i.lat)]
#
#   # interpolate estimates to get spatially smooth result
#   travel_times.interp <- with(na.omit(travel_times), interp(lon, lat, travel_time)) %>%
#     with(cbind(travel_time=as.vector(z),  # Column-major order
#                x=rep(x, times=length(y)),
#                y=rep(y, each=length(x)))) %>%
#     as.data.frame() %>% na.omit()
#
#
#   # plot
#   p <- ggplot(travel_times.interp) +
#     geom_contour_filled(aes(x=x, y=y, z=travel_time), alpha=.8) +
#     geom_sf(data = street_net$edges, color = "gray55", size=0.1, alpha = 0.7) +
#     geom_point(aes(x=lon, y=lat, color='Starting point'), data=start_pt) +
#     scale_fill_viridis_d(direction = -1, option = 'B') +
#     scale_color_manual(values=c('Central bus\nstation'='black')) +
#     scale_x_continuous(expand=c(0,0)) +
#     scale_y_continuous(expand=c(0,0)) +
#     labs(title = "Isochrone with elevation",
#          fill = "travel time (minutes)", color='') +
#     theme_minimal() +
#     theme(axis.title = element_blank())
#
#   return(p)
# }
#
#
#
