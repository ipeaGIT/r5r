# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(time_window) set_time_window(r5r_core, time_window)

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(0))
  expect_error(tester(c(1, 1)))
  expect_error(tester(Inf))
})

test_that("set_time_window argument works in expanded_travel_time_matrix()", {
  basic_expr <- call(
    "expanded_travel_time_matrix",
    r5r_core,
    pois,
    pois,
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    draws_per_minute = 1,
    max_trip_duration = 60
  )

  small_window_expr <- big_window_expr <- basic_expr
  small_window_expr$time_window <- 1
  big_window_expr$time_window <- 60

  small_window <- eval(small_window_expr)
  expect_true(
    all(small_window$departure_time == format(departure_datetime, "%H:%M:%S"))
  )

  big_window <- eval(big_window_expr)
  departure_range <- departure_datetime + c(0:59) * 60
  departure_range_char <- format(departure_range, "%H:%M:%S")
  time_window_summary <- big_window[
    ,
    .(contains_all_times = identical(departure_time, departure_range_char)),
    by = .(from_id, to_id)
  ]

  # should include all departure times even if in some of them no trip can be
  # completed within the specified constraints

  incomplete_trips <- big_window[
    from_id == "gasometer_museum" & to_id == "iguatemi_shopping_center"
  ]
  expect_true(any(is.na(incomplete_trips$routes)))
  expect_identical(incomplete_trips$departure_time, departure_range_char)
})

# travel_time_matrix(), accessibility() and pareto_frontier(): we're gonna
# assume the argument is working if calculating the times with time_window = 1
# and draws_per_minute = 1 results in all percentiles with the same value, but
# larger time windows doesn't

percentiles <- c(25, 50, 75)

test_that("set_time_window argument works in travel_time_matrix()", {
  basic_expr <- call(
    "travel_time_matrix",
    r5r_core,
    pois,
    pois,
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    draws_per_minute = 1,
    percentiles = percentiles
  )

  small_window_expr <- big_window_expr <- basic_expr
  small_window_expr$time_window <- 1
  big_window_expr$time_window <- 60

  small_window <- eval(small_window_expr)
  expect_identical(small_window$travel_time_p25, small_window$travel_time_p50)
  expect_identical(small_window$travel_time_p50, small_window$travel_time_p75)

  big_window <- eval(big_window_expr)
  expect_false(
    identical(big_window$travel_time_p25, big_window$travel_time_p50)
  )
  expect_false(
    identical(big_window$travel_time_p50, big_window$travel_time_p75)
  )
})

test_that("set_time_window argument works in accessibility()", {
  basic_expr <- call(
    "accessibility",
    r5r_core,
    points[1:30],
    points[1:30],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    draws_per_minute = 1,
    percentiles = percentiles,
    opportunities_colnames = "population",
    decay_function = "step",
    cutoffs = 30,
    max_trip_duration = 60
  )

  small_window_expr <- big_window_expr <- basic_expr
  small_window_expr$time_window <- 1
  big_window_expr$time_window <- 60

  small_window <- eval(small_window_expr)
  small_window <- data.table::dcast(
    small_window,
    id ~ percentile,
    value.var = "accessibility"
  )
  data.table::setnames(
    small_window,
    old = as.character(percentiles),
    new = paste0("access_", percentiles)
  )
  expect_identical(small_window$access_25, small_window$access_50)
  expect_identical(small_window$access_50, small_window$access_75)

  big_window <- eval(big_window_expr)
  big_window <- data.table::dcast(
    big_window,
    id ~ percentile,
    value.var = "accessibility"
  )
  data.table::setnames(
    big_window,
    old = as.character(percentiles),
    new = paste0("access_", percentiles)
  )
  expect_false(identical(big_window$access_25, big_window$access_50))
  expect_false(identical(big_window$access_50, big_window$access_75))
})

test_that("set_time_window argument works in pareto_frontier()", {
  basic_expr <- call(
    "pareto_frontier",
    r5r_core,
    points[1:5],
    points[1:5],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    percentiles = percentiles,
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60
  )

  small_window_expr <- big_window_expr <- basic_expr
  small_window_expr$time_window <- 1
  big_window_expr$time_window <- 60

  small_window <- eval(small_window_expr)
  small_window <- small_window[
    ,
    .(data = list(.SD)),
    by = .(from_id, to_id, percentile)
  ]
  small_window <- data.table::dcast(
    small_window,
    from_id + to_id ~ percentile,
    value.var = "data"
  )
  data.table::setnames(
    small_window,
    old = as.character(percentiles),
    new = paste0("frontier_", percentiles)
  )
  expect_identical(small_window$frontier_25, small_window$frontier_50)
  expect_identical(small_window$frontier_50, small_window$frontier_75)

  big_window <- eval(big_window_expr)
  big_window <- big_window[
    ,
    .(data = list(.SD)),
    by = .(from_id, to_id, percentile)
  ]
  big_window <- data.table::dcast(
    big_window,
    from_id + to_id ~ percentile,
    value.var = "data"
  )
  data.table::setnames(
    big_window,
    old = as.character(percentiles),
    new = paste0("frontier_", percentiles)
  )
  expect_false(identical(big_window$frontier_25, big_window$frontier_50))
  expect_false(identical(big_window$frontier_50, big_window$frontier_75))
})

# detailed_itineraries(): no draws_per_minute and percentiles arguments, so we
# can only check if using a larger time window brings more  information

test_that("set_time_window argument works in detailed_itineraries()", {
  basic_expr <- call(
    "detailed_itineraries",
    r5r_core,
    points[1:5],
    points[5:1],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    drop_geometry = TRUE,
    shortest_path = FALSE
  )

  small_window_expr <- big_window_expr <- basic_expr
  small_window_expr$time_window <- 1
  big_window_expr$time_window <- 30

  small_window <- eval(small_window_expr)
  small_window <- small_window[
    ,
    .(n_itin = max(option)),
    by = .(from_id, to_id)
  ]
  big_window <- eval(big_window_expr)
  big_window <- big_window[, .(n_itin = max(option)), by = .(from_id, to_id)]

  expect_true(all(big_window$n_itin > small_window$n_itin))
})
