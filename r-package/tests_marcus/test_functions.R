options(java.parameters = '-Xmx16384m')

library(r5r)
library(ggplot2)
library(data.table)
library(tidyverse)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
dest <- points

points <- r5r_core$getGrid(11L)
points <- jdx::convertToR(points)
points$schools <- 1

dest <- points
dest <- dplyr::sample_n(points, 5000)

# system.time(
  access <- accessibility(r5r_core,
                        origins = points[1:200, ],
                        destinations = dest,
                        opportunities_colname = "schools",
                        mode = "BICYCLE",
                        cutoffs = c(25, 30),
                        max_bike_dist = 3000,
                        max_trip_duration = 30,
                        verbose = FALSE,
                        progress = TRUE)
# )

access %>% left_join(points, by = c("from_id" = "id")) %>%
  ggplot() +
  geom_point(aes(x=lon, y=lat, color = accessibility)) +
  scale_color_distiller(palette = "Spectral") +
  coord_map() +
  facet_wrap(~cutoff)


  ttm <- travel_time_matrix(r5r_core, origins = points[1:200, ],
                            destinations = dest,
                            mode = c("BICYCLE"),
                            max_trip_duration = 30,
                            max_walk_dist = 800,
                            verbose = FALSE,
                            progress = FALSE)


# system.time(
  dit <- detailed_itineraries(r5r_core,
                            origins =points,
                          destinations = points[1227:1,],
                          mode = c("BICYCLE"),
                          max_trip_duration = 60,
                          max_walk_dist = 800,
                          max_bike_dist = 800,
                          verbose = FALSE,
                          progress = FALSE,
                          drop_geometry = FALSE)
# )
dit %>% ggplot() + geom_sf()
mapview::mapview(points, xcol="lon", ycol="lat", crs = 4326)

street_net <- street_network_to_sf(r5r_core)
mapview::mapview(street_net$vertices)
mapview::mapview(street_net$edges)
street_net$vertices %>% filter(bike_sharing == TRUE)

transit_net <- transit_network_to_sf(r5r_core)
mapview::mapview(transit_net$stops %>% filter(linked_to_street == TRUE))
mapview::mapview(transit_net$routes)

snap <- r5r::find_snap(r5r_core, points)

system.time(ttm2 <- data.table::copy(ttm))

## raw ttm

v_from <- ttm$get("fromId")
jdx::convertToR(ttm$keySet())

ttm_dt <- data.table::data.table(fromId = ttm$get("fromId"),
                                 toId = ttm$get("toId"))
ttm_dt$travel_time <- ttm$get("travel_time")
head(ttm_dt, 10000) %>% View()

ttm$get("fromId")
ttm$get("fromId")

rJava::.jcall(obj = ttm, returnSig = "java/lang/Object", method = "get", "fromId")
system.time(ttm$get("fromId"))
.jcall("java/lang/System","S","getProperty","os.name")

system.time(r5r_core$buildVector(900000000L))

system.time(v <- r5r_core$v)
View(v)
v_dt <- data.table(v = v)

cat("Gathering results")
cat('\014')
message("Gathering results", appendLF = FALSE)






library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, overwrite = TRUE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# inputs
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

dit <- detailed_itineraries(r5r_core,
                            origins = points[10,],
                            destinations = points[12,],
                            mode = c("WALK", "TRANSIT"),
                            departure_datetime = departure_datetime,
                            max_walk_dist = 1000,
                            max_trip_duration = 120L,
                            verbose = FALSE)


head(dit)
mapview::mapview(dit)

transit_net <- transit_network_to_sf(r5r_core)
transit_net$routes %>% mapview::mapview()
