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

# points_r8 <- h3jsr::get_parent(points$id, res = 8, simple = TRUE)
# points_r8 <- unique(points_r8)
# points_r8 <- h3jsr::h3_to_point(points_r8, simple = FALSE)
# points_r8$id <- points_r8$h3_address
# points_r8$unit <- 1
# area_sf <- h3jsr::h3_to_polygon(points$id, simple = FALSE) %>%
#   summarise()

# Pareto ------------------------------------------------------------------

fare_settings <- read_fare_calculator(file_path = here::here("tests_marcus", "rio_fares_v3.zip"))

pareto_cutoffs <- c(0, 3.80,  4.05,  4.70,  5.00,  6.05,  6.50,  7.10,  7.60,  8.10,  8.55,  9.40,  10.00)

fare_settings$debug_settings$output_file <- here::here("tests_marcus", "rio_fare_calculator_output.csv")

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
rio_debug_v7 <- read_csv(here::here("tests_marcus", "rio_fare_calculator_output.csv"))


pareto_df %>%
  mutate(percentile = factor(percentile),
         pair = paste(from_id, to_id)) %>%
  pivot_longer(cols=starts_with("monetary"), names_to = "mon", values_to="cost") %>%
  ggplot(aes(x=cost, y=travel_time, color=pair)) +
  geom_step() +
  geom_point() +
  # geom_path() +
  # scale_color_brewer(palette = "Set1") +
  # scale_x_continuous(breaks = 0:10, limits = c(0, 10)) +
  # scale_y_continuous(breaks = seq(0, 180, 30), limits = c(0, 180)) +
  theme(legend.position = "none") +
  facet_wrap(~pair)

