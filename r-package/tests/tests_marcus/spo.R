devtools::load_all(".")

spo_path <- system.file("extdata/spo", package = "r5r")
spo_core <- setup_r5(spo_path, verbose = FALSE)
spo_points <- data.table::fread(file.path(spo_path, "spo_hexgrid.csv"))
spo_points[, opportunities := 1]
spo_fare_struc <- setup_fare_structure(spo_core, 5, by = "GENERIC")
spo_fare_struc$fares_per_transfer <- data.table::data.table(NULL)

departure_datetime <- as.POSIXct("13-05-2019 14:07:00",
                                 format = "%d-%m-%Y %H:%M:%S")

basic_expr <- call(
  "pareto_frontier",
  r5r_core = spo_core,
  origins = spo_points[id == "89a8100c08fffff"],
  destinations = spo_points[id == "89a8100c557ffff"],
  mode = c("TRANSIT", "WALK"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60,
  time_window = 30,
  percentiles = c(1, 50, 99),
  fare_structure = spo_fare_struc,
  monetary_cost_cutoffs = c(0, 5, 10, 15, Inf)*100,
  draws_per_minute = 10,
  verbose=F
)
frontier <- eval(basic_expr)
print(frontier$monetary_cost |> unique())


ttm_expr <- call(
  "expanded_travel_time_matrix",
  r5r_core = spo_core,
  origins = spo_points[id == "89a8100c08fffff"],
  destinations = spo_points[id == "89a8100c557ffff"],
  mode = c("TRANSIT", "WALK"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60,
  time_window = 30,
  draws_per_minute = 1
)
ttm <- eval(ttm_expr)
print(ttm$routes |> unique())

spo_core$setDetailedItinerariesV2(TRUE)


spo_core$hasFrequencies()
spo_core$hasS
dit_expr <- call(
  "detailed_itineraries",
  r5r_core = spo_core,
  origins = spo_points[id == "89a8100c08fffff"],
  destinations = spo_points[id == "89a8100c557ffff"],
  mode = c("TRANSIT", "WALK"),
  fare_structure = spo_fare_struc,
  max_fare=10,
  departure_datetime = departure_datetime,
  max_trip_duration = 60,
  time_window = 10,
  verbose = T
)
dit <- eval(dit_expr)

spo_core$verboseMode()
spo_core$printHasSchedules()

