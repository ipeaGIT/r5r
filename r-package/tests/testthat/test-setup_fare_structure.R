# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tmpfile <- tempfile(fileext = ".csv")

gtfs_eptc <- gtfstools::read_gtfs(
  system.file("extdata/poa/poa_eptc.zip", package = "r5r"),
  encoding = "UTF-8"
)
gtfs_trensurb <- gtfstools::read_gtfs(
  system.file("extdata/poa/poa_trensurb.zip", package = "r5r"),
  encoding = "UTF-8"
)
gtfs <- gtfstools::merge_gtfs(gtfs_eptc, gtfs_trensurb)

tester <- function(r5r_network = get("r5r_network", envir = parent.frame()),
                   base_fare = 5, by = "MODE",
                   debug_path = NULL,
                   debug_info = NULL) {
  setup_fare_structure(
    r5r_network = r5r_network,
    base_fare = base_fare,
    by = by,
    debug_path = debug_path,
    debug_info = debug_info
  )
}

test_that("raises error due to incorrect input types", {
  expect_error(tester(unclass(r5r_network)))

  expect_error(tester(base_fare = "5"))
  expect_error(tester(base_fare = -1))
  expect_error(tester(base_fare = c(2, 3)))
  expect_error(tester(base_fare = NA))

  expect_error(tester(by = 1))
  expect_error(tester(by = c("MODE", "ROUTE")))
  expect_error(tester(by = "bad_by"))

  expect_error(tester(debug_path = 1))
  expect_error(tester(debug_path = tempfile(fileext = ".pdf")))

  expect_error(tester(debug_path = tmpfile, debug_info = c("MODE", "ROUTE")))
  expect_error(tester(debug_path = tmpfile, debug_info = "oie"))
})

test_that("debug_info cannot be non-NULL if debug_path is NULL", {
  expect_error(tester(debug_info = "MODE"))
})

test_that("debug_info defaults to 'ROUTE' if non-specified", {
  struc <- tester(debug_path = tmpfile)
  expect_equal(struc$debug_settings$trip_info, "ROUTE")
})

test_that("outputs a list with correct elements", {
  struc <- tester()

  expect_type(struc, "list")
  expect_identical(
    names(struc),
    c(
      "max_discounted_transfers",
      "transfer_time_allowance",
      "fare_cap",
      "fares_per_type",
      "fares_per_transfer",
      "fares_per_route",
      "debug_settings"
    )
  )

  expect_type(struc$max_discounted_transfers, "integer")
  expect_type(struc$transfer_time_allowance, "integer")
  expect_type(struc$fare_cap, "double")

  expect_s3_class(struc$fares_per_type, "data.table")
  expect_type(struc$fares_per_type$type, "character")
  expect_type(struc$fares_per_type$unlimited_transfers, "logical")
  expect_type(struc$fares_per_type$allow_same_route_transfer, "logical")
  expect_type(struc$fares_per_type$use_route_fare, "logical")
  expect_type(struc$fares_per_type$fare, "double")

  expect_s3_class(struc$fares_per_transfer, "data.table")
  expect_type(struc$fares_per_transfer$alight_leg, "character")
  expect_type(struc$fares_per_transfer$board_leg, "character")
  expect_type(struc$fares_per_transfer$fare, "double")

  expect_s3_class(struc$fares_per_route, "data.table")
  expect_type(struc$fares_per_route$agency_id, "character")
  expect_type(struc$fares_per_route$agency_name, "character")
  expect_type(struc$fares_per_route$route_id, "character")
  expect_type(struc$fares_per_route$route_short_name, "character")
  expect_type(struc$fares_per_route$route_long_name, "character")
  expect_type(struc$fares_per_route$mode, "character")
  expect_type(struc$fares_per_route$route_fare, "double")
  expect_type(struc$fares_per_route$fare_type, "character")

  expect_type(struc$debug_settings, "list")
  expect_type(struc$debug_settings$output_file, "character")
  expect_type(struc$debug_settings$trip_info, "character")
})

test_that("output includes all routes from the gtfs", {
  struc <- tester()
  expect_true(all(gtfs$routes$route_id %in% struc$fares_per_route$route_id))
})

test_that("uses the parameter 'by' to fill the structure", {
  struc <- tester(by = "AGENCY_ID")
  expect_true(all(gtfs$agency$agency_id %in% struc$fares_per_type$type))
  expect_true(
    all(gtfs$agency$agency_id %in% struc$fares_per_transfer$alight_leg)
  )
  expect_true(
    all(gtfs$agency$agency_id %in% struc$fares_per_transfer$board_leg)
  )

  struc <- tester(by = "AGENCY_NAME")
  expect_true(all(gtfs$agency$agency_name %in% struc$fares_per_type$type))
  expect_true(
    all(gtfs$agency$agency_name %in% struc$fares_per_transfer$alight_leg)
  )
  expect_true(
    all(gtfs$agency$agency_name %in% struc$fares_per_transfer$board_leg)
  )

  gtfs_modes <- gtfs$routes$route_type
  gtfs_modes <- ifelse(gtfs_modes == 3, "BUS", "RAIL")
  struc <- tester(by = "MODE")
  expect_true(all(gtfs_modes %in% struc$fares_per_type$type))
  expect_true(all(gtfs_modes %in% struc$fares_per_transfer$alight_leg))
  expect_true(all(gtfs_modes %in% struc$fares_per_transfer$board_leg))

  struc <- tester(by = "GENERIC")
  expect_true(struc$fares_per_type$type == "GENERIC")
  expect_true(struc$fares_per_transfer$alight_leg == "GENERIC")
  expect_true(struc$fares_per_transfer$board_leg == "GENERIC")
})

test_that("debug info is correctly set", {
  # debug disabled by default
  struc <- tester()
  expect_equal(struc$debug_settings$output_file, "")
  expect_equal(struc$debug_settings$trip_info, "MODE")

  # assigns trip_info as ROUTE when not specified
  struc <- tester(debug_path = tmpfile)
  expect_equal(struc$debug_settings$output_file, tmpfile)
  expect_equal(struc$debug_settings$trip_info, "ROUTE")

  # else assigns what is specified
  struc <- tester(debug_path = tmpfile, debug_info = "MODE_ROUTE")
  expect_equal(struc$debug_settings$output_file, tmpfile)
  expect_equal(struc$debug_settings$trip_info, "MODE_ROUTE")
})

test_that("fare_cap is infinite by default", {
  struc <- tester()
  expect_true(is.infinite(struc$fare_cap))
})
