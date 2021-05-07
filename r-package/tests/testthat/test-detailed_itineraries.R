context("Detailed itineraries function")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

# load required data and setup r5r_core

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# create testing function

default_tester <- function(r5r_core,
                           origins = points[1:2, ],
                           destinations = points[2:1, ],
                           mode = c("WALK", "TRANSIT"),
                           departure_datetime = as.POSIXct("13-05-2019 14:00:00",
                                                           format = "%d-%m-%Y %H:%M:%S"),
                           max_walk_dist = Inf,
                           max_trip_duration = 120L,
                           walk_speed = 3.6,
                           bike_speed = 12,
                           max_rides = 3,
                           shortest_path = TRUE,
                           n_threads = Inf,
                           verbose = FALSE,
                           drop_geometry = FALSE) {

 results <- detailed_itineraries(
   r5r_core,
   origins = origins,
   destinations = destinations,
   mode = mode,
   departure_datetime = departure_datetime,
   max_walk_dist = max_walk_dist,
   max_trip_duration = max_trip_duration,
   walk_speed = walk_speed,
   bike_speed = bike_speed,
   max_rides = max_rides,
   shortest_path = shortest_path,
   n_threads = n_threads,
   verbose = verbose,
   drop_geometry = drop_geometry
 )

 return(results)

}


# errors and warnings -----------------------------------------------------


test_that("detailed_itineraries adequately raises errors", {

  # error related to using object with wrong type as r5r_core
  expect_error(default_tester("r5r_core"))

  # error related to using wrong origins/destinations object type
  multipoint_origins      <- sf::st_cast(sf::st_as_sf(points[1:2,], coords = c("lon", "lat")), "MULTIPOINT")
  multipoint_destinations <- sf::st_cast(sf::st_as_sf(points[2:1,], coords = c("lon", "lat")), "MULTIPOINT")
  list_origins      <- list(id = c("1", "2"), lat = c(-30.02756, -30.02329), long = c(-51.22781, -51.21886))
  list_destinations <- list(id = c("2", "1"), lat = c(-30.02329, -30.02756), long = c(-51.21886, -51.22781))

  expect_error(default_tester(r5r_core, origins = multipoint_origins))
  expect_error(default_tester(r5r_core, destinations = multipoint_destinations))
  expect_error(default_tester(r5r_core, origins = list_origins))
  expect_error(default_tester(r5r_core, destinations = list_destinations))
  expect_error(default_tester(r5r_core, origins = "origins"))
  expect_error(default_tester(r5r_core, destinations = "destinations"))

  # error related to using wrong origins/destinations column types
  origins <- points[1:2, ]
  destinations <- points[2:1, ]

  origins_char_lat   <- data.frame(id = origins$id, lat = as.character(origins$lat), lon = origins$lon)
  origins_char_lon   <- data.frame(id = origins$id, lat = origins$lat, lon = as.character(origins$lon))
  destinations_char_lat   <- data.frame(id = destinations$id, lat = as.character(destinations$lat), lon = destinations$lon)
  destinations_char_lon   <- data.frame(id = destinations$id, lat = destinations$lat, lon = as.character(destinations$lon))

  expect_error(default_tester(r5r_core, origins = origins_char_lat))
  expect_error(default_tester(r5r_core, origins = origins_char_lon))
  expect_error(default_tester(r5r_core, destinations = destinations_char_lat))
  expect_error(default_tester(r5r_core, destinations = destinations_char_lon))

  # error related to 'origins' and 'destinations' with distinct number of rows
  expect_error(default_tester(r5r_core, origins = points[1:3,], destinations = points[2:1,]))
  expect_error(default_tester(r5r_core, origins = points[2:1,], destinations = points[1:3,]))

  # error related to nonexistent mode
  expect_error(default_tester(r5r_core, mode = "all"))

  # errors related to date formatting
  numeric_datetime <- as.numeric(as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))

  expect_error(default_tester(r5r_core, departure_datetime = "13-05-2019 14:00:00"))
  expect_error(default_tester(r5r_core, numeric_datetime))

  # errors related to max_walk_dist
  expect_error(default_tester(r5r_core, max_walk_dist = "1"))
  expect_error(default_tester(r5r_core, max_walk_dist = NULL))

  # error/warning related to max_street_time
  expect_error(default_tester(r5r_core, max_trip_duration = "120"))

  # error related to non-numeric walk_speed
  expect_error(default_tester(r5r_core, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(default_tester(r5r_core, bike_speed = "12"))

  # error related to non-numeric max_rides
  expect_error(default_tester(r5r_core, max_rides = "3"))

  # error related to non-logical shortest_path
  expect_error(default_tester(r5r_core, shortest_path = "TRUE"))
  expect_error(default_tester(r5r_core, shortest_path = 1))
  expect_error(default_tester(r5r_core, shortest_path = NULL))

  # error related to non-numeric n_threads
  expect_error(default_tester(r5r_core, n_threads = "1"))

  # error related to non-logical verbose
  expect_error(default_tester(r5r_core, verbose = "TRUE"))
  expect_error(default_tester(r5r_core, verbose = 1))
  expect_error(default_tester(r5r_core, verbose = NULL))

  # error related to non-logical drop_geometry
  expect_error(default_tester(r5r_core, drop_geometry = "TRUE"))
  expect_error(default_tester(r5r_core, drop_geometry = 1))

})

test_that("detailed_itineraries adequately raises warnings and messages - needs java", {

  # message related to expanding origins/destinations dataframe
  expect_message(default_tester(r5r_core, origins = points[1, ]))
  expect_message(default_tester(r5r_core, destinations = points[1, ]))

  # error/warning related to using wrong origins/destinations column types
  origins <- points[1:2, ]
  destinations <- points[2:1, ]

  origins_numeric_id <- data.frame(id = 1:2, lat = origins$lat, lon = origins$lon)
  destinations_numeric_id <- data.frame(id = 1:2, lat = destinations$lat, lon = destinations$lon)

  expect_warning(default_tester(r5r_core, origins = origins_numeric_id))
  expect_warning(default_tester(r5r_core, destinations = destinations_numeric_id))


})


# adequate behaviour ------------------------------------------------------


test_that("detailed_itineraries output is correct", {

  #  * output class ---------------------------------------------------------


  # expect results to be of class 'sf' and 'data.table', independently of the
  # class of 'origins'/'destinations', when drop_geometry = FALSE

  origins_sf      <- sf::st_as_sf(points[1:2,], coords = c("lon", "lat"))
  destinations_sf <- sf::st_as_sf(points[2:1,], coords = c("lon", "lat"))

  result_df_input <- default_tester(r5r_core)
  result_sf_input <- default_tester(r5r_core, origins_sf, destinations_sf)

  expect_true(is(result_df_input, "sf"))
  expect_true(is(result_df_input, "data.table"))
  expect_true(is(result_sf_input, "sf"))
  expect_true(is(result_sf_input, "data.table"))

  # expect results to be of class 'data.table', but not 'sf', independently of
  # the class of 'origins'/'destinations', when drop_geometry = TRUE

  result_df_input <- default_tester(r5r_core, drop_geometry = TRUE)
  result_sf_input <- default_tester(r5r_core, origins_sf, destinations_sf, drop_geometry = TRUE)

  expect_false(is(result_df_input, "sf"))
  expect_true(is(result_df_input, "data.table"))
  expect_false(is(result_sf_input, "sf"))
  expect_true(is(result_sf_input, "data.table"))

  # expect each column to be of right class

  expect_true(typeof(result_df_input$fromId) == "character")
  expect_true(typeof(result_df_input$fromLat) == "double")
  expect_true(typeof(result_df_input$fromLon) == "double")
  expect_true(typeof(result_df_input$toId) == "character")
  expect_true(typeof(result_df_input$toLat) == "double")
  expect_true(typeof(result_df_input$toLon) == "double")
  expect_true(typeof(result_df_input$option) == "integer")
  expect_true(typeof(result_df_input$segment) == "integer")
  expect_true(typeof(result_df_input$mode) == "character")
  expect_true(typeof(result_df_input$total_duration) == "double")
  expect_true(typeof(result_df_input$segment_duration) == "double")
  expect_true(typeof(result_df_input$wait) == "double")
  expect_true(typeof(result_df_input$distance) == "integer")
  expect_true(typeof(result_df_input$route) == "character")


  #  * r5r options ----------------------------------------------------------


  # expect walking segments to be shorter when setting higher walk speeds
  # ps: note that if a very high speed is set then the routes change completely
  # and we lose the ability to use lower walking speeds routes as reference

  origins      <- points[10,]
  destinations <- points[12,]

  df <- default_tester(r5r_core, origins = origins, destinations = destinations, mode = "WALK", walk_speed = 4)
  duration_lower_speed <- data.table::setDT(df)$segment_duration

  df <- default_tester(r5r_core, origins = origins, destinations = destinations, mode = "WALK", walk_speed = 5)
  duration_higher_speed <- data.table::setDT(df)$segment_duration

  expect_true(duration_higher_speed < duration_lower_speed)

  # expect bike segments to be shorter when setting higher cycling speeds
  # ps: same as with walk_speeds

  df <- default_tester(r5r_core, origins = origins, destinations = destinations,
                       mode = "BICYCLE", bike_speed = 12)
  duration_lower_speed <- data.table::setDT(df)$segment_duration

  df <- default_tester(r5r_core, origins = origins, destinations = destinations,
                       mode = "BICYCLE", bike_speed = 13)
  duration_higher_speed <- data.table::setDT(df)$segment_duration

  expect_true(duration_higher_speed < duration_lower_speed)


  #  * arguments ------------------------------------------------------------


  # expect each OD pair to have only option when shortest_path == TRUE

  df <- default_tester(r5r_core, shortest_path = TRUE)
  max_n_options <- data.table::setDT(df)[, length(unique(option)), by = .(fromId, toId)][, max(V1)]

  expect_true(max_n_options == 1)

  # expect each OD pair to have (possibly) more than one option when shortest_path == FALSE

  df <- default_tester(r5r_core, shortest_path = FALSE)
  max_n_options <- data.table::setDT(df)[, length(unique(option)), by = .(fromId, toId)][, max(V1)]

  expect_true(max_n_options > 1)

  # expect all route options to have lower total duration than max_trip_duration

  max_trip_duration <- 60L
  origins <- points[1:15,]
  destinations <- points[15:1,]

  df <- default_tester(r5r_core, origins, destinations,
                       max_trip_duration = max_trip_duration, shortest_path = FALSE)

  max_duration <- data.table::setDT(df)[, sum(segment_duration), by = .(fromId, toId, option)][, max(V1)]

  expect_true(max_duration < max_trip_duration)

  # expect a NULL data.table as output when no routes are found between the pairs

  df <- default_tester(r5r_core, origins = points[10,], destinations = points[12,],
                       mode = "WALK", max_trip_duration = 30L)

  expect_true(length(df) == 0)

  df <- default_tester(r5r_core, origins = points[10:11,], destinations = points[12,],
                       mode = "WALK", max_trip_duration = 30L)

  expect_true(length(df) == 0)

})

stop_r5(r5r_core)
