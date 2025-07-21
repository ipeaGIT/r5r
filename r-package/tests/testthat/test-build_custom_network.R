# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

# TODO
# test if setting max_speed to 0 closes the road

# data.frame with new speed info
new_carspeeds <- read.csv(file.path(data_path, "poa_osm_congestion.csv"))

# sf with congestion polygons
congestion_poly <- readRDS(file.path(data_path, "poa_poly_congestion.rds"))

tester <- function(test_data_path = data_path,
                   test_new_carspeeds = new_carspeeds,
                   output_path = tempdir(check = TRUE),
                   default_speed = NULL,
                   percentage_mode = TRUE,
                   verbose = FALSE,
                   elevation = "TOBLER"
                   ){
  new_r5r_network <- r5r::build_custom_network(
    data_path = test_data_path,
    new_carspeeds = test_new_carspeeds,
    output_path = output_path,
    default_speed = default_speed,
    percentage_mode = percentage_mode,
    verbose = verbose,
    elevation = elevation
  )
}


# tests -------------------------------------------------------------------
test_that("success in increasing travel times", {

  # get origin and destination points in a single road
  network <- r5r::street_network_to_sf(r5r_network)

  point_orig <- network$vertices |>
    dplyr::filter(index == 		18050 ) |> # 7772
    sfheaders::sf_to_df() |>
    dplyr::select(id=sfg_id, lon=x, lat=y)

  point_dest <- network$vertices |>
    dplyr::filter(index == 16844 )  |> #8128
    sfheaders::sf_to_df() |>
    dplyr::select(id=sfg_id, lon=x, lat=y)

  # calculate ttm *before* changing road speeds
  ttm_pre <- r5r::travel_time_matrix(
    r5r_network = r5r_network,
    origins = point_orig,
    destinations = point_dest,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  det_pre <- detailed_itineraries(
    r5r_network,
    origins = point_orig,
    destinations = point_dest,
    mode = "car",
    departure_datetime = departure_datetime,
    max_trip_duration = 60
  )

  # plot(det_pre['total_duration'])
  # mapview(network$edges) + network$vertices + det

  # # clean tempdir
  # r5r::stop_r5(new_r5r_network)
  # unlink(tempdir(check = TRUE), recursive = TRUE)
  # list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')

  # put all roads at 50% of their speed
  mock_data <- data.frame(osm_id = 9999, max_speed = 9999)

  new_r5r_network <- tester(test_new_carspeeds = mock_data,
                            default_speed = 0.5,
                            percentage_mode = TRUE)

  ttm_pos <- r5r::travel_time_matrix(
    r5r_network = new_r5r_network,
    origins = point_orig,
    destinations = point_dest,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  det_pos <- detailed_itineraries(
    new_r5r_network,
    origins = point_orig,
    destinations = point_dest,
    mode = "car",
    departure_datetime = departure_datetime,
    max_trip_duration = 60
  )

  #  mapview(det_pre) + det_pos

  # this should be twice as long
  testthat::expect_true(ttm_pos$travel_time_p50 > ttm_pre$travel_time_p50)
  testthat::expect_true(det_pos$total_duration > det_pre$total_duration)
  testthat::expect_true(det_pos$total_distance == det_pre$total_distance)

  testthat::expect_message(
    tester(default_speed = 1, percentage_mode = FALSE),
    regexp = "`percentage_mode` is .*, but `default_speed` is still"
  )

})

test_that("errors in congestion polygon", {

  # wrong col names
  wrong_congestion_poly1 <- congestion_poly
  names(wrong_congestion_poly1) <- c("poly_id", "speed", "priority", "geometry")
  testthat::expect_error(tester(test_new_carspeeds = wrong_congestion_poly1))

  # missing col
  wrong_congestion_poly2 <- congestion_poly
  wrong_congestion_poly2$poly_id <- NULL
  testthat::expect_error(tester(test_new_carspeeds = wrong_congestion_poly2))

  # Wrong geometry type
  #wrong_congestion_poly3 <- congestion_poly
  #wrong_congestion_poly3 <- sf::st_cast(wrong_congestion_poly3, to = 'MULTIPOINT')
  #testthat::expect_error(tester(test_new_carspeeds = wrong_congestion_poly3))

  # Wrong projection
  wrong_congestion_poly4 <- sf::st_transform(congestion_poly, 3857)
  testthat::expect_error(tester(test_new_carspeeds = wrong_congestion_poly4))

  })


test_that("errors due to incorrect input types", {

  testthat::expect_error(tester(test_new_carspeeds = congestion_poly, percentage_mode = FALSE))

  expect_error(tester(data_path = 'banana'))
  expect_error(tester(new_carspeeds = 'banana'))
  expect_error(tester(output_path  = 'banana'))

  expect_error(tester(default_speed = Inf))
  expect_error(tester(default_speed = 'banana'))

  expect_error(tester(percentage_mode = 'banana'))
  expect_error(tester(percentage_mode = NULL))

  expect_error(tester(verbose = 'banana'))
  expect_error(tester(verbose = NULL))

})

test_that("overwrite existing network in outputdir", {

  testthat::expect_message(new_r5r_network <- tester())
  expect_true(is(new_r5r_network, "r5r_network"))

  testthat::expect_message(new_r5r_network <- tester(test_new_carspeeds = congestion_poly))
  expect_true(is(new_r5r_network, "r5r_network"))

  })


test_that("errors error in the new_carspeeds column names", {

  mock_data <- data.frame(osm_id_col = 1, max_speed = 1)
  expect_error(tester(test_new_carspeeds = mock_csv))

})

test_that("no pbf data provided", {
  expect_error(tester(test_data_path = tempdir_unique()))
})
