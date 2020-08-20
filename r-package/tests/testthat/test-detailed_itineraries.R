context("Detailed itineraries function")

# load required data and setup r5r_core

data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# create testing function

detailed_itineraries_tester <- function(r5r_core,
                                        origins = points[1:15, ],
                                        destinations = points[15:1, ],
                                        departure_datetime = as.POSIXct("13-03-2019 14:00:00",
                                                                        format = "%d-%m-%Y %H:%M:%S"),
                                        max_walk_dist = 1,
                                        mode = c("WALK", "BUS"),
                                        max_trip_duration = 120L,
                                        walk_speed = 3.6,
                                        bike_speed = 12,
                                        shortest_path = TRUE,
                                        nThread = Inf,
                                        verbose = TRUE) {

  results <- detailed_itineraries(
    r5r_core,
    origins,
    destinations,
    departure_datetime,
    max_walk_dist,
    mode,
    max_trip_duration,
    walk_speed,
    bike_speed,
    shortest_path,
    nThread,
    verbose
  )

  return(results)

}

test_that("detailed_itineraries adequately raises warnings and errors", {

  # message related to expanding origins dataframe
  expect_message(detailed_itineraries_tester(r5r_core, origins = points[1, ]))

  # error related to using a MULTIPOINT sf as origin
  expect_error(
    detailed_itineraries_tester(
      r5r_core,
      origins = sf::st_cast(sf::st_as_sf(points, coords = c("lon", "lat")), "MULTIPOINT")
    )
  )


  # message related to expanding destinations dataframe
  expect_message(detailed_itineraries_tester(r5r_core, destinations = points[1, ]))

  # errors related to date formatting
  expect_error(detailed_itineraries_tester(r5r_core, departure_datetime = "13-03-2019 14:00:00"))
  expect_error(
    detailed_itineraries_tester(
      r5r_core,
      departure_datetime = as.numeric(as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))
    )
  )

  # errors related to max_walk_dist
  expect_error(detailed_itineraries_tester(r5r_core, max_walk_dist = "1"))

  # error related to nonexistent mode
  expect_error(detailed_itineraries_tester(r5r_core, mode = "MOTORCYCLE"))

  # warnings and errors related to max_street_time
  expect_error(detailed_itineraries_tester(r5r_core, max_trip_duration = "120"))
  expect_warning(detailed_itineraries_tester(r5r_core, max_trip_duration = 120))

  # error related to non-numeric walk_speed
  expect_error(detailed_itineraries_tester(r5r_core, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(detailed_itineraries_tester(r5r_core, bike_speed = "12"))

})

stop_r5(r5r_core)
