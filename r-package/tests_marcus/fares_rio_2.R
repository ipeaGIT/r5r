# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
library(tidyverse)
library(sf)
library(h3jsr)
library(data.table)
library(viridis)
library(patchwork)
library(googlesheets4)

# build transport network
data_path <- "~/Repos/r5r_fares/rio"
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

# load origin/destination points

poi <- tribble(
  ~id, ~lat, ~lon,
  "centro", -22.9064720147941, -43.177139635807734,
  "catete", -22.930673881789726, -43.17764097392119,
  "copacabana", -22.96915219120712, -43.18463648168664,
  "pavuna", -22.814726, -43.362337,
  "jardim_oceanico", -23.009335, -43.312220,
  "santa_cruz", -22.914807, -43.688556,
  "madureira", -22.875438, -43.339674
)

points <- read_csv("~/Repos/r5r_fares/rio/points_rio_09_2019.csv") %>%
  rename(id = id_hex, lon=X, lat=Y) %>%
  mutate(unit = 1)
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

points_r8 <- h3jsr::get_parent(points$id, res = 8, simple = TRUE)
points_r8 <- unique(points_r8)
points_r8 <- h3jsr::h3_to_point(points_r8, simple = FALSE)
points_r8$id <- points_r8$h3_address
points_r8$unit <- 1
# area_sf <- h3jsr::h3_to_polygon(points$id, simple = FALSE) %>%
#   summarise()

# Pareto ------------------------------------------------------------------

fare_settings <- read_fare_calculator(file_path = here::here("tests_marcus", "rio_fares_v3.zip"))
pareto_cutoffs <- c(0, 3.80,  4.05,  4.70,  5.00,  6.05,  6.50,  7.10,  7.60,  8.10,  8.55,  9.40,  10.00)

fare_settings <- setup_fare_calculator(r5r_core, base_fare = 0, by = "GENERIC")
fare_settings$fares_per_mode$allow_same_route_transfer <- TRUE
fare_settings$fares_per_mode$unlimited_transfers <- TRUE

fare_settings$debug_settings$output_file <- here::here("tests_marcus", "rio_fare_calculator_output.csv")

points_sample <- sample_n(points_r8, 50)

system.time(
  pareto_df <- pareto_frontier(r5r_core,
                               origins = poi,
                               destinations = poi,
                               mode = c("WALK", "TRANSIT"),
                               departure_datetime = departure_datetime,
                               monetary_cost_cutoffs = pareto_cutoffs,
                               fare_calculator_settings = fare_settings,
                               max_trip_duration = 180,
                               max_walk_dist = 8000,
                               time_window = 1, #30,
                               percentiles = 50, # c(5, 50, 95),
                               max_rides = 3,
                               draws_per_minute = 1L,
                               verbose = FALSE,
                               progress = TRUE)
)

rio_debug_1 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_debug_anterior.csv"))
rio_debug_2 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output.csv"))

rio_debug_df <-full_join(rio_debug_1, rio_debug_2, by="pattern") %>%
  mutate(fare.x = fare.x / 100)
View(rio_debug_df)

pareto_cutoffs <- c(rio_debug_df$fare.x, unique(rio_debug_df$fare.y))
pareto_cutoffs <- unique(pareto_cutoffs)
pareto_cutoffs <- pareto_cutoffs[!is.na(pareto_cutoffs)]
pareto_cutoffs <- sort(pareto_cutoffs)


pareto_df %>%
  # filter(from_id == "catete") %>%
  mutate(percentile = factor(percentile),
         pair = paste(from_id, to_id)) %>%
  pivot_longer(cols=starts_with("monetary"), names_to = "mon", values_to="cost") %>%
  ggplot(aes(x=cost, y=travel_time, color=pair)) +
  geom_step() +
  geom_point() +
  # geom_text(aes(label = paste0("(", monetary_cost, ",", travel_time, ")"))) +
  # geom_path() +
  # scale_color_brewer(palette = "Set1") +
  scale_x_continuous(breaks = 0:10, limits = c(0, 10)) +
  scale_y_continuous(breaks = seq(0, 180, 30), limits = c(0, 180)) +
  theme(legend.position = "none") +
  facet_wrap(~pair)

write_csv(rio_debug_df, "rio_debug_novo.csv")


##########
density_test <- function(t) {
  ttm_1 <- travel_time_matrix(r5r_core,
                              origins = points_r8,
                              destinations = points_r8,
                              mode = c("WALK", "TRANSIT"),
                              departure_datetime = departure_datetime,
                              fare_calculator_settings = NULL,
                              max_trip_duration = 180,
                              max_walk_dist = t,
                              time_window = 1, #30,
                              percentiles = 50, # c(5, 50, 95),
                              max_rides = 3,
                              draws_per_minute = 1L,
                              verbose = FALSE,
                              progress = TRUE)

  ttm_2 <- travel_time_matrix(r5r_core,
                              origins = points_r8,
                              destinations = points_r8,
                              mode = c("WALK", "TRANSIT"),
                              departure_datetime = departure_datetime,
                              max_fare = 50,
                              fare_calculator_settings = fare_settings,
                              max_trip_duration = 180,
                              max_walk_dist = t,
                              time_window = 1, #30,
                              percentiles = 50, # c(5, 50, 95),
                              max_rides = 3,
                              draws_per_minute = 1L,
                              verbose = FALSE,
                              progress = TRUE)


  ttm_c <-
    rbind(mutate(ttm_1, method = "null"),
          mutate(ttm_2, method = "normal")
    )


  unit_access <- ttm_c %>%
    filter(travel_time <= 120) %>%
    count(from_id, method)
  # pivot_wider(names_from = method, values_from = n)

  p <- unit_access %>%
    ggplot(aes(x=n, fill = method)) +
    geom_density(alpha = 0.5) +
    labs(title = paste0("max_walk_dist = ", t))

  return(p)

}

plots <- map(c(500, 1000, 1500, 2000, 3000, 5000),
    density_test)

library(patchwork)

wrap_plots(plots, ncol = 2) +
  patchwork::plot_annotation(title = "After Fix",
                             subtitle = "Density plots of unitary accessibility")

density_test(500)
density_test(1000)
density_test(1500)
density_test(2000)
density_test(3000)
density_test(5000)


unit_access

unit_access_b %>%
  ggplot(aes(x=n, fill = method)) +
  geom_density(alpha = 0.5) +
  labs(title = "max_walk_dist = 2500")
facet_wrap(~method)


ttm_b <- full_join(ttm_1, ttm_2, by=c("from_id", "to_id")) %>%
  full_join(ttm_3, by=c("from_id", "to_id")) %>%
  mutate(diff_1 = travel_time.x - travel_time.y,
         diff_2 = travel_time.x - travel_time)

ttm_b %>%
  filter(is.na(travel_time.y)) %>% View()

pt <- ttm_b %>%
  filter(is.na(travel_time.y)) %>%
  count(from_id) %>%
  filter(n > 50)

View(ttm_b)

ttm_b %>%
  pivot_longer(cols = starts_with("travel_time"))

points_r8 %>%
  # filter(h3_address == "88a8a062b3fffff") %>%
  filter(h3_address %in% pt$from_id) %>%
  mapview::mapview(crs = 4326)


