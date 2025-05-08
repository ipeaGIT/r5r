devtools::load_all('.')
library(dplyr)
library(sf)
library(mapview)
library(stringr)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)


det <- detailed_itineraries(
  r5r_core,
  origins = points,
  destinations = points[rev(seq_len(nrow(points))), ],
  mode = c('walk', 'transit'),
  departure_datetime = departure_datetime,
  max_trip_duration = 120,
  osm_link_ids = T,
)

# get all segment IDs
segment_ids <- det$edge_id_list |>
  stringr::str_extract_all("\\d+") |>
  unlist() |>
  unique()

OSM_ids <- det$osm_id_list |>
  stringr::str_extract_all("\\d+") |>
  unlist() |>
  unique()

# get OSM edges used in the trip
road_network <- r5r::street_network_to_sf(r5r_core)
edges_sf <- subset(road_network$edges, edge_index %in% segment_ids)
OSM_sf <- subset(road_network$edges, osm_id %in% OSM_ids)

det_walk <- det[det$mode == "WALK", ]
det_walk$id <- factor(1:nrow(det_walk))
# graph the routes using edge ids
mapview(det_walk, zcol = "id", lwd = 3, layer.name = "Route det")+
  mapview(edges_sf, color = "red", lwd = 3, layer.name = "Route edges_sf")

# graph the routes using OSM ids
  mapview(OSM_sf, color = "orange", lwd = 3, layer.name = "Route OSM_sf")+
    mapview(det_walk, zcol = "id", lwd = 3, layer.name = "Route det")

