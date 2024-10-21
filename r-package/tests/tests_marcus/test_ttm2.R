options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

devtools::load_all(".")
# library(ggplot2)
library(data.table)
library(tidyverse)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
points <- fread(file.path(data_path, "poa_hexgrid.csv"))
fares <- read_fare_structure(file.path(data_path, "fares/fares_poa.zip"))


dir.create(here::here("csv"))

# r5r_core$setCsvOutput(here::here("csv"))

tictoc::tic()
normal_ttm <- travel_time_matrix(r5r_core, origins = points, #[id == "89a9012a3cfffff",],
                                 destinations = points, #[id == "89a901284a3ffff",],
                                 mode = c("WALK", "TRANSIT"),
                                 departure_datetime = departure_datetime,
                                 max_trip_duration = 60,
                                 max_walk_time = 15,
                                 time_window = 30,
                                 percentiles = c(1, 25, 50, 75, 99),
                                 verbose = FALSE,
                                 progress = TRUE,
                                 fare_structure = fares,
                                 max_fare = 8)
tictoc::toc()

write_csv(normal_ttm, here::here('csv', 'ttm_original.csv'))
# fixed equal - 658.054 sec elapsed
# fixed diff  - 703.872 sec elapsed
# original    - 702.352 sec elapsed


ttm_or <- read_csv(here::here('csv', 'ttm_original.csv'))
ttm_fx <- read_csv(here::here('csv', 'ttm_fixed_equal.csv'))

ttm_or2 <-  ttm_or |> pivot_longer(cols = starts_with('travel_time'), names_to = 'percentile', values_to = 'travel_time_or')
ttm_fx2 <-  ttm_fx |> pivot_longer(cols = starts_with('travel_time'), names_to = 'percentile', values_to = 'travel_time_fx')

ttm_j <- left_join(ttm_or2, ttm_fx2) |>
  mutate(eq = travel_time_or == travel_time_fx)
