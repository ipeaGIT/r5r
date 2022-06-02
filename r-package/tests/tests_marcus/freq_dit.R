devtools::load_all(".")

library(data.table)
# build transport network
data_path <- system.file("extdata/spo", package = "r5r")
r5r_core <- setup_r5(data_path, overwrite = F)

# load origin/destination points
points <- fread(file.path(data_path, "spo_hexgrid.csv")) |>
  dplyr::sample_n(15)
# points <- read.csv(file.path(data_path, "poa_hexgrid.csv")) %>%
  # dplyr::sample_n(50)


# inputs
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

r5r_core$setDetailedItinerariesV2(TRUE)
r5r_core$setDetailedItinerariesV2(FALSE)
#
# r5r::assign_mode(mode = c("WALK", "BUS", "SUBWAY", "RAIL"), mode_egress = "WALK", style = "dit")

system.time(
  det2 <- detailed_itineraries(r5r_core,
                               origins = points[id=="89a8100c527ffff"],
                               destinations = points[id=="89a8100c5a3ffff"],
                               mode = c("WALK", "BUS", "SUBWAY", "RAIL"),
                              departure_datetime = departure_datetime,
                              max_walk_dist = 1500,
                              max_trip_duration = 120,
                              suboptimal_minutes = 5,
                              # fare_structure = fare_structure,
                              # max_fare = 10,
                              time_window = 10,
                              all_to_all = T,
                              shortest_path = F,
                              progress = T)
  )


ttm <- expanded_travel_time_matrix(r5r_core,
                                   origins = points,
                                   destinations = points,
                                   mode = c("WALK", "TRANSIT"),
                                   departure_datetime = departure_datetime,
                                   max_walk_dist = 1000,
                                   max_trip_duration = 120,
                                   # fare_structure = fare_structure,
                                   # max_fare = 10,
                                   time_window = 1,
                                   progress = T)

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

library(mapview)

tn <- transit_network_to_sf(r5r_core)
mapview(points, xcol="lon",ycol="lat", crs=4326) + tn$routes


d <- r5r_core$getTransitServicesByDate("2019-05-13")
d <- r5r::java_to_dt(d)
