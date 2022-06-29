# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
# library(ggplot2)
library(data.table)
library(tidyverse)
# build transport network
# data_path <- system.file("extdata/spo", package = "r5r")
data_path <- system.file("extdata/poa", package = "r5r")
data_path <- paste0(data_path, "/../../extdata/poa")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# points <- fread(file.path(data_path, "spo_hexgrid.csv"))
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
# points <- fread(file.path(data_path, "poa_hexgrid.csv"))
# dest <- points

# dir.create(here::here("csv"))

# r5r_core$setCsvOutput(here::here("csv"))

  normal_ttm <- travel_time_matrix(r5r_core, origins = points, #[id == "89a9012a3cfffff",],
                                   destinations = points, #[id == "89a901284a3ffff",],
                            mode = c("CAR", "TRANSIT"),
                            departure_datetime = departure_datetime,
                            max_trip_duration = 60,
                            max_walk_time = 15,
                            time_window = 30,
                            percentiles = c(1, 25, 50, 75, 99),
                            verbose = FALSE,
                            progress = TRUE)

  ttm2 <- travel_time_matrix(r5r_core, origins = points, #[id == "89a9012a3cfffff",],
                                   destinations = points, #[id == "89a901284a3ffff",],
                                   mode = c("CAR", "TRANSIT"),
                                   departure_datetime = departure_datetime,
                                   max_trip_duration = 60,
                                   max_walk_time = 15,
                                   time_window = 30,
                                   percentiles = c(1, 25, 50, 75, 99),
                                   verbose = FALSE,
                                   progress = TRUE)

  ttm3 <- travel_time_matrix(r5r_core, origins = points, #[id == "89a9012a3cfffff",],
                                   destinations = points, #[id == "89a901284a3ffff",],
                                   mode = c("CAR", "TRANSIT"),
                                   departure_datetime = departure_datetime,
                                   max_trip_duration = 60,
                                   max_walk_time = 15,
                             max_car_time = 15,
                                   time_window = 30,
                                   percentiles = c(1, 25, 50, 75, 99),
                                   verbose = FALSE,
                                   progress = TRUE)

  dit <- detailed_itineraries(r5r_core, origins = points[5,], #[id == "89a9012a3cfffff",],
                              destinations = points[11,], #[id == "89a901284a3ffff",],
                              mode = c("CAR", "TRANSIT"),
                              departure_datetime = departure_datetime,
                              max_trip_duration = 60,
                              max_walk_time = 15,
                              max_car_time = 15,
                              time_window = 30,
                              verbose = FALSE,
                              progress = TRUE)

  mapview::mapview(dit, zcol="mode")
