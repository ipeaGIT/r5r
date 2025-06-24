# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()


tester <- function(pbf_path = paste0(data_path,'/poa_osm.pbf'),
                   csv_path = paste0(data_path,'/poa_osm_congestion.csv'),
                   output_dir = tempdir(check = TRUE),
                   default_speed = 1,
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

  # calculate ttm *before* changing road speeds
  df_pre <- r5r::travel_time_matrix(
    r5r_core = r5r_core,
    origins = pois,
    destinations = pois,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  # put all roads at 50% of their speed
  mock_data <- data.frame(osm_id = 1, max_speed = 1)
  mock_csv <- tempfile(fileext = '.csv')
  data.table::fwrite(mock_data, file = mock_csv)

  new_r5r_core <- tester(csv_path = mock_csv, default_speed = 0.5)

  df_pos <- r5r::travel_time_matrix(
    r5r_core = new_r5r_core,
    origins = pois,
    destinations = pois,
    mode = 'car',
    departure_datetime = Sys.time(),
    max_trip_duration = 60
  )

  # this should be twice as long
  testthat::expect_true(df_pos[2,]$travel_time_p50 > df_pre[2,]$travel_time_p50)

  # clean tempdir
  r5r::stop_r5(new_r5r_core)
  unlink(tempdir(check = TRUE), recursive = TRUE)
  list.files(tempdir(check = TRUE), all.files = TRUE, pattern = '.pbf')

})

test_that("errors due to incorrect input types", {

  expect_error(tester(pbf_path = 'banana'))
  expect_error(tester(csv_path = 'banana'))
  expect_error(tester(output_dir = 'banana'))

  expect_error(tester(default_speed = Inf))
  expect_error(tester(default_speed = NULL))

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
