options(java.parameters = "-Xmx16G")

devtools::load_all(".")
# library(r5r)
library(tidyverse)
library(sf)
library(data.table)
library(mapview)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)

points <- fread(file.path(data_path, "poa_hexgrid.csv"))
poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
origins <- poi[c(1, 3, 10, 15),]
# origins <- poi[1, ]

# routing inputs
mode <- c("WALK", "BUS")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

cutoffs = c(1, 5, seq(10, 60, 10))
cutoffs = c(20)
iso <- isochrones(r5r_core,
                  origins = origins,
                  cutoffs = cutoffs,
                  zoom = 11L,
                  mode = mode,
                  max_walk_dist = max_walk_dist,
                  max_trip_duration = max_trip_duration,
                  departure_datetime = departure_datetime,
                  verbose = FALSE)

iso %>%
  mutate(cutoff = factor(cutoff)) %>%
  ggplot() + geom_sf(aes(fill=cutoff)) +
  scale_fill_brewer(direction = -1) +
  facet_wrap(~from_id)


snap_df <- r5r_core$findSnapPoints(points$id, points$lat, points$lon)
snap_df <- jdx::convertToR(snap_df)

mapview(snap_df, xcol="lon", ycol="lat", crs = 4326, color = "green") +
mapview(snap_df, xcol="snap_lon", ycol="snap_lat", crs = 4326, color = "red")
