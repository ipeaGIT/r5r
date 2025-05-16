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

  # invalid radius
  expect_error( find_snap(r5r_core=r5r_core, points = 'a', radius = -90, mode = 'WALK') )

})


# adequate behavior ------------------------------------------------------


test_that("output is correct", {

  # expected behavior
  expect_s3_class( find_snap(r5r_core=r5r_core, points = points, mode = 'WALK'), 'data.table')

  # 6 points don't get snapped using the default radius after moving them
  points_snap <- points
  points_snap$lat <- points_snap$lat + 0.01
  expect_equal(
    sum(!find_snap(r5r_core, points_snap, mode = 'WALK')$found),
    6
  )

  # all points are snapped after increasing the radius
  expect_equal(
    sum(!find_snap(r5r_core, points_snap, mode = 'WALK', radius = 5000)$found),
    0
  )

})
