# options(java.parameters = '-Xmx2G')

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)
library(sf)
library(mapview)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE,
                     overwrite = FALSE,
                     temp_dir = FALSE,
                     elevation = "none")



# load points
poi <- read.csv(system.file("extdata/poa/poa_points_of_interest.csv", package = "r5r"))

# load fare structure
fare_structure_path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
fare_structure <- read_fare_structure(fare_structure_path)

calculate_and_plot_frontiers <- function() {
  frontiers_df <- pareto_frontier(r5r_core,
                                  origins = poi[10, ],
                                  destinations = poi[c(9, 12), ],
                                  departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                                  format = "%d-%m-%Y %H:%M:%S"),
                                  mode = c("WALK", "TRANSIT"),
                                  max_trip_duration = 180,
                                  fare_structure = fare_structure,
                                  monetary_cost_cutoffs = c(1, 4.5, 4.8, 7.20, 8.37, 11.4, 12.57),
                                  max_rides = 5,
                                  progress = TRUE
  )

  # recode modes
  frontiers_df[, monetary_cost := round(monetary_cost, 2)]
  frontiers_df[, modes := fcase(monetary_cost == 1,   'Walk (free)',
                                monetary_cost == 4.5, 'Train (4.50)',
                                monetary_cost == 4.8, 'Bus (4.80)',
                                monetary_cost == 7.2, 'Bus + Bus (7.20)',
                                monetary_cost == 8.37, 'Bus + Train (8.37)')]

  p <- ggplot(data=frontiers_df, aes(x=monetary_cost, y=travel_time, color=to_id,
                                label = modes)) +
    geom_step(linetype = "dashed") +
    geom_point() +
    geom_text(color='gray30', hjust = -.2, nudge_x = 0.05, angle = 45) +
    labs(title='Pareto frontier of alternative routes from Farrapos station to:',
         subtitle = 'Praia de Belas shopping mall and Moinhos hospital',
         color='Destination') +
    scale_x_continuous(name="Travel cost ($)", breaks=c(0, 2, 4, 4.8, 6, 7.2, 8.37, 10)) +
    scale_y_continuous(name="Travel time (minutes)", breaks=seq(0,160,20)) +
    coord_cartesian(xlim = c(0,10), ylim = c(0, 160)) +
    theme_classic() + theme(legend.position=c(.8, 0.9))

  return(p)
}

# fare_structure$transfer_time_allowance <- 60
# fare_structure$fare_cap <- 8
# fare_structure$debug_settings$output_file <- here::here("debug.csv")
# calculate_and_plot_frontiers()

# r5r_core$startServer("")


# debug_df <- read.csv(here::here("debug.csv"))
# r5r_core$getFareStructure() %>% clipr::write_clip()

orig <- poi %>% sample_n(size = nrow(poi))
dest <- poi %>% sample_n(size = nrow(poi))

system.time(
  frontiers_df <- pareto_itineraries(r5r_core,
                                     origins = poi[10, ],
                                     destinations = poi[12, ],
                                     # origins = poi[c(10, 10), ],
                                     # destinations = poi[c(9, 12), ],
                                     origins = orig,
                                     destinations = dest,
                                     departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                                     format = "%d-%m-%Y %H:%M:%S"),
                                     time_window = 30,
                                     mode = c("WALK", "TRANSIT"),
                                     max_trip_duration = 90,
                                     max_walk_dist = 1000,
                                     fare_structure = fare_structure,
                                     max_fare = 10.0,
                                     max_rides = 5,
                                     progress = TRUE)
)

frontiers_df$geometry <- st_as_sfc(frontiers_df$geometry)
frontiers_df <- st_as_sf(frontiers_df, crs = 4326)


# df <- frontiers_df
# trip = 2
view_results <- function(df, trip = 1) {
  df_filtered <- filter(df, trip_id == trip)

  df_filtered %>%
    select(from_id, to_id, departure_time, duration, total_fare,
           leg_id, leg_type, route_id, origin_stop_name, destination_stop_name, cumulative_fare,
           allowance_value, allowance_number, allowance_time) %>%
    st_set_geometry(NULL) %>%
    View()

  mv1 <- mapview(df_filtered, zcol = "route_id")

  df_stops <- st_set_geometry(df_filtered, NULL)

  df_stops1 <- df_stops %>% select(lon = origin_lon, lat = origin_lat, stop = origin_stop_name)
  df_stops2 <- df_stops %>% select(lon = destination_lon, lat = destination_lat, stop = destination_stop_name)
  df_stops3 <- rbind(df_stops1, df_stops2) %>% distinct()

  mv2 <- mapview(df_stops3, xcol = "lon", ycol = "lat", zcol = "stop", crs = 4326)

  mv1 + mv2
}
view_results(frontiers_df, 1)
view_results(frontiers_df, 2)



# Pareto Frontiers Plot ---------------------------------------------------


pareto_frontiers_df <- frontiers_df %>%
  st_set_geometry(NULL) %>%
  select(from_id, to_id, trip_id, duration, total_fare) %>%
  distinct()

pareto_frontiers_df <- pareto_frontiers_df %>%
  group_by(from_id, to_id) %>%
  arrange(total_fare, duration) %>%
  mutate(is_better = duration < lag(duration, default = Inf)) %>%
  filter(is_better == T)


pareto_frontiers_df %>%
  ggplot(aes(x=total_fare, y=duration)) +
  geom_vline(xintercept = c(0, 4.5, 4.8, 7.2, 8.37, 9.3 ), color = "grey80") +
  geom_step() +
  geom_point() +
  scale_x_continuous(limits = c(0, 10)) +
  scale_y_continuous(limits = c(0, 90)) +
  facet_wrap(~from_id+to_id)


# comparing TA and no TA --------------------------------------------------

frontiers_no_ta <- frontiers_no_ta %>% st_set_geometry(NULL)
frontiers_with_ta <- frontiers_with_ta %>% st_set_geometry(NULL)

full_frontiers <-
  full_join(frontiers_with_ta %>% mutate(departure_time = str_sub(departure_time, 1, 5)),
            frontiers_no_ta %>% mutate(departure_time = str_sub(departure_time, 1, 5)),
          by = c("from_id", "to_id", "departure_time", "origin_stop_id", "destination_stop_id",
                 "agency_id", "route_id", "route_short_name"))

full_frontiers %>%
  filter(is.na(trip_id.x)) %>%
  slice(200) %>%
  glimpse()



# full frontiers ----------------------------------------------------------

points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))

r5r_core$setTravelAllowance(TRUE)
full_frontiers_with_ta_df <- pareto_frontier(r5r_core,
                                origins = points,
                                destinations = points,
                                departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                                format = "%d-%m-%Y %H:%M:%S"),
                                mode = c("WALK", "TRANSIT"),
                                max_trip_duration = 180,
                                fare_structure = fare_structure,
                                monetary_cost_cutoffs = c(1, 4.5, 4.8, 7.20, 8.37, 11.4, 12.57),
                                max_rides = 5,
                                progress = TRUE
)

r5r_core$setTravelAllowance(FALSE)
full_frontiers_no_ta_df <- pareto_frontier(r5r_core,
                                             origins = points,
                                             destinations = points,
                                             departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                                             format = "%d-%m-%Y %H:%M:%S"),
                                             mode = c("WALK", "TRANSIT"),
                                             max_trip_duration = 180,
                                             fare_structure = fare_structure,
                                             monetary_cost_cutoffs = c(1, 4.5, 4.8, 7.20, 8.37, 11.4, 12.57),
                                             max_rides = 5,
                                             progress = TRUE)

## combine frontiers
points_wta <- full_frontiers_with_ta_df %>%
  select(from_id, to_id, monetary_cost) %>%
  distinct()

points_nta <- full_frontiers_no_ta_df %>%
  select(from_id, to_id, monetary_cost) %>%
  distinct()

full_points <- rbind(points_wta, points_nta) %>%
  distinct()

full_points %>%
  left_join(full_frontiers_with_ta_df, suffix = c("", ".wta"))


full_frontiers_df <-
  full_join(full_frontiers_with_ta_df, full_frontiers_no_ta_df,
          by = c("from_id", "to_id", "monetary_cost", "percentile"),
          suffix = c(".wta", ".nta")) %>%
  select(from_id, to_id, monetary_cost, travel_time.wta, travel_time.nta)

diff_frontiers_df <- filter(full_frontiers_df,
                            travel_time.wta != travel_time.nta |
                              is.na(travel_time.wta) | is.na(travel_time.nta))

write_csv(diff_frontiers_df, here::here("diff_frontiers.csv"))

