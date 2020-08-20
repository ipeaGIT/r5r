context("travel_time_matrix")

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

# setup_r5
path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = path)

# input
mode <- "WALK"
departure_time <- "14:00:00"
trip_date <- "2019-05-20"
max_trip_duration = 300L

df <- travel_time_matrix( r5r_core,
                          origins = points,
                          destinations = points,
                          trip_date,
                          departure_time,
                          mode = mode,
                          max_trip_duration,
                          verbose = FALSE)

df_sf <- travel_time_matrix( r5r_core,
                          origins = points_sf,
                          destinations = points_sf,
                          trip_date,
                          departure_time,
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
                        trip_date,
                        departure_time,
                        mode,
                        max_street_time,
                        max_trip_duration))
  testthat::expect_error(
    travel_time_matrix( r5r_core,
                        origins = points,
                        destinations = 'a',
                        trip_date,
                        departure_time,
                        mode,
                        max_street_time,
                        max_trip_duration))

  # invalid modes
  testthat::expect_error(
    travel_time_matrix( r5r_core = r5r_core,
                        origins = points_sf,
                        destinations = points_sf,
                        trip_date,
                        departure_time,
                        mode = "pogoball",
                        max_trip_duration))


  # # invalid max_trip_duration
  # testthat::expect_error(
  #   travel_time_matrix( r5r_core,
  #                       origins = points,
  #                       destinations = points,
  #                       trip_date,
  #                       departure_time,
  #                       mode,
  #                       max_trip_duration = 'aaa'))

  })
