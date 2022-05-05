context("street_network_to_sf")

testthat::skip_on_cran()


# expected behavior
test_that("street_network_to_sf - expected behavior", {

  testthat::expect_type( street_network_to_sf(r5r_core), 'list')
})



# Expected errors
test_that("street_network_to_sf - expected errors", {

  # invalid input
  testthat::expect_error( street_network_to_sf('a') )
  })
