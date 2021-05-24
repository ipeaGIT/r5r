context("find_snap function")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

# load required data and setup r5r_core

data_path <- system.file("extdata/spo", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))





# errors and warnings -----------------------------------------------------


test_that("adequately raises errors", {

  # invalid mode
  expect_error( find_snap(r5r_core, points = points, mode = 'AAA') )

  # invalid r5r_core
  expect_error( find_snap(r5r_core='a', points = points, mode = 'WALK') )

  # invalid r5r_core
  expect_error( find_snap(r5r_core=r5r_core, points = 'a', mode = 'WALK') )

})


# adequate behavior ------------------------------------------------------


test_that("output is correct", {

  # expected behavior
  expect_s3_class( find_snap(r5r_core, points = points, mode = 'WALK'), 'data.table' )

})

stop_r5(r5r_core)
