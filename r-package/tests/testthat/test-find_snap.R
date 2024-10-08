context("find_snap function")

testthat::skip_on_cran()


# errors and warnings -----------------------------------------------------


test_that("adequately raises errors", {

  # invalid mode
  expect_error( find_snap(r5r_core, points = points, mode = 'AAA') )

  # invalid r5r_core
  expect_error( find_snap(r5r_core='a', points = points, mode = 'WALK') )

  # invalid points
  expect_error( find_snap(r5r_core=r5r_core, points = 'a', mode = 'WALK') )

})


# adequate behavior ------------------------------------------------------


test_that("output is correct", {

  # expected behavior
  expect_s3_class( find_snap(r5r_core=r5r_core, points = points, mode = 'WALK'), 'data.table')

})
