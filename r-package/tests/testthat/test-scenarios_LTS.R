# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

# data.frame with new LTS info
network <- r5r::street_network_to_sf(r5r_network)
edge_lts <- data.frame(
  osm_id = network$edges$osm_id,
  lts = 1L
  )

# sf with new LTS
lts_lines <- readRDS(file.path(data_path, "poa_ls_lts.rds"))


meta_fun <- function(
    fun = r5r::travel_time_matrix,
    new_lts = NULL
    ){

  fun(
    r5r_network = r5r_network,
    origins = pois[1,],
    destinations = pois[13,],
    mode = 'BICYCLE',
    departure_datetime = Sys.time(),
    max_trip_duration = 60,
    new_lts = new_lts
  )
}



# car speeds with osm ids -------------------------------------------------------------------
test_that("success in increasing travel times", {

  # calculate travel times / access *before* changing road speeds
  ttm_pre <- meta_fun(r5r::travel_time_matrix)
  expanded_ttm_pre <- meta_fun(r5r::expanded_travel_time_matrix)
  det_pre <- meta_fun(r5r::detailed_itineraries)
  arrival_ttm_pre <- r5r::arrival_travel_time_matrix(
    r5r_network = r5r_network,
    origins = pois[1,],
    destinations = pois[13,],
    mode = 'car',
    arrival_datetime = Sys.time(),
    max_trip_duration = 60
  )
  # to do: r5r::accessibility

  # plot(det_pre['total_duration'])
  # mapview(network$edges) + network$vertices + det


  # calculate travel times / access *before* changing road speeds
  ttm_pos <- meta_fun(r5r::travel_time_matrix, new_lts = edge_lts)
  expanded_ttm_pos <- meta_fun(r5r::expanded_travel_time_matrix, new_lts = edge_lts)
  det_pos <- meta_fun(r5r::detailed_itineraries, new_lts = edge_lts)
  arrival_ttm_pos <- r5r::arrival_travel_time_matrix(
    r5r_network = r5r_network,
    origins = pois[1,],
    destinations = pois[13,],
    mode = 'BICYCLE',
    arrival_datetime = Sys.time(),
    max_trip_duration = 60,
    new_lts = edge_lts
  )


  #  mapview::mapview(det_pre) + det_pos

  # checking for longer travel times
  testthat::expect_true(ttm_pos$travel_time_p50 < ttm_pre$travel_time_p50)
  testthat::expect_true(all(expanded_ttm_pos$total_time < expanded_ttm_pre$total_time))
  # testthat::expect_true(arrival_ttm_pos$total_time < arrival_ttm_pre$total_time)
  testthat::expect_true(det_pos$total_duration < det_pre$total_duration)
  testthat::expect_true(det_pos$total_distance < det_pre$total_distance)

})


# LTS with spatial sf -------------------------------------------------------------------

test_that("errors in lts sf", {

  # wrong col names
  wrong_lts_lines1 <- lts_lines
  names(wrong_lts_lines1) <- c("my_line_id", "lts", "priority", "geometry")
  testthat::expect_error(meta_fun(new_lts = wrong_lts_lines1))

  # missing col
  wrong_lts_lines2 <- lts_lines
  wrong_lts_lines2$line_id <- NULL
  testthat::expect_error(meta_fun(new_lts = wrong_lts_lines2))

  # # Wrong geometry type
  # wrong_lts_lines3 <- lts_lines
  # wrong_lts_lines3 <- sf::st_cast(wrong_lts_lines3, to = 'MULTIPOINT')
  # testthat::expect_error(meta_fun(edge_lts = wrong_lts_lines3))

  # Wrong projection
  wrong_lts_lines4 <- sf::st_transform(lts_lines, 3857)
  testthat::expect_error(meta_fun(new_lts = wrong_lts_lines4))

})


test_that("errors due to incorrect input types", {

  testthat::expect_error(meta_fun(new_lts = 'banana'))

})





# test_that("message for missing OSM ids", {
#
#   mock_data <- data.frame(
#     osm_id = 123,
#     lts = 1L
#   )
#
#   testthat::expect_message(
#     meta_fun(new_lts = mock_data),
#     regexp = "Cannot find the following OSM IDs in network"
#   )
# })
