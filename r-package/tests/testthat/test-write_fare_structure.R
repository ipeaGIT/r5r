# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

struc <- setup_fare_structure(r5r_core, 5)
tmpfile <- tempfile(pattern = "fare_structure", fileext = ".zip")

tester <- function(fare_structure = struc, file_path = tmpfile) {
  write_fare_structure(fare_structure, file_path)
}

test_that("raises error due to incorrect input types", {
  expect_error(tester(file_path = tempfile(fileext = ".csv")))
})

test_that("return path invisibly", {
  expect_equal(tester(), tmpfile)
})

test_that("debug_info defaults to 'ROUTE' if non-specified", {
  new_tmpfile <- tempfile("fare_structure_test", fileext = ".zip")
  tester(file_path = new_tmpfile)
  expect_true(file.exists(new_tmpfile))
})

test_that("written structure is identical to original", {
  tester()
  written_struc <- read_fare_structure(tmpfile)
  expect_identical(struc, written_struc)
})

# clean cache
r5r::r5r_cache(delete_file = 'all')
