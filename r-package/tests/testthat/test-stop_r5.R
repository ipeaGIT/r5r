context("Stop r5r core")

testthat::skip_on_cran()
testthat::skip_on_travis()


test_that("stop_r5 raises warnings and errors when supplied wrong objects", {
  path <- system.file("extdata", package = "r5r")
  old_env <- environment()
  r5r_core <- setup_r5(data_path = path, verbose=FALSE)

  # tries to stop a non-r5r core object
  expect_warning(stop_r5(path))

  # tries to stop a nonexistent object
  expect_error(stop_r5(nonexistent_object))

  # stops the running r5r core object
  expect_message(stop_r5())
  expect_identical(environment(), old_env)
})

test_that("stop_r5 successfully stops multiple running r5r cores", {
  path <- system.file("extdata", package = "r5r")
  old_env <- environment()

  # stops all running r5r cores

  r5r_core_1 <- setup_r5(data_path = path, verbose=FALSE)
  mid_env <- environment()
  r5r_core_2 <- setup_r5(data_path = path, verbose=FALSE)

  expect_message(stop_r5())
  expect_identical(environment(), old_env)

  # stops each core separately

  r5r_core_1 <- setup_r5(data_path = path, verbose=FALSE)
  r5r_core_2 <- setup_r5(data_path = path, verbose=FALSE)

  expect_message(stop_r5(r5r_core_2))
  expect_identical(environment(), mid_env)
  expect_message(stop_r5(r5r_core_1))
  expect_identical(environment(), old_env)
})
