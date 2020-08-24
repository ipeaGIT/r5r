context("travel_time_matrix")

testthat::skip_on_cran()
testthat::skip_on_travis()

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:10,]
points_sf <- sfheaders::sf_point(points, x='lon', y='lat', keep = T)

# setup_r5
path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = path)

# input
mode = 'BICYCLE'
max_trip_duration = 300L
departure_datetime = as.POSIXct("13-03-2019 14:00:00",
                                format = "%d-%m-%Y %H:%M:%S")

df <- travel_time_matrix( r5r_core,
                          origins = points,
                          destinations = points,
                          departure_datetime,
                          mode = mode,
                          max_trip_duration,
                          verbose = FALSE)

df_sf <- travel_time_matrix( r5r_core,
                          origins = points_sf,
                          destinations = points_sf,
                          departure_datetime,
                          mode = mode,
                          max_trip_duration,
                          verbose = FALSE)

# expected behavior
test_that("setup_r5 - expected behavior", {

  testthat::expect_true(is(df, "data.table"))
  testthat::expect_true(is(df_sf, "data.table"))

})




# Expected errors
test_that("travel_time_matrix - expected errors", {


  # invalid origins destinations
  testthat::expect_error(
    travel_time_matrix( r5r_core,
                        origins = 'a',
                        destinations = points,
                        departure_datetime,
                        mode,
                        max_street_time,
                        max_trip_duration))
  testthat::expect_error(
    travel_time_matrix( r5r_core,
                        origins = points,
                        destinations = 'a',
                        departure_datetime,
                        mode,
                        max_street_time,
                        max_trip_duration))

  # invalid modes
  testthat::expect_error(
    travel_time_matrix( r5r_core = r5r_core,
                        origins = points_sf,
                        destinations = points_sf,
                        departure_datetime,
                        mode = "pogoball",
                        max_trip_duration))


  # # invalid max_trip_duration
  # testthat::expect_error(
  #   travel_time_matrix( r5r_core,
  #                       origins = points,
  #                       destinations = points,
  #                       departure_datetime,
  #                       mode,
  #                       max_trip_duration = 'aaa'))

  })
