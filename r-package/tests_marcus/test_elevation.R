options(java.parameters = "-Xmx8G")

devtools::load_all(".")
# library(r5r)
library(sf)
library(data.table)
library(tidyverse)
library(raster)
library(akima)


# system.file returns the directory with example data inside the r5r package
# set data path to directory containing your own data if not using the examples
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path, verbose = FALSE)

# read points of origin and destination
points <- fread(file.path(data_path, "poa_hexgrid.csv"))
poi <- fread(file.path(data_path, "poa_points_of_interest.csv"))
# subset travel time matrix departing from a given origin
start_pt <- poi[1,]

# routing inputs
mode <- c("WALK", "BUS")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")
cutoffs <- seq(5, 30, 5)

iso <- isochrones(r5r_core,
                  origins = start_pt,
                  mode = mode,
                  cutoffs = cutoffs,
                  departure_datetime = departure_datetime,
                  max_walk_dist = max_walk_dist,
                  max_trip_duration = max_trip_duration,
                  verbose = FALSE)

r5r_core$resetEdges()
iso_flat <- isochrones(r5r_core,
                       origins = start_pt,
                       mode = mode,
                       cutoffs = cutoffs,
                       departure_datetime = departure_datetime,
                       max_walk_dist = max_walk_dist,
                       max_trip_duration = max_trip_duration,
                       verbose = FALSE)

rbind(
  iso %>% mutate(terrain="dem"),
  iso_flat %>% mutate(terrain="flat")) %>%
  ggplot() +
  geom_sf(aes(fill=cutoff)) +
  scale_fill_distiller(direction=-1) +
  facet_wrap(~terrain)




