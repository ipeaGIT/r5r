context("Detailed itineraries function")

# load required data and setup r5r_core

data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# create testing function

detailed_itineraries_tester <- function(r5r_core,
                                        origins = points[1:5, ],
                                        destinations = points[2:6, ],
                                        mode = c("WALK"),
                                        trip_date = "2019-03-13",
                                        departure_time = "14:00:00",
                                        max_street_time = 120L,
                                        walk_speed = 3.6,
                                        bike_speed = 12,
                                        shortest_path = TRUE,
                                        nThread = Inf) {

  results <- detailed_itineraries(r5r_core,
                                  origins,
                                  destinations,
                                  mode,
                                  trip_date,
                                  departure_time,
                                  max_street_time,
                                  walk_speed,
                                  bike_speed,
                                  shortest_path,
                                  nThread)

  return(results)

}

test_that("detailed_itineraries adequately raises warnings and errors", {

  # message related to expanding origins dataframe
  expect_message(detailed_itineraries_tester(r5r_core, origins = points[1, ]))

  # message related to expanding destinations dataframe
  expect_message(detailed_itineraries_tester(r5r_core, destinations = points[6, ]))

  # error related to nonexistent mode
  expect_error(detailed_itineraries_tester(r5r_core, mode = "MOTORCYCLE"))

  # errors related to date formatting
  expect_error(detailed_itineraries_tester(r5r_core, trip_date = "13-03-2019"))
  expect_error(detailed_itineraries_tester(r5r_core, trip_date = "2019-13-03"))
  expect_error(detailed_itineraries_tester(r5r_core, trip_date = "2019-03-mar"))

  # errors related to departure time formatting
  expect_error(detailed_itineraries_tester(r5r_core, departure_time = "14:00"))

  # warnings and errors related to max_street_time
  expect_error(detailed_itineraries_tester(r5r_core, max_street_time = "7200"))
  expect_warning(detailed_itineraries_tester(r5r_core, max_street_time = 7200))

  # error related to non-numeric walk_speed
  expect_error(detailed_itineraries_tester(r5r_core, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(detailed_itineraries_tester(r5r_core, bike_speed = "12"))

})

stop_r5(r5r_core)
