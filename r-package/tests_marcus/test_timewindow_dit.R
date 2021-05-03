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
mode <- c("WALK", "BUS")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

time_window <- 1 # in minutes
percentiles <- 50

route_tw <- function(tw) {

  r5r_core$setTimeWindowSize(as.integer(tw))
  r5r_core$setNumberOfMonteCarloDraws(as.integer(tw * 5))

  # calculate travel time matrix
  dit <- detailed_itineraries(r5r_core, origins = origin, destinations = destination,
                              mode = mode, departure_datetime = departure_datetime,
                              drop_geometry = FALSE, shortest_path = TRUE) %>%
    mutate(time_window = tw)
}

dit_df <- route_tw(1)
dit_df <- rbind(
  route_tw(1),
  route_tw(15),
  route_tw(30),
  route_tw(60),
  route_tw(90),
  route_tw(120)
)


dit_df %>% mapview::mapview(zcol = "time_window")
dit_df %>% filter(time_window == 90) %>% mapview::mapview(zcol = "mode")

dit_60 <- dit_df %>% filter(time_window == 60)
dit_60 %>%
  mapview(zcol = "mode") +
  mapview(origin, xcol="lon", ycol="lat", crs=4326) +
  mapview(destination, xcol="lon", ycol="lat", crs=4326)
