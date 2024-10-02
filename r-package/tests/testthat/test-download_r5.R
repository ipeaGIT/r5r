context("download_r5")

# skips tests on CRAN
testthat::skip_on_cran()

# expected behavior
test_that("download_r5 - expected behavior", {

  testthat::expect_vector(download_r5(force_update = TRUE, temp_dir = TRUE))
  testthat::expect_vector(download_r5(force_update = TRUE, temp_dir = FALSE))
  testthat::expect_vector(download_r5(force_update = FALSE, temp_dir = TRUE))
  testthat::expect_vector(download_r5(force_update = FALSE, quiet = TRUE))

  # testthat::expect_vector(download_r5())
  # file.remove(file.path(.libPaths()[1], "r5r", "jar", "r5r_v4.9.0.jar"))
  # testthat::expect_vector(download_r5(version='4.9.0'))

})

# Expected errors
test_that("download_r5 - expected errors", {

  testthat::expect_error( download_r5(version = "0") )
  testthat::expect_error(download_r5(force_update = 'a'))
  testthat::expect_error(download_r5(quiet = 'a'))
  testthat::expect_error(download_r5(temp_dir = 'a'))

  })
