# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
# library(ggplot2)
# library(data.table)
library(tidyverse)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

poi <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
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
                            cutoffs = c(30, 60),
                            max_trip_duration = 60,
                            time_window = 1,
                            percentiles = c(5, 50, 95),
                            verbose = FALSE)

    access$max_fare <- f

    return(access)
  })

  return(access_df)
}

access_df <- calculate_access(c(480, 720)) %>%
  # access_df <- calculate_access(c(240, 480, 720, 960, -1)) %>%
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
                        decay_function = "logistic",
                        decay_value = 15,
                        mode = c("WALK", "TRANSIT"),
                        cutoffs = c(60),
                        max_trip_duration = 60,
                        verbose = FALSE)
)

access %>% left_join(points, by = c("id" = "id")) %>%
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


# Detailed Itineraries ----------------------------------------------------

r5r_core$setMaxFare(240L, "porto-alegre")
r5r_core$setMaxFare(480L, "porto-alegre")
r5r_core$setMaxFare(720L, "porto-alegre")

origins <- poi
destinations <- poi

mode = c("WALK", "BUS")
max_walk_dist <- 10000


system.time(
  df <- detailed_itineraries(r5r_core,
                             origins = origins[2,],
                             destinations = destinations[3,],
                             departure_datetime = departure_datetime,
                             max_walk_dist = max_walk_dist,
                             mode = mode,
                             shortest_path = F,
                             n_threads= Inf,
                             verbose = F,
                             progress=T)
)



# Pareto ------------------------------------------------------------------

pareto_df <- pareto_frontier(r5r_core,
                             origins = poi[1:2,],
                             destinations = poi[3:4,],
                             mode = c("WALK", "TRANSIT"),
                             departure_datetime = departure_datetime,
                             monetary_cost_cutoffs = seq(0, 1000, 100),
                             fare_calculator = "porto-alegre",
                             max_trip_duration = 60,
                             max_walk_dist = 8000,
                             time_window = 30,
                             percentiles = c(5, 50, 95),
                             max_rides = 5,
                             verbose = FALSE,
                             progress = TRUE)

pareto_df$monetary_cost <- pareto_df$monetary_cost / 100
pareto_df$monetary_cost_upper <- pareto_df$monetary_cost_upper / 100
View(pareto_df)

pareto_df %>%
  mutate(percentile = factor(percentile)) %>%
  pivot_longer(cols=starts_with("monetary"), names_to = "mon", values_to="cost") %>%
  ggplot(aes(x=cost, y=travel_time, color=percentile, group=percentile)) +
  geom_step() +
  # geom_path() +
  scale_color_brewer(palette = "Set1") +
  scale_x_continuous(breaks = 1:10) +
  facet_grid(from_id~to_id)

r5r_core$setMaxFare(10L, "rio-de-janeiro")
r5r_core$verboseMode()


## accessibility decay

library(r5r)
library(dplyr)
library(tidyr)
library(ggplot2)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)


decay_step <- r5r_core$testDecay("STEP", 0.0)
decay_exp <- r5r_core$testDecay("EXPONENTIAL", 0.0)
decay_fixed_exp <- r5r_core$testDecay("FIXED_EXPONENTIAL", 0)
decay_linear <- r5r_core$testDecay("LINEAR", 10.0)
decay_logistic <- r5r_core$testDecay("LOGISTIC", 10.0)

decays_df <- data.frame(seconds = 1:3600,
                        step = decay_step,
                        exponential = decay_exp,
                        fixed_exponential = decay_fixed_exp,
                        linear = decay_linear,
                        logistic = decay_logistic)

decays_df <- pivot_longer(decays_df, cols = 2:6, names_to = "decay_function", values_to = "decay")

ggplot(decays_df, aes(x=seconds, y=decay, color=decay_function)) +
  geom_point() +
  geom_vline(xintercept = 1800) +
  facet_wrap(~decay_function) +
  theme(legend.position = "none")



# LTS ---------------------------------------------------------------------

street_net <- street_network_to_sf(r5r_core)
View(street_net$vertices)
View(street_net$edges)

mapview::mapview(street_net$edges, zcol = "bicycle_lts")
