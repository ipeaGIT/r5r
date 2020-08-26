options(java.parameters = "-Xmx12G")

library("r5r")
library("tidyverse")
library("tictoc")

# Start R5R core
r5r_core <- setup_r5(system.file("extdata", package = "r5r"), verbose = FALSE)
# r5r_core <- setup_r5("/Users/marcussaraiva/Repos/data_r5r/poa", verbose = FALSE)

# Load points of interest
points <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))

points_hex <- read.csv("/Users/marcussaraiva/Repos/data_r5r/poa/poa_hexgrid.csv")


# routes
street_net <- street_network_to_sf(r5r_core)

street_net$routes %>% View()

street_net$routes %>%
  ggplot() +
  geom_sf()

# Configuring trip
origin <- points[10,] # Farrapos train station
destination <- points[12,] # Praia de Belas shopping mall

trip_date_time <- lubridate::as_datetime("2019-03-20 14:00:00")
# trip_date_time <- lubridate::as_datetime("2019-05-20 14:00:00")

max_walk_distance = 1000
max_trip_duration = 120L

paths_df <- detailed_itineraries(r5r_core = r5r_core,
                                 origins = origin, destinations = destination,
                                 departure_datetime = trip_date_time,
                                 max_walk_dist = max_walk_distance,
                                 max_trip_duration = max_trip_duration,
                                 mode = c("WALK", "BUS"),
                                 shortest_path = FALSE, verbose = TRUE)

paths_df %>%
  # sf::st_write("/Users/marcussaraiva/path_with_shape.shp")
  # mapview::mapview()

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

## Route 702

poa_shapes <- read_csv("/Users/marcussaraiva/Repos/data_r5r/poa/gtfs_poa_eptc_2019-06/shapes.csv")
poa_702 <- poa_shapes %>% filter(shape_id == "702-1")

write_csv(poa_702, "/Users/marcussaraiva/p702.csv")

####

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path = data_path)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# inputs
origins <- points[]
destinations <- points[15:1,]
mode <- c("WALK", "TRANSIT")
max_walk_dist <- 1000
max_trip_duration <- 120L
departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

df <- detailed_itineraries(r5r_obj,
                           origins,
                           destinations,
                           mode,
                           departure_datetime,
                           max_walk_dist)

data.table::rbindlist(df) %>% View()
df
stop_r5(r5r_obj)
rJava::.jgc(R.gc = TRUE)

