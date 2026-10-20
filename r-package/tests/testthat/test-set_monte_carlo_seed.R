tester <- function(seed) set_monte_carlo_seed(r5r_network@jcore, seed)

test_that("input is correct", {
  skip_on_cran()
  expect_error(tester("1"))
  expect_error(tester(1.5))
  expect_error(tester(c(1, 2)))
  expect_error(tester(NA))
  expect_error(tester(1e10))
  expect_true(tester(NULL))
  expect_true(tester(1))
  r5r_network@jcore$resetRoutingProperties()
})

# spo has a frequencies.txt table, so its Monte Carlo draws are random unless seeded
spo_orig <- spo_points[51:55]
run_spo <- function(fun, seed, ...) {
  fun(
    spo_network,
    origins = spo_orig,
    destinations = spo_points,
    mode = c("WALK", "TRANSIT"),
    departure_datetime = departure_datetime,
    time_window = 5L,
    max_trip_duration = 60L,
    seed = seed,
    progress = FALSE,
    ...
  )
}

test_that("the same seed gives identical travel time matrices, regardless of n_threads", {
  skip_on_cran()
  first <- run_spo(travel_time_matrix, 1L, draws_per_minute = 2L, n_threads = 1)
  second <- run_spo(travel_time_matrix, 1L, draws_per_minute = 2L, n_threads = 2)
  expect_identical(first, second)
})

test_that("the same seed gives identical results in the other Monte Carlo functions", {
  skip_on_cran()
  expect_identical(
    run_spo(accessibility, 1L, opportunities_colnames = "opportunities", cutoffs = 30L, draws_per_minute = 2L),
    run_spo(accessibility, 1L, opportunities_colnames = "opportunities", cutoffs = 30L, draws_per_minute = 2L)
  )
  # also checks that draw_number is assigned in a stable order
  expect_identical(
    run_spo(expanded_travel_time_matrix, 1L, draws_per_minute = 2L, n_threads = 1),
    run_spo(expanded_travel_time_matrix, 1L, draws_per_minute = 2L, n_threads = 2)
  )
  arrival <- function() arrival_travel_time_matrix(
    spo_network, origins = spo_orig, destinations = spo_points, mode = c("WALK", "TRANSIT"),
    arrival_datetime = departure_datetime + 3600, max_trip_duration = 60L, draws_per_minute = 2L,
    seed = 1L, progress = FALSE
  )
  expect_identical(arrival(), arrival())

  surface <- function() travel_time_surface(
    spo_network, origins = spo_orig, mode = c("WALK", "TRANSIT"), departure_datetime = departure_datetime,
    time_window = 5L, max_trip_duration = 60L, draws_per_minute = 2L, seed = 1L, progress = FALSE
  )
  expect_identical(surface(), surface())
})

test_that("the same seed gives identical results with the McRaptor (fare) router", {
  skip_on_cran()
  frontier <- function() pareto_frontier(
    spo_network, origins = spo_orig, destinations = spo_points[56:60], mode = c("WALK", "TRANSIT"),
    departure_datetime = departure_datetime, time_window = 5L, max_trip_duration = 60L,
    fare_structure = spo_fare_struc, fare_cutoffs = c(5, 10), seed = 1L, progress = FALSE
  )
  expect_identical(frontier(), frontier())
})

test_that("different seeds give different draws", {
  skip_on_cran()
  seed_1 <- run_spo(expanded_travel_time_matrix, 1L, draws_per_minute = 2L)
  seed_2 <- run_spo(expanded_travel_time_matrix, 2L, draws_per_minute = 2L)
  expect_false(identical(seed_1, seed_2))
})
