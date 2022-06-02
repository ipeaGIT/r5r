devtools::load_all(".")

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path)

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

r5r_core$setDetailedItinerariesV2(TRUE)
r5r_core$setDetailedItinerariesV2(FALSE)

system.time(
  det2 <- detailed_itineraries(r5r_core,
                              origins = points[10,],
                              destinations = points[12,],
                              mode = c("WALK", "TRANSIT"),
                              departure_datetime = departure_datetime,
                              max_walk_dist = 1000,
                              max_trip_duration = 120,
                              # suboptimal_minutes = 10,
                              fare_structure = fare_structure,
                              max_fare = 10,
                              time_window = 1,
                              all_to_all = T,
                              progress = T,
                              shortest_path = T)
  )

mapview::mapview(det2, zcol = "mode")
mapview::mapview(dplyr::filter(det2, option == 36), zcol = "mode")
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

det2 %>%
  st_set_geometry(NULL) %>%
  group_by(option) %>%
  summarise(mode = paste(mode, collapse = "|"),
            routes = paste(route, collapse = "|"),
            total_fare = mean(total_fare))


