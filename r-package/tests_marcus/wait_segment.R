library("ggplot2")
library("dplyr")

data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

set_max_street_time(max_walk_dist = Inf, walk_speed = 3.6, max_trip_duration = 60L)

results <- detailed_itineraries(
  r5r_obj,
  origins = points[1:15,],
  destinations = points[15:1,],
  mode = c("WALK", "TRANSIT"),
  departure_datetime = as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"),
  max_walk_dist = Inf,
  max_trip_duration = 60L,
  walk_speed = 3.6,
  bike_speed = 12,
  shortest_path = FALSE,
  n_threads = Inf,
  verbose = FALSE
)

results %>%
  mutate(totalDuration = totalDuration / 60) %>%
  # write.csv("trips_with_filter.csv")
  View()

results %>% dplyr::group_by(fromId, toId, option) %>%
  dplyr::summarise(totalDuration= max(totalDuration)/60, duration = sum(duration+wait)) %>% View()
# results[8:10,] %>% View()
results %>%
  dplyr::filter(fromId == "gasometer_museum") %>%
  ggplot() +
  geom_sf(aes(colour=mode)) +
  theme_void() +
  facet_wrap(~fromId+option)
