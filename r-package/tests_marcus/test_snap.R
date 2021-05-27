# library(tidyverse)
options(java.parameters = '-Xmx10G')
devtools::load_all(".")
library(r5r)
library(sf)
library(tidyverse)
library(mapview)

# initialize r5r
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE, use_elevation = TRUE)

# get regular grid at resolution 8
  grid_df <- r5r_core$getGrid(8L, TRUE)
  grid_df <- jdx::convertToR(grid_df)


# grid_df$geometry <- st_as_sfc(grid_df$geometry)
# grid_df <- st_as_sf(grid_df, crs = 4326)

grid_df %>%
  mapview(xcol="lon", ycol="lat", crs=4326)

grid_df %>% mutate(id = as.integer(id)) %>% mapview::mapview(alpha.regions = 0)
  mapview::mapview(snap_df, xcol="lon", ycol="lat")
  mapview::mapview(snap_df %>% filter(point_id=="4"), xcol="snap_lon", ycol="snap_lat")

r5r_core$silentMode()
system.time(
  snap_df <- find_snap(r5r_core, grid_df, "WALK")
)


mapview::mapview(snap_df, xcol="lon", ycol="lat", crs=4326)
mapview::mapview(snap_df %>% drop_na(), xcol="snap_lon", ycol="snap_lat", zcol="distance", crs=4326)

leafsync::sync(mv1, mv2)


original <- snap_df %>% select(id = point_id, lat, lon)
snapped <- snap_df %>% select(id = point_id, lat = snap_lat, lon = snap_lon)

system.time(
  ttm_orig <- travel_time_matrix(r5r_core, origins = original, destinations = original,
                                 verbose = FALSE)
)

ttm_snap <- travel_time_matrix(r5r_core, origins = snapped, destinations = snapped,
                          verbose = FALSE)

ttm_join <- left_join(ttm_orig, ttm_snap, by=c("fromId", "toId"),
                      suffix = c("_or", "_sn"))

street_net <- street_network_to_sf(r5r_core)

street_net$vertices %>% mapview()
street_net$edges %>% ggplot() + geom_sf()

hex <- read_csv(system.file("extdata/poa", "poa_hexgrid.csv", package = "r5r"))

hex %>%
  mapview(xcol="lon", ycol="lat", crs=4326)

min(hex$lat)

departure_datetime <- as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

ttm <- travel_time_matrix(r5r_core, origins = grid_df[20000,], destinations = grid_df,
                          departure_datetime = departure_datetime,
                          mode = c("BICYCLE"), max_trip_duration = 30,
                          max_walk_dist = 800)

ttm %>% left_join(grid_df, by = c("toId"="id")) %>%
  mutate(travel_time = travel_time %/% 2) %>%
  st_as_sf(crs = 4326) %>%
  mapview(zcol="travel_time")
  ggplot() +
  geom_sf(aes(geometry=geometry, fill=travel_time), color=NA) +
  scale_fill_distiller(palette = "Spectral")

View()
grid_df


original <- dplyr::select(snap_df, id = point_id, lat, lon)
original$opportunities <- 1

system.time(
  ttm_orig <- accessibility(r5r_core, origins = original, destinations = original,
                            verbose = FALSE)
)
