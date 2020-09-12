options(java.parameters = "-Xmx12G")

devtools::load_all(".")
library("tidyverse")
library("tictoc")

# Start R5R core
# r5r_core <- setup_r5(system.file("extdata", package = "r5r"), verbose = FALSE)
tic()
r5r_core <- setup_r5("/Users/marcussaraiva/Repos/data_r5r/bage/", verbose = FALSE)
toc()

street_net <- street_network_to_sf(r5r_core)
street_net$vertices %>% ggplot() + geom_sf()
street_net$edges %>% ggplot() + geom_sf(aes(colour=walk))


points_hex <- read.csv("/Users/marcussaraiva/Repos/data_r5r/bage/hexgrid.csv")


# Configuring trip
origin <- tibble(id="dezoito", lon=-54.112740, lat=-31.337579)
destination <- tibble(id="unipampa", lon=-54.067700, lat=-31.302716)

trip_date_time <- lubridate::as_datetime("2017-05-22 08:10:00")

max_walk_distance = 80000L
max_trip_duration = 120L

r5r_core$setMaxTransfers(5L)
r5r_core$setTimeWindowSize(30L)

paths_df <- detailed_itineraries(r5r_core = r5r_core,
                                 origins = origin, destinations = destination,
                                 departure_datetime = trip_date_time,
                                 max_walk_dist = max_walk_distance,
                                 max_trip_duration = max_trip_duration,
                                 mode = c("WALK", "BUS"),
                                 shortest_path = FALSE, verbose = TRUE, drop_geometry = FALSE)

paths_df %>%
  ggplot() +
  geom_sf(aes(colour = mode)) +
  facet_wrap(~option)


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




