# library(tidyverse)
options(java.parameters = '-Xmx10G')
library(r5r)
library(sf)
library(tidyverse)
library(mapview)

# initialize r5r
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)

# get regular grid at resolution 8
grid_df <- r5r_core$getGrid(11L)
grid_df <- jdx::convertToR(grid_df)
grid_df$geometry <- st_as_sfc(grid_df$geometry)
grid_df <- st_as_sf(grid_df, crs = 4326)

grid_df %>% mutate(id = as.integer(id)) %>% mapview::mapview(zcol = "id")
  mapview::mapview(snap_df %>% filter(point_id=="4"), xcol="lon", ycol="lat") +
  mapview::mapview(snap_df %>% filter(point_id=="4"), xcol="snap_lon", ycol="snap_lat")


# snap grid to street network
snap_df <- r5r_core$findSnapPoints(grid_df$id, grid_df$lat, grid_df$lon, "WALK")
snap_df <- jdx::convertToR(snap_df)
snap_df <- snap_df %>%
  filter(found == TRUE)

mapview::mapview(snap_df, xcol="lon", ycol="lat", crs=4326) +
mapview::mapview(snap_df, xcol="snap_lon", ycol="snap_lat", zcol="found", crs=4326)

leafsync::sync(mv1, mv2)


original <- snap_df %>% select(id = point_id, lat, lon)
snapped <- snap_df %>% select(id = point_id, lat = snap_lat, lon = snap_lon)

ttm_orig <- travel_time_matrix(r5r_core, origins = original, destinations = original,
                          verbose = FALSE)

ttm_snap <- travel_time_matrix(r5r_core, origins = snapped, destinations = snapped,
                          verbose = FALSE)

ttm_join <- left_join(ttm_orig, ttm_snap, by=c("fromId", "toId"),
                      suffix = c("_or", "_sn"))

street_net <- street_network_to_sf(r5r_core)

street_net$vertices %>% mapview() +
street_net$edges %>% mapview()

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
