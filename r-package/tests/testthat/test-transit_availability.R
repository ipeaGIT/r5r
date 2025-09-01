# tests/testthat/test-transit_availability.R

# Individual skip is still good practice, though setup.R has a global one.
testthat::skip_on_cran()

context("transit_availability")

# --- Expected Behavior ---

test_that("transit_availability works with a vector of character dates", {
  dates_char <- c("2019-05-13", "2019-05-19") # Weekday and Sunday
  result <- transit_availability(r5r_network, dates = dates_char)

  # Check output type and structure
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_named(
    result,
    c("date", "total_services", "active_services", "pct_active")
  )
  expect_s3_class(result$date, "Date")

  # Check values
  expect_equal(result$active_services, c(116L, 1L))
})

test_that("transit_availability works with a vector of Date objects", {
  dates_obj <- as.Date(c("2019-05-13", "2019-05-19"))
  result <- transit_availability(r5r_network, dates = dates_obj)

  # Check structure and values
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 2)
  expect_equal(result$date, dates_obj)
  expect_equal(result$active_services, c(116L, 1L))
})

test_that("transit_availability works with a start_date/end_date range", {
  start <- "2019-05-18" # Saturday
  end <- "2019-05-20" # Monday
  result <- transit_availability(
    r5r_network,
    start_date = start,
    end_date = end
  )

  # Check structure and values
  expect_s3_class(result, "data.table")
  expect_equal(nrow(result), 3)
  expect_equal(result$date, seq(as.Date(start), as.Date(end), by = "day"))
  # Values for Sat, Sun, Mon
  expect_equal(result$active_services, c(1L, 1L, 116L))
})

test_that("transit_availability returns 0 active services for dates outside the GTFS calendar", {
  result <- transit_availability(r5r_network, dates = "2025-01-01")

  expect_equal(result$active_services, 0L)
  expect_equal(result$pct_active, 0.0)
})

# --- Expected Errors ---

test_that("transit_availability throws errors for invalid arguments", {
  consolidated_error_msg <- "Incorrect date arguments provided."

  # Test cases for consolidated date argument logic
  expect_error(transit_availability(r5r_network), consolidated_error_msg)
  expect_error(
    transit_availability(
      r5r_network,
      dates = "2019-01-01",
      start_date = "2019-01-01"
    ),
    consolidated_error_msg
  )
  expect_error(
    transit_availability(r5r_network, start_date = "2019-01-01"),
    consolidated_error_msg
  )

  # --- More robust tests for date FORMAT and VALIDITY ---

  # Test for invalid format (slashes instead of dashes)
  expect_error(
    transit_availability(r5r_network, dates = "2019/05/13"),
    "Invalid date format found"
  )

  # Test for invalid format (day-month-year)
  expect_error(
    transit_availability(r5r_network, dates = "13-05-2019"),
    "Invalid date format found"
  )

  # Test for a logically impossible date (correct format but invalid value)
  # This test will now pass reliably.
  expect_error(
    transit_availability(r5r_network, dates = "2025-02-29"), # 2025 is not a leap year
    "logically invalid"
  )

  # Test for start date after end date
  expect_error(
    transit_availability(
      r5r_network,
      start_date = "2019-05-20",
      end_date = "2019-05-18"
    ),
    "`start_date` must be before or the same as `end_date`."
  )
})
