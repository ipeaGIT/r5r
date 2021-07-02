context("setup_r5")

testthat::skip_on_cran()

path <- system.file("extdata/poa", package = "r5r")

# expected behavior
test_that("setup_r5 - expected behavior", {

  testthat::expect_message( setup_r5(data_path = path, verbose = F) )
  testthat::expect_message( setup_r5(data_path = path, verbose = T) )

  testthat::expect_message( setup_r5(data_path = path, use_elevation=T) )

  # remove files GTFS
  #  file.rename(file.path(path, "poa.zip"), file.path(path, "poa.x"))
  # testthat::expect_message( setup_r5(data_path = path, verbose = F) )
  #  file.rename(file.path(path, "poa.x"), file.path(path, "poa.zip"))

  testthat::expect_message(setup_r5(data_path = path, version='6.0.1', verbose = F))

})




# Expected errors
test_that("setup_r5 - expected errors", {

  testthat::expect_error( setup_r5(data_path = NULL) )
  testthat::expect_error( setup_r5(data_path = 'a') )
  testthat::expect_error(setup_r5(data_path = path, verbose = 'a'))
  testthat::expect_error(setup_r5(data_path = path, temp_dir = 'a'))
  testthat::expect_error(setup_r5(data_path = path, use_elevation = 'a'))
#  testthat::expect_error(setup_r5(data_path = path, version = 'a'))

  # No OSM data
  testthat::expect_error( setup_r5(data_path = file.path(.libPaths()[1]) ) )

  # # remove existing network.dat
  #   file.rename(file.path(path, "network.dat"), file.path(path, "network2.x"))
  #   testthat::expect_error( setup_r5(data_path = path, version = "0") )
  #   testthat::expect_error( setup_r5(data_path = path, verbose ='a') )
  #   file.rename(file.path(path, "network2.x"), file.path(path, "network.dat"))

  })

stop_r5()
