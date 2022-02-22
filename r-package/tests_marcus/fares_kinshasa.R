
# library("r5r")
devtools::load_all(".")
library("data.table")
library("tidyverse")
library("sf")
library("gtfstools")

data_path <- here::here("tests_marcus/kinshasa")
r5r_core <- r5r::setup_r5(data_path, verbose = FALSE)



# build fare calculator ---------------------------------------------------

fare_calculator <- r5r::setup_fare_calculator(r5r_core, 100)


  # adjust the fare values based on the fuel_price_change. the weight of the
  # fuel price on the final fare depends on the agency that operates each mode.
  # round the price to keep all fares as integers

  gtfs <- gtfstools::read_gtfs(here::here("tests_marcus/kinshasa", "Time.zip"))

  # assign the fare_type based on the fare_id of each route
  # we use a relational vector to get the fare id based on the route id

  fare_id_per_route <- gtfs$fare_rules$fare_id
  names(fare_id_per_route) <- gtfs$fare_rules$route_id

  fare_calculator$fares_per_route[
    ,
    fare_type := paste0(fare_type, "_FAREID_", fare_id_per_route[route_id])
  ]

  # update the fare values based on the values listed on fare_attributes

  new_fare_per_mode <- data.table::data.table(
    mode = paste0("BUS_FAREID_", gtfs$fare_attributes$fare_id),
    unlimited_transfers = FALSE,
    allow_same_route_transfer = FALSE,
    use_route_fare = FALSE,
    fare = gtfs$fare_attributes$price
  )
  fare_calculator$fares_per_mode <- new_fare_per_mode

  # remove any discounted transfers from the fare calculator

  fare_calculator$fares_per_transfer <- data.table::data.table()

  # update routes_info to display the correct fares - won't change anything,
  # because the values will be taken from fare_per_mode, but just makes
  # everything clearer

  fare_calculator$fares_per_route[
    fare_calculator$fares_per_mode,
    on = c(fare_type = "mode"),
    route_fare := i.fare
  ]


# test fare calculator ----------------------------------------------------

  # get centroids coordinates

  grid_path <- here::here("tests_marcus/kinshasa", "Uber_H3_8.csv")
  grid_data <- data.table::fread(grid_path)

  sample = 100
  if (sample) grid_data <- grid_data[sample(1:nrow(grid_data), sample)]



  max_rides <- 5
  max_fare <- 2000
  monetary_cost_cutoffs <- c(500, 1000, 1500, 2000, 5000)
  # monetary_cost_cutoffs <- generate_cost_cutoffs(
  #   fare_calculator,
  #   "kinshasa",
  #   max_fare = 2000,
  #   max_rides = 3
  # )

  departure <- as.POSIXct("10-05-2021 07:00:00", format = "%d-%m-%Y %H:%M:%S")

  mapview::mapview(grid_data, xcol="lon", ycol="lat", crs=4326)
  # a <- r5r_core$getTransitServicesByDate("2021-05-10")
  # b <- java_to_dt(a)

  # sn <- street_network_to_sf(r5r_core)
  # mapview::mapview(sn$edges)

  fare_calculator$debug_settings$output_file <- here::here("tests_marcus/kinshasa/kins_debug.csv")

  frontier <- r5r::pareto_frontier(
    r5r_core,
    origins = grid_data,
    destinations = grid_data,
    mode = c("WALK", "TRANSIT"),
    departure_datetime = departure,
    time_window = 1,
    max_walk_dist = 2500,
    max_trip_duration = 180,
    max_rides = max_rides,
    fare_calculator_settings = fare_calculator,
    monetary_cost_cutoffs = monetary_cost_cutoffs,
    verbose = FALSE
  )

  ttm2 <- r5r::travel_time_matrix(
    r5r_core,
    origins = grid_data,
    destinations = grid_data,
    mode = c("WALK", "TRANSIT"),
    departure_datetime = departure,
    time_window = 1,
    max_walk_dist = 2500,
    max_trip_duration = 180,
    max_rides = max_rides,
    fare_calculator_settings = fare_calculator,
    max_fare = 1000,
    verbose = FALSE
  )

View(fare_calculator$fares_per_mode)
View(fare_calculator$fares_per_route)
View(fare_calculator$fares_per_transfer)



fare_json <- r5r_core$getFareStructure()
clipr::write_clip(fare_json)


ttm_c <- full_join(ttm1, ttm2, by = c("fromId", "toId")) %>%
  mutate(diff = travel_time.x - travel_time.y)

dbg <- read_csv(here::here("tests_marcus/kinshasa/kins_debug.csv"))
