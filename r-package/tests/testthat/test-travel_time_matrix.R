context("travel_time_matrix")

# setup_r5
path <- system.file("extdata", package = "r5r")
r5_core <- setup_r5(data_path = path)

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

# input
direct_modes <- c("WALK")
transit_modes <-"BUS"
departure_time <- "14:00:00"
trip_date <- "2019-05-20"
street_time = 15L
max_street_time = 30L
max_trip_duration = 300L

df <- travel_time_matrix( r5_core = r5_core,
                          origins = points,
                          destinations = points,
                          trip_date = trip_date,
                          departure_time = departure_time,
                          direct_modes = direct_modes,
                          transit_modes = transit_modes,
                          max_street_time = max_street_time,
                          max_trip_duration = max_trip_duration)

df_sf <- travel_time_matrix( r5_core = r5_core,
                          origins = points_sf,
                          destinations = points_sf,
                          trip_date = trip_date,
                          departure_time = departure_time,
                          direct_modes = direct_modes,
                          transit_modes = transit_modes,
                          max_street_time = max_street_time,
                          max_trip_duration = max_trip_duration)

# expected behavior
test_that("setup_r5 - expected behavior", {

  testthat::expect_true(is(df, "data.table"))
  testthat::expect_true(is(df_sf, "data.table"))

})




# Expected errors
test_that("travel_time_matrix - expected errors", {


  # invalid modes
  travel_time_matrix( r5_core = r5_core,
                      origins = points_sf,
                      destinations = points_sf,
                      trip_date = trip_date,
                      departure_time = departure_time,
                      direct_modes = "pogoball",
                      transit_modes = transit_modes,
                      max_street_time = max_street_time,
                      max_trip_duration = max_trip_duration)

  travel_time_matrix( r5_core = r5_core,
                      origins = points_sf,
                      destinations = points_sf,
                      trip_date = trip_date,
                      departure_time = departure_time,
                      direct_modes = direct_modes,
                      transit_modes = 'mothership',
                      max_street_time = max_street_time,
                      max_trip_duration = max_trip_duration)

  # invalid max_trip_duration
  testthat::expect_error(
  travel_time_matrix( r5_core,
                      origins = points,
                      destinations = points,
                      trip_date,
                      departure_time,
                      max_street_time = 'a',
                      max_trip_duration = max_trip_duration))

  testthat::expect_error(
    travel_time_matrix( r5_core,
                        origins = points,
                        destinations = points,
                        trip_date,
                        departure_time,
                        max_street_time = max_street_time,
                        max_trip_duration = 'a'))

  })
