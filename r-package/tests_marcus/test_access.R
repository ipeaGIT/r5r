# library(r5r)
devtools::load_all(".")
library(magrittr)
library(ggplot2)
library(data.table)
library(h3jsr)
library(sf)
library(tidyverse)
library(patchwork)

path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path)

### test decays
decay_step <- r5r_core$testDecay("STEP", 30)
decay_exp <- r5r_core$testDecay("EXPONENTIAL", 30)
decay_fixed_exp <- r5r_core$testDecay("FIXED_EXPONENTIAL", 0.001)
decay_logistic <- r5r_core$testDecay("LOGISTIC", 10)
decay_linear <- r5r_core$testDecay("LINEAR", 10)

decays <- data_frame(secs = 1:3600,
                     decay_step,
                     decay_exp,
                     decay_fixed_exp,
                     decay_logistic,
                     decay_linear)
decays %>%
  pivot_longer(cols = starts_with("decay"), names_to = "fun", values_to = "decay") %>%
  ggplot(aes(x=secs/60, y=decay, color=fun)) +
  geom_point() +
  geom_vline(xintercept = 30) +
  facet_wrap(~fun) +
  theme(legend.position = "none")



##### input
origins <- destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r")) %>% setDT()

destinations[, opportunities := schools]
destinations <- destinations[opportunities > 0]

trip_date = "2019-05-20"
departure_time = "14:00:00"
mode = c('WALK', 'TRANSIT')

##### cumulative opportunities, by travel time percentile and cutoff

system.time(
  df_acc <- r5r::accessibility( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                            time_window = 30,
                            percentiles = c(25, 50, 75),
                            cutoffs = c(15, 30, 45),
                            decay_function = "STEP",
                            mode = mode,
                            max_walk_dist = 1000,
                            max_trip_duration = 45,
                            verbose = FALSE
  )
)


df_acc$geometry <- h3jsr::h3_to_polygon(df_acc$from_id)
df_acc$percentile <- paste0(df_acc$percentile, "th")
df_acc$cutoff <- paste0(df_acc$cutoff, " min")

ggplot(df_acc %>% filter(accessibility > 0)) +
  geom_sf(aes(geometry=geometry, fill=accessibility), color = NA) +
  coord_sf(datum = NA) +
  scale_fill_distiller(palette = "Spectral") +
  facet_grid(cutoff~percentile) +
  theme_minimal() +
  labs(title = "Accessibility to schools, estimated by R5",
       subtitle = "cumulative oportunities, by travel time percentile (cutoff = 30 min)")

##### different decay functions
calc_access <- function(decay_f = "STEP", decay_v = 10) {

  if (decay_f == "fixed_exponential") {decay_v = 0.001}
  if (decay_f == "linear") {decay_v = 10}
  if (decay_f == "logistic") {decay_v = 20}

  df <- r5r::accessibility( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                            time_window = 30,
                            percentiles = c(50),
                            cutoffs = c(30),
                            decay_function = decay_f,
                            decay_value = decay_v,
                            mode = mode,
                            max_walk_dist = 1000,
                            max_trip_duration = 45,
                            verbose = FALSE
  )

  df$fun <- decay_f
  return(df)
}

acc_step <- r5r::accessibility( r5r_core = r5r_core,
                                origins = origins,
                                destinations = destinations,
                                departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                                time_window = 30,
                                percentiles = c(50),
                                cutoffs = c(15, 30, 45),
                                decay_function = "STEP",
                                decay_value = 30,
                                mode = mode,
                                max_walk_dist = 1000,
                                max_trip_duration = 45,
                                verbose = FALSE) %>%
  mutate(fun = "step")

acc_exp <- r5r::accessibility( r5r_core = r5r_core,
                                  origins = origins,
                                  destinations = destinations,
                                  departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                                  time_window = 30,
                                  percentiles = c(50),
                                  cutoffs = c(15, 30, 45),
                                  decay_function = "EXPONENTIAL",
                                  decay_value = 30,
                                  mode = mode,
                                  max_walk_dist = 1000,
                                  max_trip_duration = 45,
                                  verbose = FALSE) %>%
  mutate(fun = "exp")

acc_fixed_exp <- map_df(c(0.0002, 0.0005, 0.0008),
                        function(x) {
                          r5r::accessibility( r5r_core = r5r_core,
                                              origins = origins,
                                              destinations = destinations,
                                              departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                                              time_window = 30,
                                              percentiles = c(50),
                                              cutoffs = c(30),
                                              decay_function = "FIXED_EXPONENTIAL",
                                              decay_value = x,
                                              mode = mode,
                                              max_walk_dist = 1000,
                                              max_trip_duration = 45,
                                              verbose = FALSE) %>%
                            mutate(cutoff = x)
                          }) %>%
  mutate(fun = "fixed_exp")

acc_linear <- map_df(c(5, 15, 30),
                        function(x) {
                          r5r::accessibility( r5r_core = r5r_core,
                                              origins = origins,
                                              destinations = destinations,
                                              departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                                              time_window = 30,
                                              percentiles = c(50),
                                              cutoffs = c(30),
                                              decay_function = "LINEAR",
                                              decay_value = x,
                                              mode = mode,
                                              max_walk_dist = 1000,
                                              max_trip_duration = 45,
                                              verbose = FALSE) %>%
                            mutate(cutoff = x)
                        }) %>%
  mutate(fun = "linear")

acc_logistic <- map_df(c(15, 30, 45),
                        function(x) {
                          r5r::accessibility( r5r_core = r5r_core,
                                              origins = origins,
                                              destinations = destinations,
                                              departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                                              time_window = 30,
                                              percentiles = c(50),
                                              cutoffs = c(30),
                                              decay_function = "LOGISTIC",
                                              decay_value = x,
                                              mode = mode,
                                              max_walk_dist = 1000,
                                              max_trip_duration = 45,
                                              verbose = FALSE) %>%
                            mutate(cutoff = x)
                        }) %>%
  mutate(fun = "logistic")

acc_fun_df <- rbind(acc_step, acc_exp, acc_fixed_exp, acc_logistic, acc_linear)
acc_fun_df$geometry <- h3jsr::h3_to_polygon(acc_fun_df$from_id)

ggplot(acc_fun_df) +
  geom_sf(aes(geometry=geometry, fill=accessibility), color = NA) +
  coord_sf(datum = NA) +
  scale_fill_distiller(palette = "Spectral") +
  facet_wrap(~fun+cutoff, dir = "v", nrow=3) +
  theme_minimal() +
  labs(title = "Accessibility to schools, estimated by R5",
       subtitle = "considering different decay functions")


decay_functions <- c("step", "exponential", "fixed_exponential",
                     "linear", "logistic")
df_access <- purrr::map_df(decay_functions, calc_access)
df_access$geometry <- h3jsr::h3_to_polygon(df_access$from_id)

ggplot(df_access) +
  geom_sf(aes(geometry=geometry, fill=accessibility), color = NA) +
  coord_sf(datum = NA) +
  scale_fill_distiller(palette = "Spectral") +
  facet_wrap(~fun) +
  theme_minimal() +
  labs(title = "Accessibility to schools, estimated by R5",
       subtitle = "considering different decay functions",
       caption = "cutoff = 30min, exponential decay = 0.001, linear width = 10, logistic st.dev = 20")


######### ELEVATION
tobler_hiking <- function(slope) {
  C <- 1.19403

  tobler_factor <- C * exp(-3.5 * abs(slope+0.05))

  return(1 / tobler_factor)
}

t_factor = tobler_hiking(9L:-13L)
plot(t_factor)

slopes <- as.double(9.0:-13.0)
alts <- as.double(rep(0.0, 23))
b_factor <- r5r_core$bikeSpeedCoefficientOTP(slopes, alts)
plot(b_factor)
