# # if running manually, please run the following line first:
# # source("tests/testthat/setup.R")
#
testthat::skip_on_cran()
#
# tester <- function(draws_per_minute) {
#   set_monte_carlo_draws(r5r_core, draws_per_minute, time_window = 30)
# }
#
# test_that("input is correct", {
#   expect_error(tester("1"))
#   expect_error(tester(0))
#   expect_error(tester(c(1, 1)))
#   expect_error(tester(Inf))
# })
#
# # only one monte carlo draw is performed per minute if the routing function is
# # using the fastraptor algorithm and the gtfs feeds used to create the network
# # don't include a frequencies table (independently of the value set in
# # draws_per_minute). the number of monte carlo draws is respected when any of
# # the feeds include a frequencies table and when using the mcraptor algorithm.
#
# test_that("works in expanded_travel_time_matrix() - poa", {
#   basic_expr <- call(
#     "expanded_travel_time_matrix",
#     r5r_core = r5r_core,
#     origins = pois,
#     destinations = pois,
#     mode = c("TRANSIT", "WALK"),
#     departure_datetime = departure_datetime,
#     max_trip_duration = 60,
#     time_window = 30
#   )
#
#   small_draws_expr <- big_draws_expr <- basic_expr
#   small_draws_expr$draws_per_minute <- 1
#   big_draws_expr$draws_per_minute <- 5
#
#   small_draws <- eval(small_draws_expr)
#   big_draws <- eval(big_draws_expr)
#  # expect_identical(small_draws, big_draws)
#   expect_identical(unique(small_draws$draw_number), 1L)
# })
#
# test_that("works in expanded_travel_time_matrix() - spo", {
#   basic_expr <- call(
#     "expanded_travel_time_matrix",
#     r5r_core = spo_core,
#     origins = spo_points[51:65],
#     destinations = spo_points[51:65],
#     mode = c("TRANSIT", "WALK"),
#     departure_datetime = departure_datetime,
#     max_trip_duration = 60,
#     time_window = 30
#   )
#
#   small_draws_expr <- big_draws_expr <- basic_expr
#   small_draws_expr$draws_per_minute <- 1
#   big_draws_expr$draws_per_minute <- 5
#
#   small_draws <- eval(small_draws_expr)
#   expect_identical(unique(small_draws$draw_number), 1L)
#
#   big_draws <- eval(big_draws_expr)
#   draws_summary <- big_draws[
#     ,
#     .(contains_all_draws = identical(draw_number, 1:5)),
#     by = .(from_id, to_id, departure_time)
#   ]
#   expect_true(all(draws_summary$contains_all_draws))
#
#   big_draws_2 <- eval(big_draws_expr)
#   expect_false(identical(big_draws, big_draws_2))
# })
#
# # there's no way to actually know how many draws were performed with the other
# # functions, so we assume *some* draws are done and the randomization happens
# # if the results of the same expression are different in two different
# # evaluations
#
# test_that("works in travel_time_matrix() - poa", {
#   basic_expr <- call(
#     "travel_time_matrix",
#     r5r_core = r5r_core,
#     origins = pois,
#     destinations = pois,
#     mode = c("TRANSIT", "WALK"),
#     departure_datetime = departure_datetime,
#     max_trip_duration = 60,
#     time_window = 30,
#     percentiles = c(1, 50, 99)
#   )
#
#   small_draws_expr <- big_draws_expr <- basic_expr
#   small_draws_expr$draws_per_minute <- 1
#   big_draws_expr$draws_per_minute <- 5
#
#   small_draws <- eval(small_draws_expr)
#   big_draws <- eval(big_draws_expr)
#   expect_identical(small_draws, big_draws)
#
#   mcrap_basic_expr <- basic_expr
#   mcrap_basic_expr$fare_structure <- fare_structure
# test_that("works in expanded_travel_time_matrix() - spo", {
#   basic_expr <- call(
#     "expanded_travel_time_matrix",
#     r5r_core = spo_core,
#     origins = spo_points[51:65],
#     destinations = spo_points[51:65],
#     mode = c("TRANSIT", "WALK"),
#     departure_datetime = departure_datetime,
#     max_trip_duration = 60,
#     time_window = 30
#   )
#
#   small_draws_expr <- big_draws_expr <- basic_expr
#   small_draws_expr$draws_per_minute <- 1
#   big_draws_expr$draws_per_minute <- 5
#
#   small_draws <- eval(small_draws_expr)
#   expect_identical(unique(small_draws$draw_number), 1L)
#
#   big_draws <- eval(big_draws_expr)
#   draws_summary <- big_draws[
#     ,
#     .(contains_all_draws = identical(draw_number, 1:5)),
#     by = .(from_id, to_id, departure_time)
#   ]
#   expect_true(all(draws_summary$contains_all_draws))
#
#   big_draws_2 <- eval(big_draws_expr)
#   expect_false(identical(big_draws, big_draws_2))
# })

# there's no way to actually know how many draws were performed with the other
# functions, so we assume *some* draws are done and the randomization happens
# if the results of the same expression are different in two different
# evaluations

test_that("works in travel_time_matrix() - poa", {
  basic_expr <- call(
    "travel_time_matrix",
    r5r_core = r5r_core,
    origins = pois,
    destinations = pois,
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  small_draws <- eval(small_draws_expr)
  big_draws <- eval(big_draws_expr)
  expect_identical(small_draws, big_draws)

  mcrap_basic_expr <- basic_expr
  mcrap_basic_expr$fare_structure <- fare_structure
  mcrap_basic_expr$max_fare <- 5
  mcrap_small_draws_expr <- mcrap_big_draws_expr <- mcrap_basic_expr
  mcrap_small_draws_expr$draws_per_minute <- 1
  mcrap_big_draws_expr$draws_per_minute <- 5

  mcrap_small_draws <- eval(mcrap_small_draws_expr)
  mcrap_big_draws <- eval(mcrap_big_draws_expr)
  expect_false(identical(mcrap_small_draws, mcrap_big_draws))
})

test_that("works in travel_time_matrix() - spo", {
  basic_expr <- call(
    "travel_time_matrix",
    r5r_core = spo_core,
    origins = spo_points[51:80],
    destinations = spo_points[51:80],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  small_draws <- eval(small_draws_expr)
  big_draws <- eval(big_draws_expr)
  expect_false(identical(small_draws, big_draws))

  big_draws2 <- eval(big_draws_expr)
  expect_false(identical(big_draws, big_draws2))
})

test_that("works in accessibility() - poa", {
  basic_expr <- call(
    "accessibility",
    r5r_core = r5r_core,
    origins = points[1:30],
    destinations = points[1:30],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    opportunities_colnames = "population",
    decay_function = "step",
    cutoffs = 30,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  small_draws <- eval(small_draws_expr)
  big_draws <- eval(big_draws_expr)
  expect_identical(small_draws, big_draws)

  mcrap_basic_expr <- basic_expr
  mcrap_basic_expr$fare_structure <- fare_structure
  mcrap_basic_expr$max_fare <- 5
  mcrap_small_draws_expr <- mcrap_big_draws_expr <- mcrap_basic_expr
  mcrap_small_draws_expr$draws_per_minute <- 1
  mcrap_big_draws_expr$draws_per_minute <- 5

  mcrap_small_draws <- eval(mcrap_small_draws_expr)
  mcrap_big_draws <- eval(mcrap_big_draws_expr)
  expect_false(identical(mcrap_small_draws, mcrap_big_draws))
})

test_that("works in accessibility() - spo", {
  basic_expr <- call(
    "accessibility",
    r5r_core = spo_core,
    origins = spo_points[51:80],
    destinations = spo_points[51:80],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    opportunities_colnames = "opportunities",
    decay_function = "step",
    cutoffs = 30,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  small_draws <- eval(small_draws_expr)
  big_draws <- eval(big_draws_expr)
  expect_false(identical(small_draws, big_draws))

  big_draws2 <- eval(big_draws_expr)
  expect_false(identical(big_draws, big_draws2))
})

test_that("poa draws_per_minute should fail in pareto_frontier() issue #281", {
  basic_expr <- call(
    "pareto_frontier",
    r5r_core = r5r_core,
    origins = points[1:10],
    destinations = points[1:10],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  expect_error( eval(small_draws_expr) )
  expect_error( eval(big_draws_expr) )

})

test_that("spo draws_per_minute should fail in pareto_frontier() issue #281", {
  basic_expr <- call(
    "pareto_frontier",
    r5r_core = spo_core,
    origins = spo_points[51:80],
    destinations = spo_points[51:80],
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    max_trip_duration = 60,
    time_window = 30,
    percentiles = c(1, 50, 99),
    fare_structure = spo_fare_struc,
    fare_cutoffs = c(0, 5, 10, 15, Inf)
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  expect_error( eval(small_draws_expr) )
  expect_error( eval(big_draws_expr) )
})
