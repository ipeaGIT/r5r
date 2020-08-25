options(java.parameters = "-Xmx12G")

library("r5r")
library("tidyverse")
library("tictoc")

# Start R5R core
r5r_core <- setup_r5("/Users/marcussaraiva/Repos/data_r5r/poa", verbose = FALSE)

# Load points of interest
points <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))

points_hex <- read.csv("/Users/marcussaraiva/Repos/data_r5r/poa/poa_hexgrid.csv")


# routes
street_net <- street_network_to_sf(r5r_core)

# Configuring trip
origin <- points[10,] # Farrapos train station
destination <- points[12,] # Praia de Belas shopping mall

trip_date_time <- lubridate::as_datetime("2019-05-20 14:00:00")

max_walk_distance = 1000
max_trip_duration = 120L

paths_df <- detailed_itineraries(r5r_core = r5r_core,
                                 origins = origin, destinations = destination,
                                 departure_datetime = trip_date_time,
                                 max_walk_dist = max_walk_distance,
                                 max_trip_duration = max_trip_duration,
                                 mode = c("WALK", "BUS"),
                                 shortest_path = FALSE, verbose = FALSE)

paths_df %>%
  ggplot() +
  geom_sf(aes(colour=mode)) +
  facet_wrap(~option)

sf::st_write(paths_df, "/Users/marcussaraiva/path_with_shape.shp")

tic()
ttm <- travel_time_matrix(r5r_core, points, points, mode = c("WALK", "BUS"), trip_date_time, max_walk_dist = 2000,
                          max_trip_duration = 120L, verbose = FALSE)
toc()

tic()
ttm <- travel_time_matrix(r5r_core, points_hex, points_hex, mode = c("WALK", "BUS"), trip_date_time, max_walk_dist = 2000,
                          max_trip_duration = 120L, verbose = FALSE)
toc()

hex_sample <- sample(points_hex$id, 4)

ttm %>%
  filter(fromId %in% hex_sample) %>%
  left_join(points_hex, by=c("toId"="id")) %>%
  ggplot() +
  geom_point(aes(x=lon, y=lat, colour=travel_time), size=0.5) +
  scale_color_distiller(palette = "Spectral") +
  facet_wrap(~fromId, ncol=2) +
  theme_minimal() +
  coord_map()

ttm
