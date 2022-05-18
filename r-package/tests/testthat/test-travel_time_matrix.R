context("Travel time matrix function")

# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

tester <- function(r5r_core = get("r5r_core", envir = parent.frame()),
                   origins = points[1:10, ],
                   destinations = points[1:10, ],
                   mode = "WALK",
                   mode_egress = "WALK",
                   departure_datetime = Sys.time(),
                   time_window = 1L,
                   percentiles = 50L,
                   fare_calculator = NULL,
                   max_fare = Inf,
                   max_walk_dist = Inf,
                   max_bike_dist = Inf,
                   max_trip_duration = 120L,
                   walk_speed = 3.6,
                   bike_speed = 12,
                   max_rides = 3,
                   max_lts = 2,
                   draws_per_minute = 5L,
                   n_threads = Inf,
                   verbose = FALSE,
                   progress = FALSE,
                   output_dir = NULL) {
  travel_time_matrix(
    r5r_core,
    origins = origins,
    destinations = destinations,
    mode = mode,
    mode_egress = mode_egress,
    departure_datetime = departure_datetime,
    time_window = time_window,
    percentiles = percentiles,
    fare_calculator = fare_calculator,
    max_fare = max_fare,
    max_walk_dist = max_walk_dist,
    max_bike_dist = max_bike_dist,
    max_trip_duration = max_trip_duration,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = max_rides,
    max_lts = max_lts,
    draws_per_minute = draws_per_minute,
    n_threads = n_threads,
    verbose = verbose,
    progress = progress,
    output_dir = output_dir
  )
}


# errors and warnings -----------------------------------------------------

test_that("errors due to incorrect input types - origins and destinations", {
  multipoint_origins <- sf::st_cast(
    sf::st_as_sf(points[1:2,], coords = c("lon", "lat")),
    "MULTIPOINT"
  )
  multipoint_destinations <- multipoint_origins

  list_destinations <- list_origins <- unclass(points)

  expect_error(tester(origins = multipoint_origins))
  expect_error(tester(destinations = multipoint_destinations))
  expect_error(tester(origins = list_origins))
  expect_error(tester(destinations = list_destinations))
  expect_error(tester(origins = "origins"))
  expect_error(tester(destinations = "destinations"))

  # wrong columns types

  origins <- destinations <- points[1:2, ]

  origins_char_lat <- origins
  origins_char_lat$lat <- as.character(origins$lat)
  origins_char_lon <- origins
  origins_char_lon$lon <- as.character(origins$lon)
  destinations_char_lat <- destinations
  destinations_char_lat$lat <- as.character(destinations$lat)
  destinations_char_lon <- destinations
  destinations_char_lon$lon <- as.character(destinations$lon)

  expect_error(tester(origins = origins_char_lat))
  expect_error(tester(origins = origins_char_lon))
  expect_error(tester(destinations = destinations_char_lat))
  expect_error(tester(destinations = destinations_char_lon))
})

test_that("errors due to incorrect input types - other inputs", {
  # mode and mode_egress are tested in select_mode() tests

  expect_error(tester(unclass(r5r_core)))

  expect_error(tester(departure_datetime = unclass(departure_datetime)))
  expect_error(tester(departure_datetime = rep(departure_datetime, 2)))

  expect_error(tester(time_window = "1"))
  expect_error(tester(time_window = c(12, 15)))
  expect_error(tester(time_window = 0))

  expect_error(tester(percentiles = "50"))
  expect_error(tester(percentiles = 0))
  expect_error(tester(percentiles = 100))
  expect_error(tester(percentiles = c(50, 50)))
  expect_error(tester(percentiles = 1:6))
  expect_error(tester(percentiles = NA))

  # TODO: test fare_calculator and max_fare

  expect_error(tester(max_walk_dist = "1000"))
  expect_error(tester(max_walk_dist = NULL))
  expect_error(tester(max_walk_dist = c(1000, 2000)))
  expect_error(tester(max_walk_dist = 1))

  expect_error(tester(max_bike_dist = "1000"))
  expect_error(tester(max_bike_dist = NULL))
  expect_error(tester(max_bike_dist = c(1000, 2000)))
  expect_error(tester(max_bike_dist = 1))

  expect_error(tester(max_trip_duration = "120"))
  expect_error(tester(max_trip_duration = c(25, 30)))

  expect_error(tester(walk_speed = "3.6"))
  expect_error(tester(walk_speed = c(3.6, 5)))
  expect_error(tester(walk_speed = 0))

  expect_error(tester(bike_speed = "12"))
  expect_error(tester(bike_speed = c(12, 15)))
  expect_error(tester(bike_speed = 0))

  expect_error(tester(max_rides = "3"))
  expect_error(tester(max_rides = c(3, 4)))
  expect_error(tester(max_rides = -1))

  expect_error(tester(max_lts = "3"))
  expect_error(tester(max_lts = c(3, 4)))
  expect_error(tester(max_lts = -1))

  expect_error(tester(draws_per_minute = "1"))
  expect_error(tester(draws_per_minute = c(12, 15)))
  expect_error(tester(draws_per_minute = 0))

  expect_error(tester(n_threads = "1"))
  expect_error(tester(n_threads = c(2, 3)))
  expect_error(tester(n_threads = 0))

  expect_error(tester(verbose = 1))
  expect_error(tester(verbose = NA))
  expect_error(tester(verbose = c(TRUE, TRUE)))

  expect_error(tester(output_dir = 1))
  expect_error(tester(output_dir = "non_existent_dir"))
})

test_that("adequately raises warnings - needs java", {

  # error/warning related to using wrong origins/destinations column types
  origins <- destinations <- points[1:2, ]

  origins_numeric_id <- data.frame(id = 1:2, lat = origins$lat, lon = origins$lon)
  destinations_numeric_id <- data.frame(id = 1:2, lat = destinations$lat, lon = destinations$lon)

  expect_warning(tester(origins = origins_numeric_id))
  expect_warning(tester(destinations = destinations_numeric_id))


})


# adequate behaviour ------------------------------------------------------


test_that("output is correct", {

  #  * output class ---------------------------------------------------------


  # expect results to be of class 'data.table', independently of the class of
  # 'origins'/'destinations'

  origins_sf <- destinations_sf <- sf::st_as_sf(
    points[1:10, ],
    coords = c("lon", "lat"),
    crs = 4326
  )

  result_df_input <- tester()
  result_sf_input <- tester(origins = origins_sf, destinations = destinations_sf)

  expect_true(is(result_df_input, "data.table"))
  expect_true(is(result_sf_input, "data.table"))

  # expect each column to be of right class

  expect_true(typeof(result_df_input$from_id) == "character")
  expect_true(typeof(result_df_input$to_id) == "character")
  expect_true(typeof(result_df_input$travel_time_p50) == "integer")


  #  * r5r options ----------------------------------------------------------


  # expect walking trips to be shorter when setting higher walk speeds

  max_trip_duration <- 500L
  origins <- destinations <- points[1:15,]

  df <- tester(origins = origins, destinations = destinations,
                       mode = "WALK", walk_speed = 3.6, max_trip_duration = max_trip_duration)
  travel_time_lower_speed <- data.table::setDT(df)[, max(travel_time_p50)]

  df <- tester(origins = origins, destinations = destinations,
                       mode = "WALK", walk_speed = 4, max_trip_duration = max_trip_duration)
  travel_time_higher_speed <- data.table::setDT(df)[, max(travel_time_p50)]

  expect_true(travel_time_higher_speed < travel_time_lower_speed)

  # expect bike segments to be shorter when setting higher bike speeds

  df <- tester(origins = origins, destinations = destinations,
                       mode = "BICYCLE", bike_speed = 12, max_trip_duration = max_trip_duration)
  travel_time_lower_speed <- data.table::setDT(df)[, max(travel_time_p50)]

  df <- tester(origins = origins, destinations = destinations,
                       mode = "BICYCLE", bike_speed = 13, max_trip_duration = max_trip_duration)
  travel_time_higher_speed <- data.table::setDT(df)[, max(travel_time_p50)]

  expect_true(travel_time_higher_speed < travel_time_lower_speed)


  #  * arguments ------------------------------------------------------------


  # expect all travel times to be lower than max_trip_duration

  max_trip_duration <- 60L

  df <- tester(max_trip_duration = max_trip_duration)
  max_duration <- data.table::setDT(df)[, max(travel_time_p50)]

  expect_true(max_duration <= max_trip_duration)

  # expect number of rows to be lower than or equal to nrow(origins) * nrow(destinations)

  max_trip_duration <- 300L

  df <- tester(max_trip_duration = max_trip_duration)
  n_rows <- nrow(df)

  expect_true(n_rows <= 100)

})
