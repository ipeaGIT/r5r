context("download_r5")


# expected behavior
test_that("setup_r5 - expected behavior", {
  path <- system.file("extdata", package = "r5r")

  testthat::expect_message( setup_r5(data_path = path) )
  testthat::expect_message(setup_r5(data_path = path, version='4.9.0'))

  # remove files GTFS
  file.rename(file.path(path, "poa.zip"), file.path(path, "poa.x"))
  testthat::expect_message( setup_r5(data_path = path) )
  file.rename(file.path(path, "poa.x"), file.path(path, "poa.zip"))

})




# Expected errors
test_that("setup_r5 - expected errors", {
  path <- system.file("extdata", package = "r5r")

  testthat::expect_error( setup_r5(data_path = NULL) )
  testthat::expect_error( download_r5(version = NULL ) )

  # remove existing network.dat
#  file.rename(file.path(path, "network.dat"), file.path(path, "network2.x"))
  file.remove(file.path(path, "network.dat"))
  testthat::expect_error( setup_r5(data_path = path, version = "0") )

  # remove files GTFS
  file.rename(file.path(path, "poa_osm.pbf"), file.path(path, "poa_osm.x"))
  testthat::expect_error( setup_r5(data_path = path) )
  file.rename(file.path(path, "poa_osm.x"), file.path(path, "poa_osm.pbf"))

  })
