context("Travel time matrix function")

# skips tests on CRAN and Travis since they require a specific version of java
testthat::skip_on_cran()
testthat::skip_on_travis()

# load required data and setup r5r_obj

data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# create testing function

default_tester <- function(r5r_obj,
                           origins = points[1:10,],
                           destinations = points[1:10,],
                           mode = "BICYCLE",
                           departure_datetime = as.POSIXct("13-03-2019 14:00:00",
                                                           format = "%d-%m-%Y %H:%M:%S"),
                           max_walk_dist = Inf,
                           max_trip_duration = 120L,
                           walk_speed = 3.6,
                           bike_speed = 12,
                           max_rides = 3,
                           n_threads = Inf,
                           verbose = FALSE) {

  results <- travel_time_matrix(
    r5r_obj,
    origins,
    destinations,
    mode,
    departure_datetime,
    max_walk_dist,
    max_trip_duration,
    walk_speed,
    bike_speed,
    max_rides,
    n_threads,
    verbose
  )

  return(results)

}


# errors and warnings -----------------------------------------------------


test_that("travel_time_matrix adequately raises errors", {

  # error related to using object with wrong type as r5r_core
  expect_error(default_tester("r5r_obj"))

  # error related to using wrong origins/destinations object type
  multipoint_origins      <- sf::st_cast(sf::st_as_sf(points[1:2,], coords = c("lon", "lat")), "MULTIPOINT")
  multipoint_destinations <- multipoint_origins
  list_origins      <- list(id = c("1", "2"), lat = c(-30.02756, -30.02329), long = c(-51.22781, -51.21886))
  list_destinations <- list_origins

  expect_error(default_tester(r5r_obj, origins = multipoint_origins))
  expect_error(default_tester(r5r_obj, destinations = multipoint_destinations))
  expect_error(default_tester(r5r_obj, origins = list_origins))
  expect_error(default_tester(r5r_obj, destinations = list_destinations))
  expect_error(default_tester(r5r_obj, origins = "origins"))
  expect_error(default_tester(r5r_obj, destinations = "destinations"))

  # error/warning related to using wrong origins/destinations column types
  origins <- destinations <- points[1:2, ]

  origins_char_lat   <- data.frame(id = origins$id, lat = as.character(origins$lat), lon = origins$lon)
  origins_char_lon   <- data.frame(id = origins$id, lat = origins$lat, lon = as.character(origins$lon))
  destinations_char_lat   <- data.frame(id = destinations$id, lat = as.character(destinations$lat), lon = destinations$lon)
  destinations_char_lon   <- data.frame(id = destinations$id, lat = destinations$lat, lon = as.character(destinations$lon))

  expect_error(default_tester(r5r_obj, origins = origins_char_lat))
  expect_error(default_tester(r5r_obj, origins = origins_char_lon))
  expect_error(default_tester(r5r_obj, destinations = destinations_char_lat))
  expect_error(default_tester(r5r_obj, destinations = destinations_char_lon))

  # error related to nonexistent mode
  expect_error(default_tester(r5r_obj, mode = "pogoball"))

  # errors related to date formatting
  numeric_datetime <- as.numeric(as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))

  expect_error(default_tester(r5r_obj, departure_datetime = "13-03-2019 14:00:00"))
  expect_error(default_tester(r5r_obj, numeric_datetime))

  # errors related to max_walk_dist
  expect_error(default_tester(r5r_obj, max_walk_dist = "1000"))
  expect_error(default_tester(r5r_obj, max_walk_dist = NULL))

  # error/warning related to max_street_time
  expect_error(default_tester(r5r_obj, max_trip_duration = "120"))

  # error related to non-numeric walk_speed
  expect_error(default_tester(r5r_obj, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(default_tester(r5r_obj, bike_speed = "12"))

  # error related to non-numeric max_rides
  expect_error(default_tester(r5r_obj, max_rides = "3"))

  # error related to non-numeric n_threads
  expect_error(default_tester(r5r_obj, n_threads = "1"))

  # error related to non-logical verbose
  expect_error(default_tester(r5r_obj, verbose = "TRUE"))
  expect_error(default_tester(r5r_obj, verbose = 1))
  expect_error(default_tester(r5r_obj, verbose = NULL))

})

test_that("detailed_itineraries adequately raises warnings - needs java", {

  # error/warning related to using wrong origins/destinations column types
  origins <- destinations <- points[1:2, ]

  origins_numeric_id <- data.frame(id = 1:2, lat = origins$lat, lon = origins$lon)
  destinations_numeric_id <- data.frame(id = 1:2, lat = destinations$lat, lon = destinations$lon)

  expect_warning(default_tester(r5r_obj, origins = origins_numeric_id))
  expect_warning(default_tester(r5r_obj, destinations = destinations_numeric_id))


})


# adequate behaviour ------------------------------------------------------


test_that("detailed_itineraries output is correct", {

  #  * output class ---------------------------------------------------------


  # expect results to be of class 'data.table', independently of the class of
  # 'origins'/'destinations'

  origins_sf <- destinations_sf <-  sf::st_as_sf(points[1:10,], coords = c("lon", "lat"))

  result_df_input <- default_tester(r5r_obj)
  result_sf_input <- default_tester(r5r_obj, origins_sf, destinations_sf)

  expect_true(is(result_df_input, "data.table"))
  expect_true(is(result_sf_input, "data.table"))

  # expect each column to be of right class

  expect_true(typeof(result_df_input$fromId) == "character")
  expect_true(typeof(result_df_input$toId) == "character")
  expect_true(typeof(result_df_input$travel_time) == "integer")


  #  * r5r options ----------------------------------------------------------


  # expect walking trips to be shorter when setting higher walk speeds

  max_trip_duration <- 500L
  origins <- destinations <- points[1:15,]

  df <- default_tester(r5r_obj, origins = origins, destinations = destinations,
                       mode = "WALK", walk_speed = 3.6, max_trip_duration = max_trip_duration)
  travel_time_lower_speed <- data.table::setDT(df)[, max(travel_time)]

  df <- default_tester(r5r_obj, origins = origins, destinations = destinations,
                       mode = "WALK", walk_speed = 4, max_trip_duration = max_trip_duration)
  travel_time_higher_speed <- data.table::setDT(df)[, max(travel_time)]

  expect_true(travel_time_higher_speed < travel_time_lower_speed)

  # expect bike segments to be shorter when setting higher walk speeds

  df <- default_tester(r5r_obj, origins = origins, destinations = destinations,
                       mode = "BICYCLE", walk_speed = 12, max_trip_duration = max_trip_duration)
  travel_time_lower_speed <- data.table::setDT(df)[, max(travel_time)]

  df <- default_tester(r5r_obj, origins = origins, destinations = destinations,
                       mode = "BICYCLE", walk_speed = 13, max_trip_duration = max_trip_duration)
  travel_time_higher_speed <- data.table::setDT(df)[, max(travel_time)]

  expect_true(travel_time_higher_speed < travel_time_lower_speed)


  #  * arguments ------------------------------------------------------------


  # expect all travel times to be lower than max_trip_duration

  max_trip_duration <- 60L

  df <- default_tester(r5r_obj, origins, destinations, max_trip_duration = max_trip_duration)
  max_duration <- data.table::setDT(df)[, max(travel_time)]

  expect_true(max_duration <= max_trip_duration)

  # expect number of rows to be lower than or equal to nrow(origins) * nrow(destinations)

  max_trip_duration <- 300L

  df <- default_tester(r5r_obj, origins, destinations, max_trip_duration = max_trip_duration)
  n_rows <- nrow(df)

  expect_true(n_rows <= nrow(origins) * nrow(destinations))

})

