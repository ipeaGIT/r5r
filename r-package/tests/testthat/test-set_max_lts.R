# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(max_lts) set_max_lts(r5r_core, max_lts)

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(c(1, 1)))
  expect_error(tester(0))
  expect_error(tester(5))
})

test_that("max_lts argument works in travel_time_matrix()", {
  expr <- "travel_time_matrix(
    r5r_core,
    pois[1:5],
    pois[1:5],
    mode = \"BICYCLE\"
  )"

  fast_expr <- sub("\\)$", ", max_lts = 4\\)", expr)
  slow_expr <- sub("\\)$", ", max_lts = 1\\)", expr)

  fast_res <- eval(parse(text = fast_expr))
  slow_res <- eval(parse(text = slow_expr))

  expect_true(all(slow_res$travel_time_p50 >= fast_res$travel_time_p50))
})

test_that("max_lts argument works in expanded_travel_time_matrix()", {
  expr <- "expanded_travel_time_matrix(
    r5r_core,
    pois[1:5],
    pois[1:5],
    mode = \"BICYCLE\"
  )"

  fast_expr <- sub("\\)$", ", max_lts = 4\\)", expr)
  slow_expr <- sub("\\)$", ", max_lts = 1\\)", expr)

  fast_res <- eval(parse(text = fast_expr))
  slow_res <- eval(parse(text = slow_expr))

  expect_true(all(slow_res$total_time >= fast_res$total_time))
})

test_that("max_lts argument works in pareto_frontier()", {
  expr <- "pareto_frontier(
    r5r_core,
    pois[1:5],
    pois[1:5],
    mode = \"BICYCLE\",
    departure_datetime = departure_datetime,
    fare_structure = fare_structure,
    fare_cutoffs = 0
  )"

  fast_expr <- sub("\\)$", ", max_lts = 4\\)", expr)
  slow_expr <- sub("\\)$", ", max_lts = 1\\)", expr)

  fast_res <- eval(parse(text = fast_expr))
  slow_res <- eval(parse(text = slow_expr))

  expect_true(all(slow_res$travel_time >= fast_res$travel_time))
})

test_that("max_lts argument works in detailed_itineraries()", {
  expr <- "detailed_itineraries(
    r5r_core,
    pois[1:5],
    pois[5:1],
    mode = 'BICYCLE'
  )"

  fast_expr <- sub("\\)$", ", max_lts = 4\\)", expr)
  slow_expr <- sub("\\)$", ", max_lts = 1\\)", expr)

  fast_res <- eval(parse(text = fast_expr))
  slow_res <- eval(parse(text = slow_expr))

  expect_true(all(slow_res$segment_duration >= fast_res$segment_duration))
})

test_that("max_lts argument works in accessibility()", {
  expr <- "accessibility(
    r5r_core,
    points[1:15],
    points[1:15],
    mode = 'BICYCLE',
    opportunities_colnames = 'population',
    decay_function = 'step',
    cutoffs = 30
  )"

  fast_expr <- sub("\\)$", ", max_lts = 4\\)", expr)
  slow_expr <- sub("\\)$", ", max_lts = 1\\)", expr)

  fast_res <- eval(parse(text = fast_expr))
  slow_res <- eval(parse(text = slow_expr))

  expect_true(all(slow_res$accessibility <= fast_res$accessibility))
})
