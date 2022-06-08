devtools::load_all(".")

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, elevation = "TOBLER", overwrite = T)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
# points <- read.csv(file.path(data_path, "poa_hexgrid.csv")) %>%
  # dplyr::sample_n(50)

# load fare structure object
fare_structure_path <- system.file(
  "extdata/poa/fares/fares_poa.zip",
  package = "r5r"
)
fare_structure <- read_fare_structure(fare_structure_path)

# inputs
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# r5r_core$setDetailedItinerariesV2(TRUE)
# r5r_core$setDetailedItinerariesV2(FALSE)

# a <- capture.output(
system.time(
  det_new <- detailed_itineraries(r5r_core,
                              origins = points[1,],
                              destinations = points[3,],
                              mode = c("BICYCLE", "TRANSIT"),
                              departure_datetime = departure_datetime,
                              # max_walk_dist = 1750,
                              max_bike_dist = 3500,
                              max_trip_duration = 90,
                              suboptimal_minutes = 5,
                              # fare_structure = fare_structure,
                              # max_fare = 9,
                              time_window = 1,
                              all_to_all = T,
                              progress = T,
                              shortest_path = F,
                              verbose = F,
                              drop_geometry = F)
  )
# )

det_new$dist <- sf::st_length(det_new)


mapview::mapview(det_new, zcol = "option") +
  mapview::mapview(points, xcol="lon", ycol="lat", crs=4326)

mapview::mapview(dplyr::filter(det_new, option == 2), zcol = "route")
mapview::mapview(dplyr::filter(det2,
                               from_id == "beira_rio_stadium",
                               to_id == "bus_central_station",
                               option == 2), zcol = "mode")

r5r::select_mode(c("WALK", "BICYCLE"), "WALK", style = "dit")
set_fare_structure(r5r_core, fare_structure)
r5r_core$setMaxFare(rJava::.jfloat(10.0))

r5r_core$dropFareCalculator()

library("tidyverse")

saveRDS(det, "det_v2.rds")
saveRDS(det2, "det_v1.rds")

library(sf)
library(tidyverse)

det_new %>%
  st_set_geometry(NULL) %>%
  group_by(option) %>%
  summarise(mode = paste(mode, collapse = "|"),
            routes = paste(route, collapse = "|"))

det_new %>%
  st_set_geometry(NULL) %>%
  group_by(option) %>%
  summarise(mode = paste(mode, collapse = "|"),
            routes = paste(route, collapse = "|"),
            total_fare = mean(total_fare))

a <- det_new %>%
  st_set_geometry(NULL) %>%
  group_by(option) %>%
  mutate(sum_dur = sum(segment_duration + wait),
         is_diff = sum_dur != total_duration)

suppressWarnings()

a <- r5r_core$message("bla")








# load libraries
library("r5r")
library("data.table")
library("tidyverse")

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path)

# inputs
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# size <- 15
compute_paths <- function(sm, tw) {
  # sample_data <- fread(here::here("data", "sample_15.csv"))

  t <- system.time(
    dit <- detailed_itineraries(r5r_core,
                                origins = sample_data[1,],
                                destinations = sample_data[12,],
                                mode = c("WALK", "TRANSIT"),
                                departure_datetime = departure_datetime,
                                suboptimal_minutes = sm,
                                time_window = tw,
                                max_walk_dist = 1000,
                                max_trip_duration = 120,
                                progress = T,
                                shortest_path = F)
  )

  l <- dit$option |> unique() |> length()

  rm(dit)
  rJava::.jgc()

  return(data.table(suboptimal_minutes = sm,
                    time_window = tw,
                    n_options = l,
                    time = t[3]))
}

# compute paths
# times_old <- lapply(c(15, 25), compute_paths) |> rbindlist()

df <- NULL
for (sm in 0:15) {
  for (tw in 1:15) {
    df1 <- compute_paths(sm, tw)

    if (is.null(df)) {
      df <- df1
    } else {
      df <- rbind(df, df1)
    }
  }
}

