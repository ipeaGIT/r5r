# utils::remove.packages('r5r')
# devtools::install_github("ipeaGIT/r5r", subdir = "r-package", ref = "dev")

#' Testing r5r 0.5-0 new features:
#' - Isochrone
#' - Topography

#' To test this, you need to install r5r from the dev branch:
# utils::remove.packages('r5r')
# devtools::install_github("ipeaGIT/r5r", subdir = "r-package", ref = "dev")


# allocate RAM memory to Java
options(java.parameters = "-Xmx6G")

library(r5r)
library(tidyverse)
library(sf)
library(mapview)
library(leafsync)

# helper function
build_isochrone <- function(mode, terrain) {

  max_walk_dist <- 800   # meters
  max_trip_duration <- 60 # minutes
  departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                   format = "%d-%m-%Y %H:%M:%S")

  iso <- isochrones(r5r_core,
                    origins = origins,
                    cutoffs = seq(5, 30, 5),
                    mode = mode,
                    zoom = 11L,
                    departure_datetime = departure_datetime,
                    max_trip_duration = max_trip_duration,
                    max_walk_dist = max_walk_dist,
                    max_lts = 2,
                    verbose = FALSE)

  iso <- iso %>%
    mutate(mode = paste(str_to_lower(mode), collapse = ", "),
           terrain = terrain)

  return(iso)

}

# load data and build transport network
path <- system.file("extdata/poa", package = "r5r")
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
poi <- read.csv(system.file("extdata/poa/poa_points_of_interest.csv", package = "r5r"))
origins = poi[1,]

r5r_core <- setup_r5(data_path = path, verbose = FALSE)

# calculate isochrones with topography enabled
iso_walk <- build_isochrone(mode = c("WALK"), terrain = "topo")
iso_bus <- build_isochrone(mode = c("WALK", "BUS"), terrain = "topo")
iso_bike <- build_isochrone(mode = c("BICYCLE"), terrain = "topo")

# flatten the terrain
r5r_core$dropElevation()

# calculate isochrones on flat terrain
iso_walk_flat <- build_isochrone(mode = c("WALK"), terrain = "flat")
iso_bus_flat <- build_isochrone(mode = c("WALK", "BUS"), terrain = "flat")
iso_bike_flat <- build_isochrone(mode = c("BICYCLE"), terrain = "flat")

# build mapviews

mv_walk <- iso_walk %>% mapview(zcol = "cutoff", layer.name = "walk topo")
mv_bike <- iso_bike %>% mapview(zcol = "cutoff", layer.name = "bike topo")
mv_bus <- iso_bus %>% mapview(zcol = "cutoff", layer.name = "bus topo")

mv_walk_flat <- iso_walk_flat %>% mapview(zcol = "cutoff", layer.name = "walk flat")
mv_bike_flat <- iso_bike_flat %>% mapview(zcol = "cutoff", layer.name = "bike flat")
mv_bus_flat <- iso_bus_flat %>% mapview(zcol = "cutoff", layer.name = "bus flat")

# mapview small multiples
sync(mv_walk, mv_bike, mv_bus, mv_walk_flat, mv_bike_flat, mv_bus_flat, ncol = 3)


