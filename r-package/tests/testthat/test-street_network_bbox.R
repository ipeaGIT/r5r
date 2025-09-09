context("Testing street_network_bbox")

testthat::skip_on_cran()

test_that("street_network_bbox returns an sf polygon by default", {
  bbox_poly <- street_network_bbox(r5r_network)

  # Check class and type
  expect_s3_class(bbox_poly, "sfc")
  expect_s3_class(bbox_poly, "sfc_POLYGON")
  expect_equal(
    as.character(sf::st_geometry_type(bbox_poly, by_geometry = FALSE)),
    "POLYGON"
  )

  # Check properties
  expect_equal(length(bbox_poly), 1)
  expect_equal(sf::st_crs(bbox_poly), sf::st_crs(4326))
})

test_that("street_network_bbox returns a bbox object when output = 'bbox'", {
  bbox_obj <- street_network_bbox(r5r_network, output = "bbox")

  # Check class and properties
  expect_s3_class(bbox_obj, "bbox")
  expect_true(is.numeric(bbox_obj))
  expect_length(bbox_obj, 4)
  expect_named(bbox_obj, c("xmin", "ymin", "xmax", "ymax"))
})

test_that("street_network_bbox returns a named vector when output = 'vector'", {
  bbox_vec <- street_network_bbox(r5r_network, output = "vector")

  # Check class and properties
  expect_true(is.numeric(bbox_vec))
  expect_false(inherits(bbox_vec, "bbox"))
  expect_length(bbox_vec, 4)
  expect_named(bbox_vec, c("xmin", "ymin", "xmax", "ymax"))
})

test_that("bbox and vector outputs are consistent in value and order", {
  bbox_obj <- street_network_bbox(r5r_network, output = "bbox")
  bbox_vec <- street_network_bbox(r5r_network, output = "vector")

  # Check that the numeric values are equal, ignoring names and attributes.
  expect_equal(as.numeric(bbox_obj), unclass(unname(bbox_vec)))

  # Check that the names are identical.
  expect_identical(names(bbox_obj), names(bbox_vec))
})

test_that("street_network_bbox gives deprecation warning for r5r_core", {
  # Check that the warning is thrown
  bbox_poly <- expect_warning(
    street_network_bbox(r5r_core = r5r_network),
    regexp = "The `r5r_core` argument is deprecated"
  )

  # Check that the function still returns the correct output
  expect_s3_class(bbox_poly, "sfc")
  expect_s3_class(bbox_poly, "sfc_POLYGON")
})

test_that("street_network_bbox throws an error for invalid output argument", {
  expect_error(
    street_network_bbox(r5r_network, output = "invalid_option"),
    regexp = "'arg' should be one of"
  )
})
