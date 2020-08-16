context("download_r5")

path <- system.file("extdata", package = "r5r")

# expected behavior
test_that("download_r5- expected behavior", {

  testthat::expect_message( setup_r5(data_path = path) )
  testthat::expect_message(setup_r5(data_path = path, version='4.9.0'))

  # remove files GTFS
  file.remove( file.path(path, "poa.zip") )
  testthat::expect_message( setup_r5(data_path = path) )

})





# Expected errors
test_that("download_r5 - expected errors", {

  testthat::expect_error( setup_r5(data_path = NULL) )
  testthat::expect_error( download_r5(version = NULL ) )

  # remove existing network.dat
  file.remove( file.path(path, "network.dat") )
  testthat::expect_error( setup_r5(data_path = path, version = "0") )

  # remove files GTFS
  file.remove( file.path(path, c("poa_osm.pbf" , "poa_osm.pbf.mapdb", "poa_osm.pbf.mapdb.p" )) )
  testthat::expect_error( setup_r5(data_path = path) )

  })
