context("transit_network_to_sf")

testthat::skip_on_cran()

# expected behavior
test_that("transit_network_to_sf - expected behavior", {

  testthat::expect_type( transit_network_to_sf(r5r_network), 'list')
})



# Expected errors
test_that("transit_network_to_sf - expected errors", {

  # invalid input
  testthat::expect_error( transit_network_to_sf('a') )
})

