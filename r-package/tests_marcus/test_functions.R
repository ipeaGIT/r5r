# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
library(ggplot2)
library(data.table)
library(tidyverse)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# poi <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
dest <- points

calculate_access <- function(fares) {

  access_df <- map_df(fares, function(f) {
    f <- as.integer(f)

    r5r_core$setMaxFare(f, "porto-alegre")

    access <- accessibility(r5r_core,
                            origins = points,
                            destinations = dest,
                            departure_datetime = departure_datetime,
                            opportunities_colname = "schools",
                            mode = c("WALK", "TRANSIT"),
                            cutoffs = c(60),
                            max_trip_duration = 60,
                            max_rides = 5,
                            verbose = FALSE)

    access$max_fare <- f

    return(access)
  })

  return(access_df)
}

access_df <- calculate_access(c(240, 480, 720, 960, -1)) %>%
  left_join(points, by = c("from_id" = "id"))

access_df %>%
  ggplot(aes(x=lon, y=lat, color= accessibility)) +
  geom_point() +
  coord_map() +
  scale_color_distiller(palette = "Spectral") +
  facet_wrap(~max_fare)

access_df %>%
  pivot_wider(names_from = max_fare, values_from = accessibility, names_prefix = "fare_") %>%
  View()


r5r_core$setMaxFare(-1L, "porto-alegre")
r5r_core$setMaxFare(200L, "porto-alegre")
r5r_core$setMaxFare(480L, "porto-alegre")
r5r_core$setMaxFare(1000L, "porto-alegre")

system.time(
  access <- accessibility(r5r_core,
                        origins = points,
                        destinations = dest,
                        departure_datetime = departure_datetime,
                        opportunities_colname = "schools",
                        mode = c("WALK", "TRANSIT"),
                        cutoffs = c(60),
                        max_trip_duration = 60,
                        verbose = FALSE)
)

access %>% left_join(points, by = c("from_id" = "id")) %>%
  ggplot(aes(x=lon, y=lat, color= accessibility)) +
  geom_point() +
  coord_map() +
  scale_color_distiller(palette = "Spectral") +
  facet_wrap(~cutoff)


system.time(
  ttm <- travel_time_matrix(r5r_core, origins = points,
                            destinations = dest,
                            mode = c("WALK", "TRANSIT"),
                            breakdown = FALSE,
                            departure_datetime = departure_datetime,
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 30,
                            percentiles = c(25, 50, 75),
                            verbose = FALSE,
                            progress = TRUE)
)

calculate_ttm <- function(fare) {
  r5r_core$setMaxFare(fare, "porto-alegre")

  ttm <- travel_time_matrix(r5r_core, origins = points,
                            destinations = dest,
                            mode = c("WALK", "TRANSIT"),
                            breakdown = FALSE,
                            departure_datetime = departure_datetime,
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 1,
                            percentiles = c(50),
                            verbose = FALSE,
                            progress = TRUE)
  ttm$max_fare <- fare

  return(ttm)
}

ttm_max = calculate_ttm(-1L)
ttm_200 = calculate_ttm(200L)
ttm_480 = calculate_ttm(480L)
ttm_1000 = calculate_ttm(1000L)

ttm <- rbind(ttm_max, ttm_200, ttm_480, ttm_1000)

access_df <- ttm %>%
  group_by(fromId, max_fare) %>%
  summarise(access = n(), .groups = "drop") %>%
  left_join(points, by = c("fromId" = "id"))

access_df %>%
  ggplot(aes(x=lon, y=lat, color= access)) +
  geom_point() +
  coord_map() +
  scale_color_distiller(palette = "Spectral") +
  facet_wrap(~max_fare)
