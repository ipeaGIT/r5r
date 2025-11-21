# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

tester <- function(r5r_network = get("r5r_network", envir = parent.frame()),
                   origins = pois[2,],
                   cutoffs = c(0, 30),
                   mode = "WALK",
                   mode_egress = "WALK",
                   departure_datetime = Sys.time(),
                   polygon_output = TRUE,
                   max_walk_time = Inf,
                   max_bike_time = Inf,
                   max_trip_duration = 120L,
                   walk_speed = 3.6,
                   bike_speed = 12,
                   max_rides = 3,
                   max_lts = 2,
                   n_threads = Inf,
                   verbose = FALSE,
                   progress = FALSE
                   ) {
  isochrone(
    r5r_network,
    origins = origins,
    cutoffs = cutoffs,
    mode = mode,
    mode_egress = mode_egress,
    departure_datetime = departure_datetime,
    polygon_output = polygon_output,
    max_walk_time = max_walk_time,
    max_bike_time = max_bike_time,
    max_trip_duration = max_trip_duration,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = max_rides,
    max_lts = max_lts,
    n_threads = n_threads,
    verbose = verbose,
    progress = progress
    )
}

# tests -------------------------------------------------------------------

test_that("errors due to incorrect input types - origins and destinations", {
  multipoint_origins <- sf::st_cast(
    sf::st_as_sf(pois, coords = c("lon", "lat")),
    "MULTIPOINT"
  )
  list_destinations <- list_origins <- unclass(pois)

  expect_error(tester(origins = multipoint_origins))
  expect_error(tester(origins = list_origins))
  expect_error(tester(origins = "origins"))

  # wrong columns types

  pois_char_lat <- pois
  pois_char_lat$lat <- as.character(pois$lat)
  pois_char_lon <- pois
  pois_char_lon$lon <- as.character(pois$lon)

  expect_error(tester(origins = pois_char_lat))
  expect_error(tester(origins = pois_char_lon))
})

test_that("errors due to incorrect input types - other inputs", {
  # mode and mode_egress are tested in assign_mode() tests

  expect_error(tester(unclass(r5r_network)))

  expect_error(tester(departure_datetime = unclass(departure_datetime)))
  expect_error(tester(departure_datetime = rep(departure_datetime, 2)))

  expect_error(tester(cutoffs = "50"))
  expect_error(tester(cutoffs = -5))
  expect_error(tester(polygon_output = 'banana'))
  expect_error(tester(zoom=8))
  expect_error(tester(zoom=13))
  expect_error(tester(zoom="banana"))
})


# test polygon-based output
test_that("output is an sf with correct columns", {
  iso <- tester()
  expect_s3_class(iso, "sf")
  expect_identical(names(iso), c("id", "isochrone", "percentile", "polygons"))
  expect_type(iso$id, "character")
  expect_type(iso$isochrone, "double")
  expect_type(iso$polygons, "list")
  print(class(iso$polygons[1]))
  expect_true("sfc_POLYGON" %in% class(iso$polygons[1]))

  # more cutoffs means more rows

  iso2 <- tester(cutoffs = c(30, 50))
  expect_true(
    nrow(iso2) > nrow(iso)
  )
})


# test line-based output
test_that("output is an sf with correct columns", {
  iso <- tester(polygon_output = FALSE)
  expect_s3_class(iso, "sf")

  expect_type(iso$edge_index, "character")
  expect_type(iso$isochrone, "double")
  expect_true("sfc_LINESTRING" %in% class(iso$geometry[1]))
})
