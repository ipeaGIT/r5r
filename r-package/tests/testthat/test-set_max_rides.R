# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(max_rides) set_max_rides(r5r_core, max_rides)

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(0))
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

  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 2\\)", expr)

  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  expect_true(nrow(many_rides) >= nrow(one_ride))
  one_ride[
    many_rides,
    on = c("from_id", "to_id"),
    travel_time_many_rides := i.travel_time_p50
  ]
  expect_true(
    all(one_ride$travel_time_p50 >= one_ride$travel_time_many_rides)
  )
  expect_true(
    any(one_ride$travel_time_p50 > one_ride$travel_time_many_rides)
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

  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 2\\)", expr)

  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  one_ride[many_rides, on = "id", accessibility_many_rides := i.accessibility]
  expect_true(all(one_ride$accessibility <= one_ride$accessibility_many_rides))
  expect_true(any(one_ride$accessibility < one_ride$accessibility_many_rides))
})

test_that("max_rides argument works in expanded_travel_time_matrix()", {
  expr <- "expanded_travel_time_matrix(
    r5r_core,
    pois[1:5],
    pois[1:5],
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = departure_datetime,
    draws_per_minute = 1
  )"

  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 2\\)", expr)

  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  count_transit <- function(strings) {
    split_vector <- strsplit(strings, "\\|")
    walkless_vector <- lapply(
      split_vector,
      function(s) {
        if (identical(s, "[WALK]")) {
          character(0)
        } else {
          s
        }
      }
    )
    count <- vapply(walkless_vector, length, integer(1))
  }

  one_ride[, transit_count := count_transit(routes)]
  expect_true(all(one_ride$transit_count <= 1))
  expect_true(any(one_ride$transit_count > 0))

  many_rides[, transit_count := count_transit(routes)]
  expect_true(all(many_rides$transit_count <= 2))
  expect_true(any(many_rides$transit_count > 0))
  expect_true(any(many_rides$transit_count > 1))
})

test_that("max_rides argument works in pareto_frontier()", {
  expr <- "pareto_frontier(
    r5r_core,
    pois[1:5],
    pois[1:5],
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = departure_datetime,
    fare_structure = fare_structure,
    fare_cutoffs  = c(0, 5, 10)
  )"

  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 2\\)", expr)

  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  expect_true(all(one_ride$monetary_cost <= 5))
  expect_true(any(one_ride$monetary_cost > 0))

  expect_true(all(many_rides$monetary_cost <= 10))
  expect_true(any(many_rides$monetary_cost > 0))
  expect_true(any(many_rides$monetary_cost > 5))
})

test_that("max_rides argument works in detailed_itineraries()", {
  expr <- "detailed_itineraries(
    r5r_core,
    pois,
    pois[15:1],
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = departure_datetime,
    drop_geometry = TRUE,
    shortest_path = FALSE
  )"

  one_ride_expr <- sub("\\)$", ", max_rides = 1\\)", expr)
  many_rides_expr <- sub("\\)$", ", max_rides = 2\\)", expr)

  one_ride <- eval(parse(text = one_ride_expr))
  many_rides <- eval(parse(text = many_rides_expr))

  count_transit <- function(routes) {
    non_walk_legs <- routes != ""
    sum(non_walk_legs)
  }

  one_ride <- one_ride[
    ,
    .(transit_legs = count_transit(route)),
    by = .(from_id, to_id, option)
  ]
  expect_true(all(one_ride$transit_legs <= 1))
  expect_true(any(one_ride$transit_legs > 0))

  many_rides <- many_rides[
    ,
    .(transit_legs = count_transit(route)),
    by = .(from_id, to_id, option)
  ]
  expect_true(all(many_rides$transit_legs <= 2))
  expect_true(any(many_rides$transit_legs > 0))
  expect_true(any(many_rides$transit_legs > 1))
})
