# options(java.parameters = '-Xmx2G')

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)

# build transport network
data_path <- system.file("extdata/spo", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = TRUE, overwrite = TRUE,
                     temp_dir = FALSE)

# load origin/destination points
points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))

# r5r_core$setTravelTimesBreakdown(FALSE)
ttm_flat_walk <- travel_time_matrix(r5r_core,
                            origins = points,
                            destinations = points,
                            mode = c("WALK", "TRANSIT"),
                            max_trip_duration = 60,
                            max_walk_dist = Inf,
                            time_window = 1,
                            percentiles = c(50),
                            verbose = FALSE,
                            progress = TRUE)


ttm_flat_bike <- travel_time_matrix(r5r_core,
                                    origins = points,
                                    destinations = points,
                                    breakdown = FALSE,
                                    mode = c("BICYCLE"),
                                    max_trip_duration = 60,
                                    max_walk_dist = Inf,
                                    time_window = 1,
                                    percentiles = c(50),
                                    verbose = FALSE,
                                    progress = TRUE)

ttm_flat_walk$scenario <- "flat"
ttm_flat_walk$mode <- "walk"
ttm_flat_bike$scenario <- "flat"
ttm_flat_bike$mode <- "bike"

write_csv(ttm_flat_walk, here::here("elevation", "walk_flat.csv"))
write_csv(ttm_flat_bike, here::here("elevation", "bike_flat.csv"))
