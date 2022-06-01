# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")

tester <- function(file_path = path, encoding = "UTF-8") {
  read_fare_structure(file_path, encoding)
}

test_that("raises error due to incorrect input types", {
  expect_error(tester(tempfile(fileext = ".csv")))
  expect_error(tester("DESCRIPTION"))
  expect_error(tester(encoding = as.factor("UTF-8")))
  expect_error(tester(encoding = c("UTF-8", "UTF-8")))
  expect_error(tester(encoding = "oie"))
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
      "fares_per_mode",
      "fares_per_transfer",
      "fares_per_route",
      "debug_settings"
    )
  )

  expect_type(struc$max_discounted_transfers, "integer")
  expect_type(struc$transfer_time_allowance, "integer")
  expect_type(struc$fare_cap, "double")

  expect_s3_class(struc$fares_per_mode, "data.table")
  expect_type(struc$fares_per_mode$mode, "character")
  expect_type(struc$fares_per_mode$unlimited_transfers, "logical")
  expect_type(struc$fares_per_mode$allow_same_route_transfer, "logical")
  expect_type(struc$fares_per_mode$use_route_fare, "logical")
  expect_type(struc$fares_per_mode$fare, "double")

  expect_s3_class(struc$fares_per_transfer, "data.table")
  expect_type(struc$fares_per_transfer$first_leg, "character")
  expect_type(struc$fares_per_transfer$second_leg, "character")
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

test_that("encoding argument works", {
  utf8_struc <- tester()
  latin1_struc <- tester(encoding = "Latin-1")
  expect_false(identical(utf8_struc, latin1_struc))
  expect_false(
    identical(
      utf8_struc$fares_per_route$agency_name,
      latin1_struc$fares_per_route$agency_name
    )
  )
  expect_false(
    identical(
      utf8_struc$fares_per_route$route_long_name,
      latin1_struc$fares_per_route$route_long_name
    )
  )
})
