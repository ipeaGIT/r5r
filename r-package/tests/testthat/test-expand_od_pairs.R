# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

test_that("raises errors when !all_to_all and nrow(origs/dests) is diff", {
  origins <- points[1:3]
  destinations <- points[6:7]

  expect_error(expand_od_pairs(origins, destinations, all_to_all = FALSE))
})

test_that("works correctly when nrow(origins/destinations) == 1", {
  origins <- as.data.frame(pois)[1, ]
  destinations <- as.data.frame(pois)

  expect_message(
    result <- expand_od_pairs(origins, destinations, all_to_all = FALSE)
  )
  expect_true(nrow(result$origins) == nrow(result$destinations))
  expect_true(all(result$origins$id == origins$id))
  expect_identical(result$destinations, destinations)

  origins <- as.data.frame(pois)
  destinations <- as.data.frame(pois)[1, ]

  expect_message(
    result <- expand_od_pairs(origins, destinations, all_to_all = FALSE)
  )
  expect_true(nrow(result$origins) == nrow(result$destinations))
  expect_true(all(result$destinations$id == destinations$id))
  expect_identical(result$origins, origins)
})

test_that("works correctly when all_to_all = TRUE", {
  origins <- as.data.frame(pois)[1:3, ]
  destinations <- as.data.frame(pois)[4:5, ]

  expect_silent(
    result <- expand_od_pairs(origins, destinations, all_to_all = TRUE)
  )
  expect_true(nrow(result$origins) == nrow(result$destinations))
  expect_identical(result$origins$id, origins$id[rep(1:3, each = 2)])
  expect_identical(result$destinations$id, destinations$id[rep(1:2, times = 3)])
})

test_that("works with sf objects", {
  origins_sf <- destinations_sf <- sf::st_as_sf(
    pois,
    coords = c("lon", "lat"),
    crs = 4326
  )
  origins_sf <- origins_sf[1:3, ]
  destinations_sf <- destinations_sf[4:5, ]

  expect_silent(
    result <- expand_od_pairs(origins_sf, destinations_sf, all_to_all = TRUE)
  )
  expect_true(nrow(result$origins) == nrow(result$destinations))
  expect_identical(result$origins$id, origins_sf$id[rep(1:3, each = 2)])
  expect_identical(
    result$destinations$id,
    destinations_sf$id[rep(1:2, times = 3)]
  )
})
