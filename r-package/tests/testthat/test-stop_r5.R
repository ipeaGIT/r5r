context("Stop r5r network")

testthat::skip_on_cran()

test_that("stop_r5 raises warnings and errors when supplied wrong objects", {
  path <- system.file("extdata/poa", package = "r5r")
  old_env <- environment()
  r5r_network <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)

  # tries to stop a non-r5r network object
  expect_warning(stop_r5(path))

  # tries to stop a nonexistent object
  expect_error(stop_r5(nonexistent_object))

  # stops the running r5r network object
  expect_message(stop_r5())
  expect_identical(environment(), old_env)
})

test_that("stop_r5 successfully stops multiple running r5r networks", {
  path <- system.file("extdata/poa", package = "r5r")
  old_env <- environment()

  # stops all running r5r networks

  r5r_network_1 <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)
  mid_env <- environment()
  r5r_network_2 <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)

  expect_message(stop_r5())
  expect_identical(environment(), old_env)

  # stops each network separately

  r5r_network_1 <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)
  r5r_network_2 <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)

  expect_message(stop_r5(r5r_network_2))
  expect_identical(environment(), mid_env)
  expect_message(stop_r5(r5r_network_1))
  expect_identical(environment(), old_env)
})
