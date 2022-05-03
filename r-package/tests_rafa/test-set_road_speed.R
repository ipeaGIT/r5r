context("set_road_speed")

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

path <- system.file("extdata/poa", package = "r5r")
all_files <- list.files(path, full.names = T)


# expected behavior
test_that("set_road_speed - expected behavior", {

  # test 1
  testthat::expect_message( set_road_speed(data_path = path,
                                           motorway = 1
                                           , motorway_link = 1
                                           , trunk = 1
                                           , trunk_link = 1
                                           , primary = 1
                                           , primary_link = 1
                                           , secondary = 1
                                           , secondary_link = 1
                                           , tertiary = 1
                                           , tertiary_link = 1
                                           , living_street = 1
                                           , pedestrian = 1
                                           , residential = 1
                                           , unclassified = 1
                                           , service = 1
                                           , track = 1
                                           , road = 1
                                           , defaultSpeed = 1) )

  # json file created ?
  testthat::expect_length( list.files(path, full.names = T, pattern = 'build-config.json'), 1 )

  # can setup_r5() build network?
  testthat::expect_message( setup_r5(data_path = path, verbose = TRUE, temp_dir = TRUE, overwrite = TRUE) )

})




# Expected errors
test_that("set_road_speed - expected errors", {

  testthat::expect_error( set_road_speed(data_path = path,
                                         primary = 1,
                                         defaultSpeed = NULL) )

  testthat::expect_error( set_road_speed(data_path = path,
                                         primary = 'a',
                                         defaultSpeed = 1) )

  })



stop_r5()
