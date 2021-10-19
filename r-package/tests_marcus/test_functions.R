options(java.parameters = '-Xmx16384m')
options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

library(r5r)
library(ggplot2)
library(data.table)
library(tidyverse)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = TRUE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# poi <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
# points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# points <- points %>%
#   st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
#   st_transform(31982)

# dest <- points

points <- r5r_core$getGrid(11L)
points <- jdx::convertToR(points$getDataFrame())
points$schools <- 1

dest <- points
# dest <- dplyr::sample_n(points, 5000)

## params

# origins = points
# destinations = dest
# opportunities_colname = "schools"
# mode = "WALK"
# mode_egress = "WALK"
# cutoffs = c(25, 30)
# time_window = 1L
# percentiles = 50L
# decay_function = "step"
# decay_value = 1.0
# max_trip_duration = 30
# max_walk_dist = Inf
# max_bike_dist = Inf
# walk_speed = 3.6
# bike_speed = 12
# max_rides = 3
# max_lts = 2
# n_threads = Inf
# verbose = FALSE
# progress = TRUE
# shortest_path = TRUE


## params

r5r_core$setBenchmark(TRUE)
system.time(
  access <- accessibility(r5r_core,
                        origins = points,
                        destinations = dest,
                        opportunities_colname = "schools",
                        mode = "WALK",
                        cutoffs = c(25, 30),
                        max_trip_duration = 30,
                        verbose = FALSE)
)

system.time(
  ttm <- travel_time_matrix(r5r_core, origins = points,
                            destinations = dest,
                            mode = c("WALK", "TRANSIT"),
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 30,
                            percentiles = c(25, 50, 75),
                            verbose = FALSE)
)
#
# system.time(
#   dit <- detailed_itineraries(r5r_core,
#                             origins =poi[1:15,],
#                           destinations = points[15:1,],
#                           mode = c("TRANSIT"),
#                           max_trip_duration = 60,
#                           max_walk_dist = 1000,
#                           max_bike_dist = 1000,
#                           verbose = FALSE,
#                           drop_geometry = FALSE,
#                           departure_datetime = departure_datetime)
# )
# dit %>% ggplot() + geom_sf()
# mapview::mapview(points, xcol="lon", ycol="lat", crs = 4326)
# mapview::mapview(dit, crs = 4326, zcol = "fromId")
#
# street_net <- street_network_to_sf(r5r_core)
# mapview::mapview(street_net$vertices)
# mapview::mapview(street_net$edges)
#
# transit_net <- transit_network_to_sf(r5r_core)
# mapview::mapview(transit_net$stops |> filter(linked_to_street == TRUE))
# mapview::mapview(transit_net$routes)
#
# snap <- r5r::find_snap(r5r_core, points)
# snap %>% mapview::mapview(xcol="snap_lon", ycol="snap_lat", zcol="distance", crs=4326)
# system.time(ttm2 <- data.table::copy(ttm))
#
# ## raw ttm
#
# grid <- r5r_core$getGrid(9L)
# g <- java_to_dt(grid)
#
# gsnap <- r5r::find_snap(r5r_core, g)
# gsnap %>% mapview::mapview(xcol="snap_lon", ycol="snap_lat", zcol="distance", crs=4326)
# gsnap %>% mapview::mapview(xcol="lon", ycol="lat", zcol="found", crs=4326)
#
# g <- jdx::convertToR(grid$getDataFrame())
# g <- data.table::data.table(g)
# v_from <- ttm$get("fromId")
# jdx::convertToR(ttm$keySet())
#
# ttm_dt <- data.table::data.table(fromId = ttm$get("fromId"),
#                                  toId = ttm$get("toId"))
# ttm_dt$travel_time <- ttm$get("travel_time")
# head(ttm_dt, 10000) %>% View()
#
# ttm$get("fromId")
# ttm$get("fromId")
#
# rJava::.jcall(obj = ttm, returnSig = "java/lang/Object", method = "get", "fromId")
# system.time(ttm$get("fromId"))
# .jcall("java/lang/System","S","getProperty","os.name")
#
# system.time(r5r_core$buildVector(900000000L))
#
# system.time(v <- r5r_core$v)
# View(v)
# v_dt <- data.table(v = v)
#
# cat("Gathering results")
# cat('\014')
# message("Gathering results", appendLF = FALSE)
#
#
# system.time(
#   dit <- detailed_itineraries(r5r_core,
#                               origins =poi[10,],
#                               destinations = poi[12,],
#                               mode = c("WALK"),
#                               max_trip_duration = 30,
#                               max_walk_dist = 1000,
#                               max_bike_dist = 1000,
#                               verbose = FALSE,
#                               drop_geometry = FALSE,
#                               departure_datetime = departure_datetime)
# )
