context("Detailed itineraries function")

# load required data and setup r5r_obj

data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# create testing function

detailed_itineraries_tester <- function(r5r_obj,
                                        origins = points[1:15, ],
                                        destinations = points[15:1, ],
                                        mode = c("WALK", "BUS"),
                                        departure_datetime = as.POSIXct("13-03-2019 14:00:00",
                                                                        format = "%d-%m-%Y %H:%M:%S"),
                                        max_walk_dist = Inf,
                                        max_trip_duration = 120L,
                                        walk_speed = 3.6,
                                        bike_speed = 12,
                                        shortest_path = TRUE,
                                        n_threads = Inf,
                                        verbose = FALSE) {

  results <- detailed_itineraries(
    r5r_obj,
    origins,
    destinations,
    mode,
    departure_datetime,
    max_walk_dist,
    max_trip_duration,
    walk_speed,
    bike_speed,
    shortest_path,
    n_threads,
    verbose
  )

  return(results)

}

test_that("detailed_itineraries adequately raises warnings and errors", {

  # message related to expanding origins/destinations dataframe
  expect_message(detailed_itineraries_tester(r5r_obj, origins = points[1, ]))
  expect_message(detailed_itineraries_tester(r5r_obj, destinations = points[1, ]))

  # error related to using wrong origins/destinations object type
  multipoint_origins      <- sf::st_cast(sf::st_as_sf(points[1:15,], coords = c("lon", "lat")), "MULTIPOINT")
  multipoint_destinations <- sf::st_cast(sf::st_as_sf(points[15:1,], coords = c("lon", "lat")), "MULTIPOINT")
  list_origins      <- list(id = c("1", "2"),   lat = c(-30.02756, -30.02329), long = c(-51.22781, -51.21886))
  list_destinations <- list(id = c("15", "14"), lat = c(-30.05797, -30.03340), long = c(-51.17607, -51.22028))

  expect_error(detailed_itineraries_tester(r5r_obj, origins = multipoint_origins))
  expect_error(detailed_itineraries_tester(r5r_obj, destinations = multipoint_destinations))
  expect_error(detailed_itineraries_tester(r5r_obj, origins = list_origins))
  expect_error(detailed_itineraries_tester(r5r_obj, destinations = list_destinations))
  expect_error(detailed_itineraries_tester(r5r_obj, origins = "origins"))
  expect_error(detailed_itineraries_tester(r5r_obj, destinations = "destinations"))

  # error/warning related to using wrong origins/destinations column types
  origins <- points[1:15, ]
  destinations <- points[15:1, ]

  origins_numeric_id <- data.frame(id = 1:15, lat = origins$lat, lon = origins$lon)
  origins_char_lat   <- data.frame(id = origins$id, lat = as.character(origins$lat), lon = origins$lon)
  origins_char_lon   <- data.frame(id = origins$id, lat = origins$lat, lon = as.character(origins$lon))
  destinations_numeric_id <- data.frame(id = 1:15, lat = destinations$lat, lon = destinations$lon)
  destinations_char_lat   <- data.frame(id = destinations$id, lat = as.character(destinations$lat), lon = destinations$lon)
  destinations_char_lon   <- data.frame(id = destinations$id, lat = destinations$lat, lon = as.character(destinations$lon))

  expect_warning(detailed_itineraries_tester(r5r_obj, origins = origins_numeric_id))
  expect_error(detailed_itineraries_tester(r5r_obj, origins = origins_char_lat))
  expect_error(detailed_itineraries_tester(r5r_obj, origins = origins_char_lon))
  expect_warning(detailed_itineraries_tester(r5r_obj, destinations = destinations_numeric_id))
  expect_error(detailed_itineraries_tester(r5r_obj, destinations = destinations_char_lat))
  expect_error(detailed_itineraries_tester(r5r_obj, destinations = destinations_char_lon))

  # error related to nonexistent mode
  expect_error(detailed_itineraries_tester(r5r_obj, mode = "all"))

  # errors related to date formatting
  numeric_datetime <- as.numeric(as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))

  expect_error(detailed_itineraries_tester(r5r_obj, departure_datetime = "13-03-2019 14:00:00"))
  expect_error(detailed_itineraries_tester(r5r_obj, numeric_datetime))

  # errors related to max_walk_dist
  expect_error(detailed_itineraries_tester(r5r_obj, max_walk_dist = "1"))
  expect_error(detailed_itineraries_tester(r5r_obj, max_walk_dist = NULL))

  # error/warning related to max_street_time
  expect_error(detailed_itineraries_tester(r5r_obj, max_trip_duration = "120"))
  expect_warning(detailed_itineraries_tester(r5r_obj, max_trip_duration = 120))

  # error related to non-numeric walk_speed
  expect_error(detailed_itineraries_tester(r5r_obj, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(detailed_itineraries_tester(r5r_obj, bike_speed = "12"))

  # error related to non-logical shortest_path
  expect_error(detailed_itineraries_tester(r5r_obj, shortest_path = "TRUE"))
  expect_error(detailed_itineraries_tester(r5r_obj, shortest_path = 1))
  expect_error(detailed_itineraries_tester(r5r_obj, shortest_path = NULL))

  # error related to non-numeric n_threads
  expect_error(detailed_itineraries_tester(r5r_obj, n_threads = "1"))
  expect_warning(detailed_itineraries_tester(r5r_obj, n_threads = 1))

  # error related to non-logical verbose
  expect_error(detailed_itineraries_tester(r5r_obj, verbose = "TRUE"))
  expect_error(detailed_itineraries_tester(r5r_obj, verbose = 1))
  expect_error(detailed_itineraries_tester(r5r_obj, verbose = NULL))

})

stop_r5(r5r_obj)
