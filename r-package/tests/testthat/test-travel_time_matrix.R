# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

tester <- function(r5r_network = get("r5r_network", envir = parent.frame()),
                   origins = pois,
                   destinations = pois,
                   mode = "WALK",
                   mode_egress = "WALK",
                   departure_datetime = Sys.time(),
                   time_window = 1L,
                   percentiles = 50L,
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
  travel_time_matrix(
    r5r_network,
    origins = origins,
    destinations = destinations,
    mode = mode,
    mode_egress = mode_egress,
    departure_datetime = departure_datetime,
    time_window = time_window,
    percentiles = percentiles,
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

# tests -------------------------------------------------------------------

test_that("errors due to incorrect input types - origins and destinations", {
  multipoint_origins <- sf::st_cast(
    sf::st_as_sf(pois, coords = c("lon", "lat")),
    "MULTIPOINT"
  )
  multipoint_destinations <- multipoint_origins

  list_destinations <- list_origins <- unclass(pois)

  expect_error(tester(origins = multipoint_origins))
  expect_error(tester(destinations = multipoint_destinations))
  expect_error(tester(origins = list_origins))
  expect_error(tester(destinations = list_destinations))
  expect_error(tester(origins = "origins"))
  expect_error(tester(destinations = "destinations"))

  # wrong columns types

  pois_char_lat <- pois
  pois_char_lat$lat <- as.character(pois$lat)
  pois_char_lon <- pois
  pois_char_lon$lon <- as.character(pois$lon)

  expect_error(tester(origins = pois_char_lat))
  expect_error(tester(origins = pois_char_lon))
  expect_error(tester(destinations = pois_char_lat))
  expect_error(tester(destinations = pois_char_lon))
})

test_that("errors due to incorrect input types - other inputs", {
  # mode and mode_egress are tested in assign_mode() tests

  expect_error(tester(unclass(r5r_network)))

  expect_error(tester(departure_datetime = unclass(departure_datetime)))
  expect_error(tester(departure_datetime = rep(departure_datetime, 2)))

  expect_error(tester(percentiles = "50"))
  expect_error(tester(percentiles = 0))
  expect_error(tester(percentiles = 100))
  expect_error(tester(percentiles = c(50, 50)))
  expect_error(tester(percentiles = 1:6))
  expect_error(tester(percentiles = NA))

  # TODO: test fare_structure

  expect_error(tester(max_fare = "0"))
  expect_error(tester(max_fare = -1))
  expect_error(tester(max_fare = c(0, 20)))
  expect_error(tester(max_fare = NA))

  expect_error(tester(max_walk_time = "1000"))
  expect_error(tester(max_walk_time = NULL))
  expect_error(tester(max_walk_time = c(1000, 2000)))
  expect_error(tester(max_walk_time = 0))

  expect_error(tester(max_bike_time = "1000"))
  expect_error(tester(max_bike_time = NULL))
  expect_error(tester(max_bike_time = c(1000, 2000)))
  expect_error(tester(max_bike_time = 0))

  expect_error(tester(max_trip_duration = "120"))
  expect_error(tester(max_trip_duration = c(25, 30)))
  expect_error(tester(max_trip_duration = Inf))

  expect_error(tester(walk_speed = "3.6"))
  expect_error(tester(walk_speed = c(3.6, 5)))
  expect_error(tester(walk_speed = 0))

  expect_error(tester(bike_speed = "12"))
  expect_error(tester(bike_speed = c(12, 15)))
  expect_error(tester(bike_speed = 0))

  expect_error(tester(draws_per_minute = "1"))
  expect_error(tester(draws_per_minute = c(12, 15)))
  expect_error(tester(draws_per_minute = 0))
  expect_error(tester(draws_per_minute = Inf))

  expect_error(tester(output_dir = 1))
  expect_error(tester(output_dir = "non_existent_dir"))
})

test_that("raises errors when non-character ids are used in origs/dests", {
  origins <- destinations <- pois[1:2, ]

  origins_numeric_id <- origins
  origins_numeric_id$id <- 1:2
  destinations_numeric_id <- destinations
  destinations_numeric_id$id <- 1:2

  expect_warning(tester(origins = origins_numeric_id))
  expect_warning(tester(destinations = destinations_numeric_id))
})

test_that("output is a data.table with correct columns", {
  ttm <- tester()
  expect_s3_class(ttm, "data.table")
  expect_identical(names(ttm), c("from_id", "to_id", "travel_time_p50"))
  expect_type(ttm$from_id, "character")
  expect_type(ttm$to_id, "character")
  expect_type(ttm$travel_time_p50, "integer")

  # more percentiles means more columns

  ttm <- tester(percentiles = c(25, 50, 75))
  expect_identical(
    names(ttm),
    c("from_id", "to_id", paste0("travel_time_p", c(25, 50, 75)))
  )
  expect_type(ttm$from_id, "character")
  expect_type(ttm$to_id, "character")
  expect_type(ttm$travel_time_p25, "integer")
  expect_type(ttm$travel_time_p50, "integer")
  expect_type(ttm$travel_time_p75, "integer")
})

test_that("output is identical independent of origs/dests type", {
  origins_sf <- destinations_sf <- sf::st_as_sf(
    pois,
    coords = c("lon", "lat"),
    crs = 4326
  )

  ttm_df <- tester()
  ttm_sf <- tester(origins = origins_sf, destinations = destinations_sf)
  expect_identical(ttm_df, ttm_sf)
})


test_that("we get more results (and faster trips) when using faster modes", {
  ttm_walk_only <- tester(
    mode = "WALK",
    departure_datetime = departure_datetime
  )
  data.table::setnames(ttm_walk_only, "travel_time_p50", new = "only_walk_time")
  ttm_with_transit <- tester(
    mode = c("WALK", "TRANSIT"),
    departure_datetime = departure_datetime
  )

  expect_true(nrow(ttm_with_transit) > nrow(ttm_walk_only))

  ttm <- ttm_walk_only[
    ttm_with_transit,
    on = c("from_id", "to_id"),
    with_transit_time := i.travel_time_p50
  ]
  expect_true(all(ttm$only_walk_time >= ttm$with_transit_time))
})


test_that("higher percentiles travel times are slower", {
  ttm <- tester(
    mode = c("WALK", "TRANSIT"),
    departure_datetime = departure_datetime,
    percentiles = c(1, 50, 99),
    time_window = 20
  )
  expect_true(all(ttm$travel_time_p01 <= ttm$travel_time_p50))
  expect_true(all(ttm$travel_time_p50 <= ttm$travel_time_p99))
})

test_that("walk trips are shorter with higher walk speeds", {
  ttm_low_speed <- tester(mode = "WALK", walk_speed = 3.6)
  data.table::setnames(ttm_low_speed, "travel_time_p50", new = "low_speed_time")
  ttm_high_speed <- tester(mode = "WALK", walk_speed = 6)
  ttm <- ttm_low_speed[
    ttm_high_speed,
    on = c("from_id", "to_id"),
    high_speed_time := i.travel_time_p50
  ]
  expect_true(all(ttm$low_speed_time >= ttm$high_speed_time))
})



test_that("bike trips are shorter with higher bike speeds", {
  ttm_low_speed <- tester(mode = "BICYCLE", bike_speed = 12)
  data.table::setnames(ttm_low_speed, "travel_time_p50", new = "low_speed_time")
  ttm_high_speed <- tester(mode = "BICYCLE", bike_speed = 20)
  ttm <- ttm_low_speed[
    ttm_high_speed,
    on = c("from_id", "to_id"),
    high_speed_time := i.travel_time_p50
  ]
  expect_true(all(ttm$low_speed_time >= ttm$high_speed_time))
})

test_that("all travel times are lower than max_trip_duration", {
  max_trip_duration <- 60L
  ttm <- tester(max_trip_duration = max_trip_duration, percentiles = 99)
  expect_true(all(ttm$travel_time_p99 <= max_trip_duration))
})

test_that("all od pairs are unique", {
  ttm <- tester()
  ttm <- ttm[, .N, keyby = .(from_id, to_id)]
  expect_equal(unique(ttm$N), 1)
})

test_that("output is saved to dir and function returns path with output_dir", {
  tmpdir <- tempfile("ttm_output")
  dir.create(tmpdir)

  ttm_output_dir <- tester(output_dir = tmpdir)
  expect_equal(normalizePath(ttm_output_dir), normalizePath(tmpdir))

  ttm_from_files <- lapply(
    list.files(ttm_output_dir, full.names = TRUE),
    data.table::fread
  )
  ttm_from_files <- data.table::rbindlist(ttm_from_files)
  ttm_from_files <- ttm_from_files[order(from_id, to_id)]

  ttm_normal <- tester()
  ttm_normal <- ttm_normal[order(from_id, to_id)]

  expect_identical(ttm_normal, ttm_from_files)
})

test_that("returns ttm even if last call saved to dir", {
  tmpdir <- tempfile("ttm_output")
  dir.create(tmpdir)
  ttm_output_dir <- tester(output_dir = tmpdir)
  ttm_normal <- tester()
  expect_s3_class(ttm_normal, "data.table")
})


test_that("using transit outside the gtfs dates throws an error", {
  expect_error(
    tester(r5r_network,
           mode='transit',
           departure_datetime = as.POSIXct("13-05-2025 14:00:00",
                                           format = "%d-%m-%Y %H:%M:%S")
    )
  )
})
