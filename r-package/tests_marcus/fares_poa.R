# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
library(tidyverse)
library(sf)
library(h3jsr)
library(data.table)

# build transport network
data_path <- "~/Repos/r5r_fares/poa"
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)


# load origin/destination points

poi <- read.csv(system.file("extdata/poa/poa_points_of_interest.csv", package = "r5r"))
points_small <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
points_small$unit <- 1
points <- read_csv("~/Repos/r5r_fares/poa/poa_points.csv") %>%
  rename(id = id_hex)
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# Accessibility -----------------------------------------------------------

calculate_access <- function(fares) {

  access_df <- map_df(fares, function(f) {
    f <- as.integer(f)

    r5r_core$setMaxFare(f, "porto-alegre")

    access <- accessibility(r5r_core,
                            origins = points_small,
                            destinations = points_small,
                            departure_datetime = departure_datetime,
                            opportunities_colname = "unit",
                            mode = c("WALK", "TRANSIT"),
                            cutoffs = c(30, 45),
                            max_trip_duration = 45,
                            max_walk_dist = 800,
                            time_window = 1,
                            percentiles = 50,
                            verbose = FALSE)

    access$max_fare <- f

    return(access)
  })

  return(access_df)
}

access_df <- calculate_access(c(450, 480, 720)) %>%
  # access_df <- calculate_access(c(240, 480, 720, 960, -1)) %>%
  left_join(points, by = c("from_id" = "id"))

access_df %>%
  filter(cutoff == 30) %>%
  drop_na() %>%
  ggplot(aes(x=lon, y=lat)) +
  geom_point(size=1, aes(color=accessibility)) +
  geom_point(data=poi[c(1, 10),], color = "blue") +
  facet_grid(cutoff~max_fare) +
  scale_color_distiller(palette = "Spectral") +
  coord_map()



# Travel Times ------------------------------------------------------------

r5r_core$setMaxFare(-1L, "porto-alegre")
r5r_core$setMaxFare(80L, "porto-alegre")

ttm <- travel_time_matrix(r5r_core,
                        origins = poi[1,],
                        destinations = poi[10,],
                        departure_datetime = departure_datetime,
                        mode = c("WALK", "TRANSIT"),
                        breakdown = T,
                        max_trip_duration = 45,
                        max_walk_dist = 800,
                        time_window = 1,
                        percentiles = 50,
                        verbose = FALSE)


# Pareto ------------------------------------------------------------------

pareto_df <- pareto_frontier(r5r_core,
                             origins = poi[2,],
                             destinations = poi[3,],
                             mode = c("WALK", "TRANSIT"),
                             departure_datetime = departure_datetime,
                             monetary_cost_cutoffs = seq(0, 1000, 50),
                             fare_calculator = "porto-alegre",
                             max_trip_duration = 60,
                             max_walk_dist = 8000,
                             time_window = 1, #30,
                             percentiles = 50, # c(5, 50, 95),
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
  scale_y_continuous(breaks = seq(0, 50, 10), limits = c(0, 50)) +
  facet_grid(from_id~to_id)


r5r_core$setMaxFare(10L, "rio-de-janeiro")
r5r_core$verboseMode()



# Transit Network ---------------------------------------------------------

tn = transit_network_to_sf(r5r_core)
tn$routes %>% View()

mapview::mapview(tn$routes)

