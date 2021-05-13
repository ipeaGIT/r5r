##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

library(r5r)
library(magrittr)
library(data.table)
library(h3jsr)
library(sf)

path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path)


##### input
origins <- destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r")) %>% setDT()

destinations[, opportunities := schools]
destinations <- destinations[opportunities > 0]

trip_date = "2019-05-20"
departure_time = "14:00:00"
mode = c('WALK', 'TRANSIT')

##### Max threads

system.time(
  df_acc <- accessibility( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            departure_datetime = lubridate::ymd_hm("2019-05-20 14:00"),
                            time_window = 30,
                            percentiles = c(25, 50, 75),
                            cutoffs = c(15, 30, 45, 60),
                            mode = mode,
                            max_walk_dist = 300,
                            max_trip_duration = 60,
                            verbose = FALSE
  )
)



df$geometry <- h3jsr::h3_to_polygon(df$from_id)

df %>%
  ggplot() +
  geom_sf(aes(geometry=geometry, fill=accessibility), color = NA) +
  coord_sf() +
  facet_grid(cutoff~percentile)



