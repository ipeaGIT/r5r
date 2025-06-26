# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

# TODO
# test if setting max_speed to 0 closes the road

tester <- function(pbf_path = paste0(data_path,'/poa_osm.pbf'),
                   csv_path = paste0(data_path,'/poa_osm_congestion.csv'),
                   output_dir = tempdir(check = TRUE),
                   default_speed = NULL,
                   percentage_mode = TRUE,
                   verbose = FALSE
                   ){
  new_r5r_core <- modify_osm_carspeeds(
    pbf_path = pbf_path,
    csv_path = csv_path,
    output_dir = output_dir,
    default_speed = default_speed,
    percentage_mode = percentage_mode,
    verbose = verbose
  )
}


# tests -------------------------------------------------------------------
test_that("success in increasing travel times", {

  # get origin and destination points in a single road
  network <- r5r::street_network_to_sf(r5r_core)

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
    r5r_core = r5r_core,
    origins = point_orig,
    destinations = point_dest,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  det_pre <- detailed_itineraries(
    r5r_core,
    origins = point_orig,
    destinations = point_dest,
    mode = "car",
    departure_datetime = departure_datetime,
    max_trip_duration = 60
  )

  # plot(det_pre['total_duration'])
  # mapview(network$edges) + network$vertices + det

  # # clean tempdir
  # r5r::stop_r5(new_r5r_core)
  # unlink(tempdir(check = TRUE), recursive = TRUE)
  # list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')

  # put all roads at 50% of their speed
  mock_data <- data.frame(osm_id = 9999, max_speed = 9999)
  mock_csv <- tempfile(fileext = '.csv')
  data.table::fwrite(mock_data, file = mock_csv)


  new_r5r_core <- tester(csv_path = mock_csv,
                         default_speed = 0.5,
                         percentage_mode = TRUE)

  ttm_pos <- r5r::travel_time_matrix(
    r5r_core = new_r5r_core,
    origins = point_orig,
    destinations = point_dest,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  det_pos <- detailed_itineraries(
    new_r5r_core,
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

  # clean tempdir
  r5r::stop_r5(new_r5r_core)
  unlink(tempdir(check = TRUE), recursive = TRUE)
  list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')


  testthat::expect_warning(
    tester(default_speed = 1,percentage_mode = FALSE)
  )

})

test_that("errors due to incorrect input types", {

  expect_error(tester(pbf_path = 'banana'))
  expect_error(tester(csv_path = 'banana'))
  expect_error(tester(output_dir = 'banana'))

  expect_error(tester(default_speed = Inf))
  expect_error(tester(default_speed = 'banana'))

  expect_error(tester(percentage_mode = 'banana'))
  expect_error(tester(percentage_mode = NULL))

  expect_error(tester(verbose = 'banana'))
  expect_error(tester(verbose = NULL))

})

test_that("errors due existing pbf in outputdir", {

  # clean tempdir
  r5r::stop_r5()
  unlink(tempdir(check = TRUE), recursive = TRUE)
  list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')

  new_r5r_core <- tester()
  expect_error(tester())

  # clean tempdir
  r5r::stop_r5(new_r5r_core)
  unlink(tempdir(check = TRUE), recursive = TRUE)
  list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')

  })


test_that("errors error in the csv column name", {

  mock_data <- data.frame(osm_id_col = 1, max_speed = 1)
  mock_csv <- tempfile(fileext = '.csv')
  data.table::fwrite(mock_data, file = mock_csv)

  expect_error(tester(csv_path = mock_csv))

})
