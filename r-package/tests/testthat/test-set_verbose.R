# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(verbose) set_verbose(r5r_core, verbose)

test_that("input is correct", {
  expect_error(tester("TRUE"))
  expect_error(tester(c(TRUE, TRUE)))
  expect_error(tester(NA))
})

test_that("verbose argument works in routing functions", {
  verbose_messages <- capture.output(
    res <- travel_time_matrix(r5r_core, pois[1], pois[1], verbose = TRUE),
    type = "message"
  )
  expect_true(
    any(grepl("(\\[main\\] INFO)|(\\[main\\] DEBUG)", verbose_messages))
  )

  non_verbose_messages <- capture.output(
    res <- travel_time_matrix(r5r_core, pois[1], pois[1], verbose = FALSE),
    type = "message"
  )
  expect_false(
    any(grepl("(\\[main\\] INFO)|(\\[main\\] DEBUG)", non_verbose_messages))
  )
})
