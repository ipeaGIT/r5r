context("setup_r5")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

path <- system.file("extdata/poa", package = "r5r")

# expected behavior
test_that("setup_r5 - expected behavior", {

  testthat::expect_message( setup_r5(data_path = path, verbose = F, temp_dir = TRUE) )
  testthat::expect_message( setup_r5(data_path = path, verbose = T, temp_dir = TRUE) )

  testthat::expect_message( setup_r5(data_path = path, use_elevation=T, temp_dir = TRUE) )

  # remove files GTFS
  #  file.rename(file.path(path, "poa.zip"), file.path(path, "poa.x"))
  # testthat::expect_message( setup_r5(data_path = path, verbose = F) )
  #  file.rename(file.path(path, "poa.x"), file.path(path, "poa.zip"))

  testthat::expect_message(setup_r5(data_path = path, version='6.4.0', verbose = F, temp_dir = TRUE))

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

test_that("'overwrite' parameter works correctly", {

  testthat::expect_error(setup_r5(path, overwrite = 1))

  # since a network was already created, if overwrite = FALSE it should use it
  testthat::expect_message(
    r5r_core <- setup_r5(path, verbose = FALSE, temp_dir = TRUE),
    regexp = "Using cached network\\.dat from "
  )

  # but if overwrite = TRUE, then it should create a new network anyway
  testthat::expect_message(
    r5r_core <- setup_r5(path, verbose = FALSE, overwrite = TRUE, temp_dir = TRUE),
    regexp = "Finished building network\\.dat at "
  )

})

stop_r5()
