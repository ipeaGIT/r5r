# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(n_threads) set_n_threads(r5r_network, n_threads)

test_that("input is correct", {
  expect_error(tester("1"))
  expect_error(tester(c(1, 1)))
  expect_error(tester(0))
})

test_that("number of threads is set correctly", {
  expect_true(tester(1))
  expect_true(r5r_network$getNumberOfThreads() == 1)

  expect_true(tester(Inf))
  expect_true(r5r_network$getNumberOfThreads() == parallel::detectnetworks() - 1)
})
