context("elevation utils")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

# load required data and setup r5r_core
raster_poa <- system.file("extdata/poa/poa_elevation.tif", package = "r5r")
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)



# tobler_hiking -----------------------------------------------------

test_that("tobler_hiking", {

  expect_error( tobler_hiking('bananas') )
  expect_error( tobler_hiking() )
  expect_identical( round( r5r:::tobler_hiking(1)), 33)

})



# apply_elevation -----------------------------------------------------

test_that("apply_elevation", {

  if (requireNamespace("rgdal", quietly = TRUE)) {

    expect_silent( r5r:::apply_elevation(r5r_core, raster_poa) )
    expect_silent( r5r:::apply_elevation(r5r_core, c(raster_poa,raster_poa)) )

  }

  expect_error( r5r:::apply_elevation('bananas', raster_poa) )
  expect_error( r5r:::apply_elevation(r5r_core, 'bananas') )

})

stop_r5(r5r_core)
