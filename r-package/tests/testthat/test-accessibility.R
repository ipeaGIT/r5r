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
                   opportunities_colname = "schools",
                   mode = "WALK",
                   mode_egress = "WALK",
                   departure_datetime = Sys.time(),
                   time_window = 1L,
                   percentiles = 50L,
                   decay_function = "step",
                   cutoffs = NULL,
                   decay_value = NULL,
                   fare_structure = NULL,
                   max_fare = Inf,
                   max_walk_time = Inf,
                   max_bike_time = Inf,
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
  accessibility(
    r5r_core = r5r_core,
    origins = origins,
    destinations = destinations,
    opportunities_colname = opportunities_colname,
    mode = mode,
    mode_egress = mode_egress,
    departure_datetime = departure_datetime,
    time_window = time_window,
    percentiles = percentiles,
    decay_function = decay_function,
    cutoffs = cutoffs,
    decay_value = decay_value,
    fare_structure = fare_structure,
    max_fare = max_fare,
    max_walk_time = max_walk_time,
    max_bike_time = max_bike_time,
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


test_that("adequately raises errors", {

  # error related to using object with wrong type as r5r_core
  expect_error(tester("r5r_core"))

  # error related to using wrong origins/destinations object type
  multipoint_origins      <- sf::st_cast(sf::st_as_sf(points[1:2,], coords = c("lon", "lat")), "MULTIPOINT")
  multipoint_destinations <- multipoint_origins
  list_origins      <- list(id = c("1", "2"), lat = c(-30.02756, -30.02329), long = c(-51.22781, -51.21886))
  list_destinations <- list_origins

  expect_error(tester(r5r_core, origins = multipoint_origins))
  expect_error(tester(r5r_core, destinations = multipoint_destinations))
  expect_error(tester(r5r_core, origins = list_origins))
  expect_error(tester(r5r_core, destinations = list_destinations))
  expect_error(tester(r5r_core, origins = "origins"))
  expect_error(tester(r5r_core, destinations = "destinations"))

  # error/warning related to using wrong origins/destinations column types
  origins <- destinations <- points[1:2, ]

  origins_char_lat   <- data.frame(id = origins$id, lat = as.character(origins$lat), lon = origins$lon)
  origins_char_lon   <- data.frame(id = origins$id, lat = origins$lat, lon = as.character(origins$lon))
  destinations_char_lat   <- data.frame(id = destinations$id, lat = as.character(destinations$lat), lon = destinations$lon)
  destinations_char_lon   <- data.frame(id = destinations$id, lat = destinations$lat, lon = as.character(destinations$lon))

  expect_error(tester(r5r_core, origins = origins_char_lat))
  expect_error(tester(r5r_core, origins = origins_char_lon))
  expect_error(tester(r5r_core, destinations = destinations_char_lat))
  expect_error(tester(r5r_core, destinations = destinations_char_lon))

  # error related to nonexistent mode
  expect_error(tester(r5r_core, mode = "pogoball"))

  # errors related to date formatting
  numeric_datetime <- as.numeric(as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"))

  expect_error(tester(r5r_core, departure_datetime = "13-05-2019 14:00:00"))
  expect_error(tester(r5r_core, numeric_datetime))


  # errors related to max_trip_duration
  expect_error(tester(r5r_core, cutoffs = 10, max_trip_duration = 5))
  expect_error(tester(r5r_core, max_trip_duration = "1000"))
  expect_error(tester(r5r_core, max_trip_duration = NULL))

  # errors related to max_walk_time
  expect_error(tester(r5r_core, max_walk_time = "1000"))
  expect_error(tester(r5r_core, max_walk_time = NULL))

  # errors related to max_bike_time
  expect_error(tester(r5r_core, max_bike_time = "1000"))
  expect_error(tester(r5r_core, max_bike_time = NULL))

    # error/warning related to max_street_time
  expect_error(tester(r5r_core, max_trip_duration = "120"))

  # error related to non-numeric walk_speed
  expect_error(tester(r5r_core, walk_speed = "3.6"))

  # error related to non-numeric bike_speed
  expect_error(tester(r5r_core, bike_speed = "12"))

  # error related to too many or invalid percentiles
  expect_error(tester(r5r_core, percentiles = .3))
  expect_error(tester(r5r_core, percentiles = 1:6))

  # decay_function
  expect_error(tester(r5r_core, decay_function = "fixed_exponential"))
  expect_error(tester(r5r_core, decay_function = "bananas"))
  expect_error(tester(r5r_core, opportunities_colname = "bananas"))
  expect_error(tester(r5r_core, cutoffs = "bananas"))
  expect_error(tester(r5r_core, decay_value = "bananas"))

})

# test_that("adequately raises warnings - needs java", {
#
#   # error/warning related to using wrong origins/destinations column types
#   origins <- destinations <- points[1:2, ]
#
#   origins_numeric_id <- data.frame(id = 1:2, lat = origins$lat, lon = origins$lon)
#   destinations_numeric_id <- data.frame(id = 1:2, lat = destinations$lat, lon = destinations$lon)
#
#   expect_warning(tester(r5r_core, origins = origins_numeric_id))
#   expect_error(tester(r5r_core, destinations = destinations_numeric_id))
#
#
# })


# adequate behavior ------------------------------------------------------


test_that("output is correct", {

  # decay functions
  expect_s3_class(tester(decay_function = "step", cutoffs = 30), "data.table")
  expect_s3_class(
    tester(decay_function = "exponential", cutoffs = 30),
    "data.table"
  )
  expect_s3_class(
    tester(decay_function = "linear", cutoffs = 30, decay_value = 1),
    "data.table"
  )
  expect_s3_class(
    tester(decay_function = "logistic", cutoffs = 30, decay_value = 1),
    "data.table"
  )
  expect_s3_class(
    tester(decay_function = "fixed_exponential", decay_value = 0.5),
    "data.table"
  )

  #  * output class ---------------------------------------------------------


  # expect results to be of class 'data.table', independently of the class of
  # 'origins'/'destinations'

  origins_sf <- destinations_sf <- sf::st_as_sf(
    points[1:10, ],
    coords = c("lon", "lat"),
    crs = 4326
  )

  result_df_input <- tester(cutoffs = 30)
  result_sf_input <- tester(
    origins = origins_sf,
    destinations = destinations_sf,
    cutoffs = 30
  )

  expect_s3_class(result_df_input, "data.table")
  expect_s3_class(result_sf_input, "data.table")

  # expect each column to be of right class

  expect_true(typeof(result_df_input$id) == "character")
  expect_true(typeof(result_df_input$accessibility) == "double")


  #  * r5r options ----------------------------------------------------------


  # access to multiple opportunities
  one_opport <- tester(cutoffs = 30)
  two_opport <- tester(
    opportunities_colname = c("schools", "healthcare"),
    cutoffs = 30
  )
  expect_true( nrow(two_opport) > nrow(one_opport))
  expect_true(is(two_opport, "data.table"))
})
