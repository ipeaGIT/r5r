# if running manually, please run the following line first:
# source("tests/testthat/setup.R")

testthat::skip_on_cran()

tester <- function(progress) set_progress(r5r_core, progress)

test_that("input is correct", {
  expect_error(tester("TRUE"))
  expect_error(tester(c(TRUE, TRUE)))
  expect_error(tester(NA))
})

test_that("progress argument works in routing functions", {
  assert_function <- function(f) {
    expr <- if (identical(f, travel_time_matrix)) {
      "f(r5r_core, pois[1:5], pois[1:5])"
    } else if (identical(f, expanded_travel_time_matrix)) {
      "f(r5r_core, pois[1:5], pois[1:5])"
    } else if (identical(f, detailed_itineraries)) {
      "f(r5r_core, pois[1:5], pois[5:1])"
    } else if (identical(f, pareto_frontier)) {
      "f(
        r5r_core,
        pois[1:5],
        pois[1:5],
        departure_datetime = departure_datetime,
        fare_structure = fare_structure,
        fare_cutoffs = c(0, 5, 10),
        max_trip_duration = 60
      )"
    } else if (identical(f, accessibility)) {
      "f(
        r5r_core,
        points[1:5],
        points[1:5],
        opportunities_colnames = \"schools\",
        cutoffs = 60
      )"
    }

    progress_expr <- sub("\\)$", ", progress = TRUE\\)", expr)
    non_progress_expr <- sub("\\)$", ", progress = FALSE\\)", expr)

    progress_regex <- "\\d+ out of \\d+ origins processed\\."

    progress_messages <- capture.output(
      res <- eval(parse(text = progress_expr)),
      type = "message"
    )
    expect_true(any(grepl(progress_regex, progress_messages)))

    non_progress_messages <- capture.output(
      res <- eval(parse(text = non_progress_expr)),
      type = "message"
    )
    expect_false(any(grepl(progress_regex, non_progress_messages)))
  }

  assert_function(travel_time_matrix)
  assert_function(expanded_travel_time_matrix)
  assert_function(detailed_itineraries)
  assert_function(pareto_frontier)
  assert_function(accessibility)
})
