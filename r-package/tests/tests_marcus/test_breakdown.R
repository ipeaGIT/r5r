options(java.parameters = '-Xmx16G')
# library(r5r)
devtools::load_all(".")
library(data.table)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/destination points
points <- fread(file.path(data_path, "poa_hexgrid.csv"))

# r5r_core$setCsvOutput(here::here("csv"))

# Calculate 3 TTMs, one for each minute of the TTM with the time_window setting
system.time(
  ttm <- travel_time_matrix(r5r_core,
                            origins = points[id == "89a901291abffff",], #[id == "89a901288c3ffff",],
                            destinations = points[id == "89a901295b7ffff"], #[id == "89a90129953ffff",],
                            mode = c("WALK", "TRANSIT"),
                            max_trip_duration = 60,
                            time_window = 60,
                            draws_per_minute = 10,
                            percentiles = c(25, 50, 75),
                            departure_datetime = lubridate::mdy_hm("4/19/19 12:00pm"),
                            verbose = F,
                            progress = T,
                            breakdown = T)
  )

ttm[from_id != to_id,] |>head(100) |> View()


ttm %>%
  arrange(departure_time) %>%
  write_csv("ttm_breakdown_full.csv")

fs <- setup_fare_calculator(r5r_core, 5, by = "generic")
View(fs$fares_per_mode)
View(fs$fares_per_route)
View(fs$fares_per_transfer)
