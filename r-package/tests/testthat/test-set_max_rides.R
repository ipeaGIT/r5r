# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)
fare_structure <- read_fare_structure(
  system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
)

tester <- function(max_rides) set_max_rides(r5r_core, max_rides)

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(c(1, 1)))
  expect_error(tester(Inf))
})

test_that("max_rides argument works in travel_time_matrix()", {
  expr <- "travel_time_matrix(
    r5r_core,
    pois,
    pois,
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = departure_datetime
  )"

  walk_expr <- sub(", \\'TRANSIT\\'", "", expr)
  no_rides_expr <- sub("\\)$", ", max_rides = 0\\)", expr)
  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 3\\)", expr)

  walk <- eval(parse(text = walk_expr))
  no_rides <- eval(parse(text = no_rides_expr))
  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  # no rides is equivalent to walk only

  expect_identical(walk, no_rides)

  # using one transit leg improves results

  expect_true(nrow(one_ride) >= nrow(no_rides))
  no_rides[
    one_ride,
    on = c("from_id", "to_id"),
    travel_time_one_ride := i.travel_time_p50
  ]
  expect_true(
    all(no_rides$travel_time_p50 >= no_rides$travel_time_one_ride)
  )

  # using many transit legs further improves results

  expect_true(nrow(many_rides) >= nrow(one_ride))
  one_ride[
    many_rides,
    on = c("from_id", "to_id"),
    travel_time_many_rides := i.travel_time_p50
  ]
  expect_true(
    all(one_ride$travel_time_p50 >= one_ride$travel_time_many_rides)
  )
})

test_that("max_rides argument works in accessibility()", {
  expr <- "accessibility(
    r5r_core,
    points[1:15],
    points[1:15],
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = departure_datetime,
    opportunities_colnames = 'population',
    cutoffs = 60
  )"

  walk_expr <- sub(", \\'TRANSIT\\'", "", expr)
  no_rides_expr <- sub("\\)$", ", max_rides = 0\\)", expr)
  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 3\\)", expr)

  walk <- eval(parse(text = walk_expr))
  no_rides <- eval(parse(text = no_rides_expr))
  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  # no rides is equivalent to walk only

  expect_identical(walk, no_rides)

  # using one transit leg improves results

  no_rides[one_ride, on = "id", accessibility_one_ride := i.accessibility]
  expect_true(all(no_rides$accessibility <= no_rides$accessibility_one_ride))

  # using many transit legs further improves results

  one_ride[many_rides, on = "id", accessibility_many_rides := i.accessibility]
  expect_true(all(one_ride$accessibility <= one_ride$accessibility_many_rides))
})
