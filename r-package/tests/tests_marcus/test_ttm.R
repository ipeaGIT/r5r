# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
# library(ggplot2)
library(data.table)
library(tidyverse)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

poi <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
# points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
# dest <- points

system.time(
  normal_ttm <- travel_time_matrix(r5r_core, origins = poi,
                            destinations = poi,
                            mode = c("WALK", "TRANSIT"),
                            breakdown = FALSE,
                            departure_datetime = departure_datetime,
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 30,
                            percentiles = c(1, 25, 50, 75, 99),
                            verbose = FALSE,
                            progress = TRUE)
)


system.time(
  expanded_ttm <- expanded_travel_time_matrix(r5r_core, origins = poi,
                                   destinations = poi,
                                   mode = c("WALK", "TRANSIT"),
                                   breakdown = F,
                                   departure_datetime = departure_datetime,
                                   max_trip_duration = 60,
                                   max_walk_dist = 800,
                                   time_window = 30,
                                   verbose = FALSE,
                                   progress = TRUE)
)
