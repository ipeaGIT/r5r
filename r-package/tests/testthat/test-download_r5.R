context("download_r5")

test_that("download_r5- expected behavior", {

  testthat::expect_vector(download_r5())
  testthat::expect_vector(download_r5(version='1.0'))

})


# Expected errors
test_that("download_r5 - expected errors", {

  testthat::expect_error( download_r5(version = "0") )
  testthat::expect_error( download_r5(version = NULL ) )

  })
