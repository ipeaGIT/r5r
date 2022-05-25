# options(java.parameters = '-Xmx2G')


# load stuff --------------------------------------------------------------

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)
library(sf)
library(mapview)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, elevation = "none")

# load points
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))

# load fare structure
fare_structure_path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
fare_structure <- read_fare_structure(fare_structure_path)

diff_frontiers_df <- read_csv(here::here("diff_frontiers.csv"))



# check differences -------------------------------------------------------


# find itineraries --------------------------------------------------------

plot_pareto <- function(df) {
  o <- df$from_id[1]
  d <- df$to_id[1]

  orig <- points  %>% filter(id == o)
  dest <-  points %>% filter(id == d)

  r5r_core$setTravelAllowance(TRUE)
  full_frontiers_with_ta_df <- pareto_frontier(r5r_core,
                                               origins = orig,
                                               destinations = dest,
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
                                             origins = orig,
                                             destinations = dest,
                                             departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                                             format = "%d-%m-%Y %H:%M:%S"),
                                             mode = c("WALK", "TRANSIT"),
                                             max_trip_duration = 180,
                                             fare_structure = fare_structure,
                                             monetary_cost_cutoffs = c(1, 4.5, 4.8, 7.20, 8.37, 11.4, 12.57),
                                             max_rides = 5,
                                             progress = TRUE)

  full_frontiers_with_ta_df$scenario <- "with_ta"
  full_frontiers_no_ta_df$scenario <- "no_ta"

  full_frontiers <- rbind(full_frontiers_no_ta_df, full_frontiers_with_ta_df)

  p <- full_frontiers %>%
    ggplot(aes(x=monetary_cost, y=travel_time, color=scenario)) +
    geom_step(position=position_dodge(width=0.2)) +
    geom_point(position=position_dodge(width=0.2))

  return(p)
}

plots <- lapply(1:16, function(i) plot_pareto(diff_frontiers_df[i, ]))

library(patchwork)

wrap_plots(plots, ncol=4) + plot_layout(guides = "collect")


plot_pareto(diff_frontiers_df[1,])
plot_pareto(diff_frontiers_df[9,])
plot_pareto(diff_frontiers_df[15,])







system.time(
  frontiers_df <- pareto_itineraries(r5r_core,
                                     # origins = poi[10, ],
                                     # destinations = poi[12, ],
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


