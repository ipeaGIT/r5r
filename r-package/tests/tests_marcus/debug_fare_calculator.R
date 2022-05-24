# options(java.parameters = '-Xmx2G')

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)
library(sf)

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

# orig <- poi %>% sample_n(size = nrow(poi))
# dest <- poi %>% sample_n(size = nrow(poi))

system.time(
  frontiers_df <- pareto_itineraries(r5r_core,
                                     origins = poi[10, ],
                                     destinations = poi[12, ],
                                     # origins = poi[c(10, 10), ],
                                     # destinations = poi[c(9, 12), ],
                                     # origins = orig,
                                     # destinations = dest,
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

frontiers_df %>%
  filter(to_id == "praia_de_belas_shopping_center", trip_id %in% c(1, 7)) %>%
  View()

st_write(frontiers_df[frontiers_df$to_id == "praia_de_belas_shopping_center",],
         here::here("trips.gpkg"))

mapview::mapview(frontiers_df[frontiers_df$to_id == "praia_de_belas_shopping_center",],
                 zcol="trip_id")

library(ggspatial)

frontiers_df %>%
  filter(to_id == "praia_de_belas_shopping_center", trip_id <= 8) %>%
  # filter(to_id == "moinhos_de_vento_hospital") %>%
  # filter(trip_id == 1) %>%
  ggplot() +
  # coord_sf(datum = NA) +
  # annotation_map_tile(type = "cartolight") +
  geom_sf(aes(color=route_id)) +
  theme_minimal() +
  facet_wrap(~trip_id)
# frontiers_df$json[1] %>% jsonlite::prettify() %>% clipr::write_clip()
# trips <- jsonlite::parse_json(frontiers_df$json[1], simplifyVector = F)
#
# trips <- trips$trips
