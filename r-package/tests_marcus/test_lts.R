##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

library(r5r)
library(sf)
library(data.table)
library(ggplot2)
library(akima)
library(dplyr)
library(patchwork)

# system.file returns the directory with example data inside the r5r package
# set data path to directory containing your own data if not using the examples
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path, verbose = FALSE)

# read points of origin and destination
points <- fread(file.path(data_path, "poa_hexgrid.csv"))
# subset travel time matrix departing from a given origin
central_bus_stn <- points[291,]

# routing inputs
mode <- c("BICYCLE")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

time_window <- 1 # in minutes
percentiles <- 50

# find isochrone's bounding box to crop the map below
# bb_x <- c(min(travel_times.interp$x), max(travel_times.interp$x))
# bb_y <- c(min(travel_times.interp$y), max(travel_times.interp$y))

plot_lts <- function(bike_lts) {

  r5r_core$setMaxLevelTrafficStress(as.integer(bike_lts))


  # calculate travel time matrix
  computation_time <- system.time(ttm <- travel_time_matrix(r5r_core,
                                                            origins = central_bus_stn,
                                                            destinations = points,
                                                            mode = mode,
                                                            departure_datetime = departure_datetime,
                                                            max_walk_dist = max_walk_dist,
                                                            max_trip_duration = max_trip_duration,
                                                            time_window = time_window,
                                                            percentiles = percentiles,
                                                            verbose = FALSE))
  print(paste('travel time matrix computed in', computation_time[['elapsed']], 'seconds'))
  head(ttm)


  # extract OSM network
  street_net <- street_network_to_sf(r5r_core)

  # select trips departing the bus central station and add coordinates of destinations
  travel_times <- ttm[fromId %in% central_bus_stn$id]
  travel_times[points, on=c('toId' ='id'), `:=`(lon = i.lon, lat = i.lat)]

  # interpolate estimates to get spatially smooth result
  travel_times.interp <- with(na.omit(travel_times), interp(lon, lat, travel_time)) %>%
    with(cbind(travel_time=as.vector(z),  # Column-major order
               x=rep(x, times=length(y)),
               y=rep(y, each=length(x)))) %>%
    as.data.frame() %>% na.omit()


  # plot
  p <- ggplot(travel_times.interp) +
    geom_contour_filled(aes(x=x, y=y, z=travel_time), alpha=.8) +
    geom_sf(data = street_net$edges, color = "gray55", size=0.1, alpha = 0.7) +
    geom_point(aes(x=lon, y=lat, color='Central bus\nstation'), data=central_bus_stn) +
    scale_fill_viridis_d(direction = -1, option = 'B') +
    scale_color_manual(values=c('Central bus\nstation'='black')) +
    scale_x_continuous(expand=c(0,0)) +
    scale_y_continuous(expand=c(0,0)) +
    coord_sf(xlim = bb_x, ylim = bb_y) +
    labs(title = paste0("Isochrone, LTS ", bike_lts),
         fill = "travel time (minutes)", color='') +
    theme_minimal() +
    theme(axis.title = element_blank())

  return(p)
}

p_lts1 <- plot_lts(1)
p_lts2 <- plot_lts(2)
p_lts3 <- plot_lts(3)
p_lts4 <- plot_lts(4)

p_lts1 + p_lts2 + p_lts3 + p_lts4

# save plot
ggsave(file=sprintf('lts.jpeg', bike_lts),width = 24, height = 14, scale = 1.6,
       units = 'cm', dpi = 300 )


