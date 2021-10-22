context("transit_network_to_sf")

testthat::skip_on_cran()


# setup_r5
path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path, verbose=FALSE, temp_dir = TRUE)


# expected behavior
test_that("transit_network_to_sf - expected behavior", {

  testthat::expect_type( transit_network_to_sf(r5r_core), 'list')
})



# Expected errors
test_that("transit_network_to_sf - expected errors", {

  # invalid input
  testthat::expect_error( transit_network_to_sf('a') )
})

stop_r5(r5r_core)
