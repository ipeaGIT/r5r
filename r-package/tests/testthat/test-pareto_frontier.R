# if running manually, please run the following line first:
# source("tests/testthat/setup.R")
context("Pareto frontier function")

# Behaviour covered by test-pareto_frontier.R
#
# 1. Basic wrapper smoke validation for invalid r5r_network.
# 2. Basic Pareto-specific input validation for invalid fare_structure and fare_cutoffs.
# 3. Errors when transit routing is requested outside the GTFS service date range.
# 4. Returns a data.table with expected core schema.
# 5. Returns expected fare frontier schema when fares are enabled.
# 6. Supports multiple percentiles.
# 7. fare_cutoffs constrain returned monetary_cost values.
# 8. WALK with zero fare cutoff returns only zero-cost alternatives.
# 9. Returned frontier rows are not dominated within each OD-percentile group.
# 10. output_dir writes files, returns the output path, and does not poison later calls.
# 11. Returns empty data.table when no OD pairs are reachable.
# 12. Restrictive max_trip_duration does not return over-limit trips.

testthat::skip_on_cran()

default_tester <- function(r5r_network = get("r5r_network", envir = parent.frame()),
                           origins = points[1:10, ],
                           destinations = points[1:10, ],
                           mode = "TRANSIT",
                           mode_egress = "WALK",
                           departure_datetime = get("departure_datetime", envir = parent.frame()),
                           time_window = 1L,
                           percentiles = 50L,
                           fare_structure = NULL,
                           fare_cutoffs = 0L,
                           max_walk_time = Inf,
                           max_bike_time = Inf,
                           max_car_time = Inf,
                           max_trip_duration = 120L,
                           walk_speed = 3.6,
                           bike_speed = 12,
                           max_rides = 3,
                           max_lts = 2,
                           n_threads = Inf,
                           verbose = FALSE,
                           output_dir = NULL) {

  pareto_frontier(
    r5r_network = r5r_network,
    origins = origins,
    destinations = destinations,
    mode = mode,
    mode_egress = mode_egress,
    departure_datetime = departure_datetime,
    time_window = time_window,
    percentiles = percentiles,
    fare_structure = fare_structure,
    fare_cutoffs = fare_cutoffs,
    max_walk_time = max_walk_time,
    max_bike_time = max_bike_time,
    max_car_time = max_car_time,
    max_trip_duration = max_trip_duration,
    walk_speed = walk_speed,
    bike_speed = bike_speed,
    max_rides = max_rides,
    max_lts = max_lts,
    n_threads = n_threads,
    verbose = verbose,
    output_dir = output_dir
  )
}

has_dominated_rows <- function(df) {
  if (nrow(df) <= 1) {
    return(FALSE)
  }

  vapply(
    seq_len(nrow(df)),
    function(i) {
      any(
        df$monetary_cost <= df$monetary_cost[i] &
          df$travel_time <= df$travel_time[i] &
          (
            df$monetary_cost < df$monetary_cost[i] |
              df$travel_time < df$travel_time[i]
          )
      )
    },
    logical(1)
  ) |>
    any()
}

fare_structure_path <- system.file(
  "extdata/poa/fares/fares_poa.zip",
  package = "r5r"
)

fare_structure <- r5r::read_fare_structure(fare_structure_path)


# minimal input filtering -------------------------------------------------

test_that("rejects invalid wrapper-level and Pareto-specific inputs", {
  expect_error(default_tester(r5r_network = "r5r_network"))

  expect_error(default_tester(fare_structure = "fare_structure"))
  expect_error(default_tester(fare_cutoffs = "5"))
  expect_error(default_tester(fare_cutoffs = -1))
  expect_error(default_tester(fare_cutoffs = NA))
  expect_error(default_tester(fare_cutoffs = c(0, 5, 5)))
})

test_that("using transit outside the GTFS service dates throws an error", {
  expect_error(
    default_tester(
      mode = "TRANSIT",
      departure_datetime = as.POSIXct(
        "13-05-2025 14:00:00",
        format = "%d-%m-%Y %H:%M:%S"
      )
    )
  )
})


# business behaviour ------------------------------------------------------

test_that("returns expected basic frontier output without fares", {
  pf <- default_tester(
    mode = "WALK",
    fare_structure = NULL,
    fare_cutoffs = 0L,
    max_trip_duration = 60L
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)

  expected_cols <- c("from_id", "to_id", "monetary_cost", "travel_time")
  expect_true(all(expected_cols %in% names(pf)))

  expect_type(pf$from_id, "character")
  expect_type(pf$to_id, "character")
  expect_true(is.numeric(pf$monetary_cost))
  expect_type(pf$travel_time, "integer")

  expect_true(all(pf$monetary_cost == 0))
  expect_true(all(pf$travel_time <= 60L, na.rm = TRUE))
})

test_that("returns expected fare frontier schema when fares are enabled", {
  pf <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)

  expected_cols <- c(
    "from_id",
    "to_id",
    "percentile",
    "monetary_cost",
    "travel_time"
  )

  expect_true(all(expected_cols %in% names(pf)))

  expect_type(pf$from_id, "character")
  expect_type(pf$to_id, "character")
  expect_type(pf$percentile, "integer")
  expect_true(is.numeric(pf$monetary_cost))
  expect_type(pf$travel_time, "integer")

  expect_true(all(pf$percentile == 50L))
  expect_true(all(pf$travel_time <= 60L, na.rm = TRUE))
  expect_true(all(pf$monetary_cost %in% c(0, 5, 10)))
})

test_that("supports multiple percentiles", {
  pf <- default_tester(
    mode = c("WALK", "TRANSIT"),
    percentiles = c(25, 50, 75),
    time_window = 30L,
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)
  expect_equal(sort(unique(pf$percentile)), c(25L, 50L, 75L))
})

test_that("fare_cutoffs constrain the monetary costs returned", {
  low_cutoff <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5),
    max_trip_duration = 60L
  )

  high_cutoff <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L
  )

  expect_true(all(low_cutoff$monetary_cost %in% c(0, 5)))
  expect_true(all(high_cutoff$monetary_cost %in% c(0, 5, 10)))
  expect_true(nrow(high_cutoff) >= nrow(low_cutoff))
})

test_that("no returned row is dominated within its OD pair and percentile", {
  pf <- default_tester(
    origins = points[1:10, ],
    destinations = points[1:10, ],
    mode = c("WALK", "TRANSIT"),
    percentiles = c(25, 50, 75),
    time_window = 30L,
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L
  )

  expect_true(nrow(pf) > 0)

  pf <- pf[!is.na(travel_time)]

  dominated <- pf[
    ,
    .(any_dominated = has_dominated_rows(.SD)),
    by = .(from_id, to_id, percentile)
  ]

  expect_false(any(dominated$any_dominated))
})

test_that("output_dir writes files, returns path, and does not affect later calls", {
  tmpdir <- tempfile("pareto_frontier_output")
  dir.create(tmpdir)

  returned_path <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L,
    output_dir = tmpdir
  )

  expect_equal(normalizePath(returned_path), normalizePath(tmpdir))

  output_files <- list.files(returned_path, full.names = TRUE)
  expect_true(length(output_files) > 0)

  pf_from_files <- data.table::rbindlist(
    lapply(output_files, data.table::fread),
    fill = TRUE
  )

  expect_s3_class(pf_from_files, "data.table")
  expect_true(nrow(pf_from_files) > 0)
  expect_true(all(c("from_id", "to_id", "travel_time") %in% names(pf_from_files)))

  pf <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10)
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)
})

test_that("returns empty data.table when no OD pairs are reachable", {
  far_destinations <- data.table::copy(points[1:5, ])
  far_destinations[
    ,
    `:=`(
      id = paste0(id, "_far"),
      lat = lat + 20,
      lon = lon + 20
    )
  ]

  pf <- default_tester(
    origins = points[1:5, ],
    destinations = far_destinations,
    mode = "WALK",
    fare_structure = NULL,
    fare_cutoffs = 0L,
    max_trip_duration = 1L,
    max_walk_time = 1L
  )

  expect_s3_class(pf, "data.table")
  expect_equal(nrow(pf), 0)
})

test_that("restrictive max_trip_duration does not return over-limit trips", {
  pf <- default_tester(
    origins = points[1:5, ],
    destinations = points[1:5, ],
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 1L
  )

  expect_s3_class(pf, "data.table")

  if (nrow(pf) > 0) {
    expect_true(all(is.na(pf$travel_time) | pf$travel_time <= 1L))
  }
})
