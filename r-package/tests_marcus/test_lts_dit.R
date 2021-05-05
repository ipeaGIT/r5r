##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

library(r5r)
library(sf)
library(data.table)
library(dplyr)
library(mapview)

# system.file returns the directory with example data inside the r5r package
# set data path to directory containing your own data if not using the examples
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path, verbose = FALSE)

# Load points of interest
points <- read.csv(system.file("extdata/poa/poa_points_of_interest.csv", package = "r5r"))

# Configuring trip
origin <- points[10,] # Farrapos train station
destination <- points[12,] # Praia de Belas shopping mall

# routing inputs
mode <- c("BICYCLE")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

time_window <- 1 # in minutes
percentiles <- 50
bike_lts <- 2
route_lts <- function(bike_lts) {
  # r5r_core$setTimeWindowSize(1L)
  # r5r_core$setNumberOfMonteCarloDraws(5L)
  # r5r_core$setPercentiles(50L)
  # r5r_core$dropElevation()
  # calculate travel time matrix
  dit <- detailed_itineraries(r5r_core, origins = origin, destinations = destination,
                              mode = mode, departure_datetime = departure_datetime,
                              max_walk_dist = Inf, max_trip_duration = 140L,
                              max_lts = 4, verbose = TRUE, shortest_path = FALSE,
                              drop_geometry = FALSE) %>%
    mutate(lts = bike_lts)
}
dit %>% mapview::mapview(zcol="mode")
dit_df <- rbind(
  route_lts(1),
  route_lts(2),
  route_lts(3),
  route_lts(4)
)

edges <- r5r_core$getEdges()
edges <- jdx::convertToR(edges)
dit_df %>% mapview::mapview(zcol = "lts")
