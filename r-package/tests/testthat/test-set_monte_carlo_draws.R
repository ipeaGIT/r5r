# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(draws_per_minute) {
  set_monte_carlo_draws(r5r_core, draws_per_minute, time_window = 30)
}

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(0))
  expect_error(tester(c(1, 1)))
  expect_error(tester(Inf))
})

# only one monte carlo draw is performed per minute if the gtfs feeds used to
# create the network don't include a frequencies table (independently of the
# value set in draws_per_minute). this value is respected when any of the feeds
# include a frequencies table

test_that("draws_per_minute arg works in expanded_travel_time_matrix()", {
  basic_expr <- call(
    "expanded_travel_time_matrix",
    r5r_core = r5r_core,
    origins = pois,
    destinations = pois,
    mode = c("TRANSIT", "WALK"),
    departure_datetime = departure_datetime,
    max_trip_duration = 60,
    time_window = 30
  )

  small_draws_expr <- big_draws_expr <- basic_expr
  small_draws_expr$draws_per_minute <- 1
  big_draws_expr$draws_per_minute <- 5

  small_draws <- eval(small_draws_expr)
  big_draws <- eval(big_draws_expr)
  expect_identical(small_draws, big_draws)
  expect_identical(unique(small_draws$draw_number), 1L)

  spo_basic_expr <- basic_expr
  spo_basic_expr$r5r_core <- spo_core
  spo_basic_expr$origins <- spo_points[51:65]
  spo_basic_expr$destinations <- spo_points[51:65]

  spo_small_draws_expr <- spo_big_draws_expr <- spo_basic_expr
  spo_small_draws_expr$draws_per_minute <- 1
  spo_big_draws_expr$draws_per_minute <- 5

  # all od pairs should include n entries per departure_time, where n the
  # specified number of draws

  spo_small_draws <- eval(spo_small_draws_expr)
  expect_identical(unique(spo_small_draws$draw_number), 1L)

  spo_big_draws <- eval(spo_big_draws_expr)
  draws_summary <- spo_big_draws[
    ,
    .(contains_all_draws = identical(draw_number, 1:5)),
    by = .(from_id, to_id, departure_time)
  ]
  expect_true(all(draws_summary$contains_all_draws))

  # results are always different because of R5 randomization

  spo_big_draws_2 <- eval(spo_big_draws_expr)
  expect_false(identical(spo_big_draws, spo_big_draws_2))
})
