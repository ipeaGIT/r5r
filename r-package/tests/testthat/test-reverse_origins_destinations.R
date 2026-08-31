# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

spo_points2 <- spo_points[2:3,]

npoints <- nrow(spo_points)
npoints2 <- nrow(spo_points2)




# travel_time_matrix -------------------------------------------------------------------

ttm_regular <- travel_time_matrix(
  spo_network,
  origins = spo_points2,
  destinations = spo_points,
  mode = "walk",
  max_trip_duration = 600
)

ttm_reverse <- travel_time_matrix(
  spo_network,
  origins = spo_points,
  destinations = spo_points2,
  mode = "walk",
  bike_speed = 100,
  max_trip_duration = 600
)

testthat::expect_true(length(unique(ttm_regular$from_id)) == npoints2)
testthat::expect_true(length(unique(ttm_regular$to_id)) == npoints)

testthat::expect_true(length(unique(ttm_reverse$from_id)) == npoints)
testthat::expect_true(length(unique(ttm_reverse$to_id)) == npoints2)



# arrival_travel_time_matrix -------------------------------------------------------------------

attm_regular <- arrival_travel_time_matrix(
  spo_network,
  origins = spo_points2,
  destinations = spo_points,
  mode = "walk",
  max_trip_duration = 600
)

attm_reverse <- arrival_travel_time_matrix(
  spo_network,
  origins = spo_points,
  destinations = spo_points2,
  mode = "walk",
  bike_speed = 100,
  max_trip_duration = 600
)

testthat::expect_true(length(unique(attm_regular$from_id)) == npoints2)
testthat::expect_true(length(unique(attm_regular$to_id)) == npoints)

testthat::expect_true(length(unique(attm_reverse$from_id)) == npoints)
testthat::expect_true(length(unique(attm_reverse$to_id)) == npoints2)




# expanded_travel_time_matrix -------------------------------------------------------------------

ettm_regular <- expanded_travel_time_matrix(
  spo_network,
  origins = spo_points2,
  destinations = spo_points,
  mode = "walk",
  bike_speed = 100,
  max_trip_duration = 600
)

ettm_reverse <- expanded_travel_time_matrix(
  spo_network,
  origins = spo_points,
  destinations = spo_points2,
  mode = "walk",
  bike_speed = 100,
  max_trip_duration = 600
)

testthat::expect_true(length(unique(ettm_regular$from_id)) == npoints2)
testthat::expect_true(length(unique(ettm_regular$to_id)) == npoints)

testthat::expect_true(length(unique(ettm_reverse$from_id)) == npoints)
testthat::expect_true(length(unique(ettm_reverse$to_id)) == npoints2)

