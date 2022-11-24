# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(speed, mode) set_speed(r5r_core, speed, mode)

test_that("input is correct", {
  expect_error(tester(10, 1))
  expect_error(tester(10, c("bike", "bike")))
  expect_error(tester(10, "oie"))

  expect_error(tester("a", "walk"))
  expect_error(tester(c(1, 1), "walk"))
  expect_error(tester(0, "walk"))
  expect_error(tester(Inf, "walk"))
})

test_that("set_speed argument works in travel_time_matrix()", {
  walk_expr <- call("travel_time_matrix", r5r_core, pois, pois, mode = "WALK")

  slow_walk_expr <- fast_walk_expr <- walk_expr
  slow_walk_expr$walk_speed <- 2
  fast_walk_expr$walk_speed <- 4

  slow_walk <- eval(slow_walk_expr)
  fast_walk <- eval(fast_walk_expr)

  expect_true(nrow(fast_walk) > nrow(slow_walk))
  slow_walk[
    fast_walk,
    on = c("from_id", "to_id"),
    travel_time_fast := i.travel_time_p50
  ]
  expect_true(all(slow_walk$travel_time_p50 >= slow_walk$travel_time_fast))
  expect_true(any(slow_walk$travel_time_p50 > slow_walk$travel_time_fast))

  bike_expr <- walk_expr
  bike_expr$mode <- "BICYCLE"
  slow_bike_expr <- fast_bike_expr <- bike_expr
  slow_bike_expr$bike_speed <- 5
  fast_bike_expr$bike_speed <- 10

  slow_bike <- eval(slow_bike_expr)
  fast_bike <- eval(fast_bike_expr)

  expect_true(nrow(fast_bike) > nrow(slow_bike))
  slow_bike[
    fast_bike,
    on = c("from_id", "to_id"),
    travel_time_fast := i.travel_time_p50
  ]
  expect_true(all(slow_bike$travel_time_p50 >= slow_bike$travel_time_fast))
  expect_true(any(slow_bike$travel_time_p50 > slow_bike$travel_time_fast))
})

test_that("set_speed argument works in expanded_travel_time_matrix()", {
  walk_expr <- call(
    "expanded_travel_time_matrix",
    r5r_core,
    pois,
    pois,
    mode = "WALK"
  )

  slow_walk_expr <- fast_walk_expr <- walk_expr
  slow_walk_expr$walk_speed <- 2
  fast_walk_expr$walk_speed <- 4

  slow_walk <- eval(slow_walk_expr)
  fast_walk <- eval(fast_walk_expr)

  expect_true(nrow(fast_walk) > nrow(slow_walk))
  slow_walk[
    fast_walk,
    on = c("from_id", "to_id"),
    total_time_fast := i.total_time
  ]
  expect_true(all(slow_walk$total_time >= slow_walk$total_time_fast))
  expect_true(any(slow_walk$total_time > slow_walk$total_time_fast))

  bike_expr <- walk_expr
  bike_expr$mode <- "BICYCLE"
  slow_bike_expr <- fast_bike_expr <- bike_expr
  slow_bike_expr$bike_speed <- 5
  fast_bike_expr$bike_speed <- 10

  slow_bike <- eval(slow_bike_expr)
  fast_bike <- eval(fast_bike_expr)

  expect_true(nrow(fast_bike) > nrow(slow_bike))
  slow_bike[
    fast_bike,
    on = c("from_id", "to_id"),
    total_time_fast := i.total_time
  ]
  expect_true(all(slow_bike$total_time >= slow_bike$total_time_fast))
  expect_true(any(slow_bike$total_time > slow_bike$total_time_fast))
})

test_that("set_speed argument works in accessibility()", {
  walk_expr <- call(
    "accessibility",
    r5r_core,
    points[1:15],
    points[1:15],
    mode = "WALK",
    opportunities_colnames = "population",
    decay_function = "step",
    cutoffs = 30
  )

  slow_walk_expr <- fast_walk_expr <- walk_expr
  slow_walk_expr$walk_speed <- 2
  fast_walk_expr$walk_speed <- 5

  slow_walk <- eval(slow_walk_expr)
  fast_walk <- eval(fast_walk_expr)

  slow_walk[fast_walk, on = "id", accessibility_fast := i.accessibility]
  expect_true(all(slow_walk$accessibility <= slow_walk$accessibility_fast))
  expect_true(any(slow_walk$accessibility < slow_walk$accessibility_fast))

  bike_expr <- walk_expr
  bike_expr$mode <- "BICYCLE"
  slow_bike_expr <- fast_bike_expr <- bike_expr
  slow_bike_expr$bike_speed <- 5
  fast_bike_expr$bike_speed <- 10

  slow_bike <- eval(slow_bike_expr)
  fast_bike <- eval(fast_bike_expr)

  slow_bike[fast_bike, on = "id", accessibility_fast := i.accessibility]
  expect_true(all(slow_bike$accessibility <= slow_bike$accessibility_fast))
  expect_true(any(slow_bike$accessibility < slow_bike$accessibility_fast))
})

test_that("set_speed argument works in pareto_frontier()", {
  walk_expr <- call(
    "pareto_frontier",
    r5r_core,
    points[1:5],
    points[1:5],
    mode = "WALK",
    fare_structure = fare_structure,
    fare_cutoffs = 0
  )

  slow_walk_expr <- fast_walk_expr <- walk_expr
  slow_walk_expr$walk_speed <- 2
  fast_walk_expr$walk_speed <- 4

  slow_walk <- eval(slow_walk_expr)
  fast_walk <- eval(fast_walk_expr)

  expect_true(nrow(fast_walk) > nrow(slow_walk))
  slow_walk[
    fast_walk,
    on = c("from_id", "to_id"),
    travel_time_fast := i.travel_time
  ]
  expect_true(all(slow_walk$travel_time >= slow_walk$travel_time_fast))
  expect_true(any(slow_walk$travel_time > slow_walk$travel_time_fast))

  bike_expr <- walk_expr
  bike_expr$mode <- "BICYCLE"
  slow_bike_expr <- fast_bike_expr <- bike_expr
  slow_bike_expr$bike_speed <- 5
  fast_bike_expr$bike_speed <- 10

  slow_bike <- eval(slow_bike_expr)
  fast_bike <- eval(fast_bike_expr)

  expect_true(nrow(fast_bike) > nrow(slow_bike))
  slow_bike[
    fast_bike,
    on = c("from_id", "to_id"),
    travel_time_fast := i.travel_time
  ]
  expect_true(all(slow_bike$travel_time >= slow_bike$travel_time_fast))
  expect_true(any(slow_bike$travel_time > slow_bike$travel_time_fast))
})

# FIXME: currently, the speeds calculated from detailed_itineraries() distance
# and duration fields don't result in the same speed specified in the function
# call. some investigation of why is on issue #276
test_that("set_speed argument works in detailed_itineraries()", {
  walk_expr <- call(
    "detailed_itineraries",
    r5r_core,
    pois,
    pois[15:1],
    mode = "WALK",
    drop_geometry = TRUE
  )

  slow_walk_expr <- fast_walk_expr <- walk_expr
  slow_walk_expr$walk_speed <- 2
  fast_walk_expr$walk_speed <- 4.68

  slow_walk <- eval(slow_walk_expr)
  fast_walk <- eval(fast_walk_expr)

  slow_walk[
    fast_walk,
    on = c("from_id", "to_id"),
    segment_duration_fast := i.segment_duration
  ]
  expect_true(
    all(slow_walk$segment_duration >= slow_walk$segment_duration_fast)
  )
  expect_true(any(slow_walk$segment_duration > slow_walk$segment_duration_fast))

  bike_expr <- walk_expr
  bike_expr$mode <- "BICYCLE"
  bike_expr$max_lts < 4
  slow_bike_expr <- fast_bike_expr <- bike_expr
  slow_bike_expr$bike_speed <- 5
  fast_bike_expr$bike_speed <- 10

  slow_bike <- eval(slow_bike_expr)
  fast_bike <- eval(fast_bike_expr)

  slow_bike[
    fast_bike,
    on = c("from_id", "to_id"),
    segment_duration_fast := i.segment_duration
  ]
  expect_true(
    all(slow_bike$segment_duration >= slow_bike$segment_duration_fast)
  )
  expect_true(any(slow_bike$segment_duration > slow_bike$segment_duration_fast))
})
