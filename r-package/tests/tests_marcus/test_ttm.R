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
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# points <- fread(file.path(data_path, "spo_hexgrid.csv"))
# poi <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
points <- fread(file.path(data_path, "poa_hexgrid.csv"))
# dest <- points

# dir.create(here::here("csv"))

# r5r_core$setCsvOutput(here::here("csv"))

  normal_ttm <- travel_time_matrix(r5r_core, origins = points, #[id == "89a9012a3cfffff",],
                                   destinations = points, #[id == "89a901284a3ffff",],
                            mode = c("WALK"),
                            departure_datetime = departure_datetime,
                            max_trip_duration = 60,
                            max_walk_dist = Inf,
                            time_window = 30,
                            percentiles = c(1, 25, 50, 75, 99),
                            verbose = FALSE,
                            progress = TRUE)

a
normal_ttm %>%
  select(from_id, to_id) %>%
  distinct() %>%
  nrow()

system.time(
  expanded_ttm <- expanded_travel_time_matrix(r5r_core,
                                              origins = points[id == "89a9012a3cfffff",],
                                   destinations = points[id == "89a901284a3ffff",],
                                   mode = c("WALK", "TRANSIT"),
                                   breakdown = F,
                                   departure_datetime = departure_datetime,
                                   max_trip_duration = 60,
                                   max_walk_dist = Inf,
                                   time_window = 60,
                                   draws_per_minute = 20,
                                   verbose = FALSE,
                                   progress = TRUE)
)

expanded_ttm %>%
  filter(from_id == "89a9012a3cfffff", to_id == "89a901284a3ffff") %>% # poa
  # filter(from_id == "89a8100c2b3ffff", to_id == "89a8100c38fffff") %>% # spo
  View()



expanded_ttm %>%
  select(from_id, to_id) %>%
  distinct() %>%
  nrow()









