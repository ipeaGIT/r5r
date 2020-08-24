context("Support functions")

testthat::skip_on_cran()
testthat::skip_on_travis()


# load required data and setup r5r_obj
data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))


# set_verbose -------------------------------------------------------------


test_that("set_verbose adequately raises warnings and errors", {

  expect_error(set_verbose("r5r_obj", TRUE))
  expect_error(set_verbose(r5r_obj, "TRUE"))
  expect_error(set_verbose(r5r_obj, 1))

})


# set_max_street_time -----------------------------------------------------


test_that("set_max_street_time adequately raises warnings and errors", {

  expect_error(set_max_walk_distance("1000", 3.6, 60L))
  expect_error(set_max_walk_distance(1000, "3.6", 60L))
  # expect_error(set_max_walk_distance(3700, 3.6, "60L")) # should this fail though?

})

test_that("set_max_street_time output is coherent", {

  expect_equal(set_max_street_time(Inf, 3.6, 60L), 60L)
  expect_equal(set_max_street_time(1800, 3.6, 60L), 30L)
  expect_equal(set_max_street_time(7200, 3.6, 60L), 60L)

})


# select_mode -------------------------------------------------------------


test_that("select_mode adequately raises warnings and errors", {

  expect_error(select_mode("POGOBALL"))

})


# posix_to_string ---------------------------------------------------------


test_that("posix_to_string adequately raises warnings and errors", {

  datetime <- as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

  expect_error(posix_to_string(as.character(datetime)))
  expect_error(posix_to_string(as.integer(datetime)))

})

test_that("posix_to_string output is coherent", {

  datetime <- as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
  datetime <- posix_to_string(datetime)

  expect_equal(datetime$date, "2019-03-13")
  expect_equal(datetime$time, "14:00:00")

  datetime <- as.POSIXct("13-03-1919 2:00:00 pm", format = "%d-%m-%Y %I:%M:%S %p")
  datetime <- posix_to_string(datetime)

  expect_equal(datetime$date, "1919-03-13")
  expect_equal(datetime$time, "14:00:00")

})


# assert_points_input -----------------------------------------------------


test_that("assert_points_input adequately raises warnings and errors", {

  multipoint_points <- sf::st_cast(sf::st_as_sf(points, coords = c("lon", "lat")), "MULTIPOINT")
  list_points <- setNames(lapply(names(points), function(i) points[[i]]), names(points))

  # object class

  expect_error(assert_points_input(as.matrix(points), "points"))
  expect_error(assert_points_input(list_points, "points"))
  expect_error(assert_points_input(multipoint_points, "points"))

  # object columns types

  points_numeric_id <- data.table::setDT(data.table::copy(points))[, id := 1:.N]
  points_char_lat <- data.table::setDT(data.table::copy(points))[, lat := as.character(lat)]
  points_char_lon <- data.table::setDT(data.table::copy(points))[, lon := as.character(lon)]

  expect_warning(assert_points_input(points_numeric_id, "points"))
  expect_error(assert_points_input(points_char_lat, "points"))
  expect_error(assert_points_input(points_char_lon, "points"))

})

test_that("assert_points_input output is coherent", {

  sf_points <- sf::st_as_sf(points, coords = c("lon", "lat"))
  sf_points_output <- assert_points_input(sf_points, "points")

  df_points_output <- assert_points_input(points, "points")

  # correct output column types

  expect_type(sf_points_output$id, "character")
  expect_type(sf_points_output$lat, "double")
  expect_type(sf_points_output$lon, "double")

  # expect output columns to have the same value, irrespective of input class

  expect_equal(sf_points_output$id, df_points_output$id, points$id)
  expect_equal(sf_points_output$lat, df_points_output$lat, points$lat)
  expect_equal(sf_points_output$lon, df_points_output$lon, points$lon)

})


# set_n_threads -----------------------------------------------------------


test_that("set_n_threads adequately raises warnings and errors", {

  expect_error(set_n_threads("r5r_obj", 2))
  expect_error(set_n_threads(r5r_obj, "2"))

})


# set_speed ---------------------------------------------------------------


test_that("set_speed adequately raises warnings and errors", {

  expect_error(set_speed("r5r_obj", 3.6, "walk"))
  expect_error(set_speed(r5r_obj, "3.6", "walk"))

})

stop_r5(r5r_obj)
