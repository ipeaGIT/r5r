# if running manually, please run the following line first:
# source("tests/testthat/setup.R")
context("Pareto frontier function")

# Behaviour covered by test-pareto_frontier.R
#
# 1. Rejects invalid r5r_network objects.
# 2. Rejects invalid origins/destinations inputs, including non-data.frame inputs,
#    non-POINT sf geometries, and missing or wrongly typed lat/lon columns.
# 3. Warns when origin/destination id columns are numeric and must be coerced to character.
# 4. Rejects invalid transport modes, ambiguous direct modes, and unsupported egress modes.
# 5. Rejects invalid departure_datetime values, including strings, numerics, and length > 1 inputs.
# 6. Rejects invalid time_window values.
# 7. Rejects invalid max_walk_time, max_bike_time, max_car_time, and max_trip_duration values.
# 8. Rejects invalid walk_speed and bike_speed values.
# 9. Rejects invalid percentile inputs, including out-of-range, duplicated, missing, and too many values.
# 10. Rejects invalid fare_structure and fare_cutoffs inputs.
# 12. Errors when transit routing is requested outside the GTFS service date range.
# 13. Returns a data.table for both data.frame and sf origin/destination inputs.
# 14. Returns expected core schema columns: from_id, to_id, and travel_time.
# 15. Returns correctly typed core output columns.
# 16. Ensures returned travel times do not exceed max_trip_duration.
# 17. Ensures default zero-cost frontier output has no more rows than the OD pair count.
# 18. When fares are enabled, returns expected fare frontier columns:
#     from_id, to_id, percentile, monetary_cost, and travel_time.
# 19. Supports multiple percentiles and returns percentile-specific frontier rows.
# 20. Ensures fare_cutoffs constrain the monetary_cost values returned.
# 21. Ensures a zero fare cutoff with WALK returns only zero-cost alternatives.
# 22. Checks Pareto monotonicity within each origin-destination-percentile group.
# 23. Checks that no returned frontier row is dominated by another row in the same group.
# 24. Verifies output_dir makes the function write result files and return the output path.
# 25. Verifies a normal data.table result is still returned after a previous output_dir call.
# 26. Returns an empty data.table when no OD pairs are reachable within the constraints.
# 27. Ensures very restrictive max_trip_duration does not return over-limit trips.

# skips tests on CRAN since they require a specific version of java
testthat::skip_on_cran()

default_tester <- function(r5r_network = get("r5r_network", envir = parent.frame()),
                           origins = points[1:10,],
                           destinations = points[1:10,],
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

is_pareto_frontier <- function(df) {
  df <- df[order(monetary_cost, -travel_time)]

  if (nrow(df) <= 1) {
    return(TRUE)
  }

  costs_increase <- all(diff(df$monetary_cost) > 0)
  times_decrease <- all(diff(df$travel_time) < 0)

  costs_increase && times_decrease
}

# load fare calculator object
fare_structure_path <- system.file(
  "extdata/poa/fares/fares_poa.zip",
  package = "r5r"
)
fare_structure <- r5r::read_fare_structure(fare_structure_path)

# errors and warnings -----------------------------------------------------

test_that("adequately raises errors", {

  # wrong r5r_network
  expect_error(default_tester(r5r_network = "r5r_network"))

  # wrong origins/destinations object type
  multipoint_origins <- sf::st_cast(
    sf::st_as_sf(points[1:2,], coords = c("lon", "lat"), crs = 4326),
    "MULTIPOINT"
  )
  multipoint_destinations <- multipoint_origins

  list_origins <- list(
    id = c("1", "2"),
    lat = c(-30.02756, -30.02329),
    long = c(-51.22781, -51.21886)
  )
  list_destinations <- list_origins

  expect_error(default_tester(origins = multipoint_origins))
  expect_error(default_tester(destinations = multipoint_destinations))
  expect_error(default_tester(origins = list_origins))
  expect_error(default_tester(destinations = list_destinations))
  expect_error(default_tester(origins = "origins"))
  expect_error(default_tester(destinations = "destinations"))

  # wrong origins/destinations column types
  origins <- destinations <- points[1:2,]

  origins_char_lat <- data.frame(
    id = origins$id,
    lat = as.character(origins$lat),
    lon = origins$lon
  )
  origins_char_lon <- data.frame(
    id = origins$id,
    lat = origins$lat,
    lon = as.character(origins$lon)
  )
  destinations_char_lat <- data.frame(
    id = destinations$id,
    lat = as.character(destinations$lat),
    lon = destinations$lon
  )
  destinations_char_lon <- data.frame(
    id = destinations$id,
    lat = destinations$lat,
    lon = as.character(destinations$lon)
  )

  expect_error(default_tester(origins = origins_char_lat))
  expect_error(default_tester(origins = origins_char_lon))
  expect_error(default_tester(destinations = destinations_char_lat))
  expect_error(default_tester(destinations = destinations_char_lon))

  # mode errors
  expect_error(default_tester(mode = "pogoball"))
  expect_error(default_tester(mode = c("WALK", "CAR")))
  expect_error(default_tester(mode_egress = "CAR_PARK"))

  # date errors
  numeric_datetime <- as.numeric(departure_datetime)

  expect_error(default_tester(departure_datetime = "13-05-2019 14:00:00"))
  expect_error(default_tester(departure_datetime = numeric_datetime))
  expect_error(default_tester(departure_datetime = rep(departure_datetime, 2)))

  # time window
  expect_error(default_tester(time_window = "1"))
  expect_error(default_tester(time_window = 0))
  expect_error(default_tester(time_window = Inf))

  # max street/trip times
  expect_error(default_tester(max_walk_time = "1000"))
  expect_error(default_tester(max_walk_time = NULL))
  expect_error(default_tester(max_walk_time = 0))

  expect_error(default_tester(max_bike_time = "1000"))
  expect_error(default_tester(max_bike_time = NULL))
  expect_error(default_tester(max_bike_time = 0))

  expect_error(default_tester(max_car_time = "1000"))
  expect_error(default_tester(max_car_time = NULL))
  expect_error(default_tester(max_car_time = 0))

  expect_error(default_tester(max_trip_duration = "120"))
  expect_error(default_tester(max_trip_duration = NULL))
  expect_error(default_tester(max_trip_duration = 0))
  expect_error(default_tester(max_trip_duration = Inf))

  # speeds
  expect_error(default_tester(walk_speed = "3.6"))
  expect_error(default_tester(walk_speed = 0))
  expect_error(default_tester(walk_speed = Inf))

  expect_error(default_tester(bike_speed = "12"))
  expect_error(default_tester(bike_speed = 0))
  expect_error(default_tester(bike_speed = Inf))

  # percentiles
  expect_error(default_tester(percentiles = .3))
  expect_error(default_tester(percentiles = 0))
  expect_error(default_tester(percentiles = 100))
  expect_error(default_tester(percentiles = 1:6))
  expect_error(default_tester(percentiles = c(50, 50)))
  expect_error(default_tester(percentiles = NA))

  # fare inputs
  expect_error(default_tester(fare_structure = "fare_structure"))
  expect_error(default_tester(fare_cutoffs = "5"))
  expect_error(default_tester(fare_cutoffs = -1))
  expect_error(default_tester(fare_cutoffs = NA))
  expect_error(default_tester(fare_cutoffs = c(0, 5, 5)))

  # other routing settings
  expect_error(default_tester(max_rides = "3"))
  expect_error(default_tester(max_rides = 0))
  expect_error(default_tester(max_rides = Inf))

  expect_error(default_tester(max_lts = "2"))
  expect_error(default_tester(max_lts = 0))
  expect_error(default_tester(max_lts = 5))

  expect_error(default_tester(n_threads = "1"))
  expect_error(default_tester(n_threads = 0))

  expect_error(default_tester(output_dir = 1))
  expect_error(default_tester(output_dir = tempfile("missing_output_dir")))
})

test_that("adequately raises warnings - needs java", {

  origins <- destinations <- points[1:2,]

  origins_numeric_id <- data.frame(
    id = 1:2,
    lat = origins$lat,
    lon = origins$lon
  )
  destinations_numeric_id <- data.frame(
    id = 1:2,
    lat = destinations$lat,
    lon = destinations$lon
  )

  expect_warning(default_tester(origins = origins_numeric_id))
  expect_warning(default_tester(destinations = destinations_numeric_id))
})

test_that("using transit outside the gtfs dates throws an error", {
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

# adequate behaviour ------------------------------------------------------

test_that("output is correct", {

  origins_sf <- destinations_sf <- sf::st_as_sf(
    points[1:10,],
    coords = c("lon", "lat"),
    crs = 4326
  )

  result_df_input <- default_tester()
  result_sf_input <- default_tester(origins = origins_sf, destinations = destinations_sf)

  expect_s3_class(result_df_input, "data.table")
  expect_s3_class(result_sf_input, "data.table")

  expect_true(all(c("from_id", "to_id", "travel_time") %in% names(result_df_input)))

  expect_type(result_df_input$from_id, "character")
  expect_type(result_df_input$to_id, "character")
  expect_type(result_df_input$travel_time, "integer")

  # old test: travel times lower than max_trip_duration
  max_trip_duration <- 60L

  df <- default_tester(
    origins = points[1:10,],
    destinations = points[1:10,],
    max_trip_duration = max_trip_duration
  )

  expect_true(max(df$travel_time, na.rm = TRUE) <= max_trip_duration)

  # old test: row count sanity for default zero-cost frontier
  df <- default_tester(
    origins = points[1:10,],
    destinations = points[1:10,],
    max_trip_duration = 300L
  )

  expect_true(nrow(df) <= nrow(points[1:10,]) * nrow(points[1:10,]))
})

test_that("output has expected schema when fares are enabled", {
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

test_that("multiple percentiles add percentile-specific frontier rows", {
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

test_that("fare_cutoffs controls the monetary costs returned", {
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

test_that("zero fare cutoff returns only zero-cost alternatives", {
  pf <- default_tester(
    mode = "WALK",
    fare_structure = NULL,
    fare_cutoffs = 0L,
    max_trip_duration = 60L
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)
  expect_true(all(pf$monetary_cost == 0))
  expect_true(all(pf$travel_time <= 60L, na.rm = TRUE))
})

test_that("frontier is monotonic within each OD pair and percentile", {
  pf <- default_tester(
    origins = points[1:10,],
    destinations = points[1:10,],
    mode = c("WALK", "TRANSIT"),
    percentiles = c(25, 50, 75),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    time_window = 30L,
    max_trip_duration = 60L
  )

  expect_true(nrow(pf) > 0)

  pf <- pf[!is.na(travel_time)]

  pf_groups <- pf[
    ,
    .(frontier_ok = is_pareto_frontier(.SD)),
    by = .(from_id, to_id, percentile)
  ]

  expect_true(all(pf_groups$frontier_ok))
})

test_that("no returned row is dominated within its OD pair and percentile", {
  pf <- default_tester(
    origins = points[1:10,],
    destinations = points[1:10,],
    mode = c("WALK", "TRANSIT"),
    percentiles = 50L,
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10),
    max_trip_duration = 60L
  )

  pf <- pf[!is.na(travel_time)]

  dominated <- pf[
    ,
    {
      d <- .SD

      is_dominated <- vapply(
        seq_len(nrow(d)),
        function(i) {
          any(
            d$monetary_cost <= d$monetary_cost[i] &
              d$travel_time <= d$travel_time[i] &
              (
                d$monetary_cost < d$monetary_cost[i] |
                  d$travel_time < d$travel_time[i]
              )
          )
        },
        logical(1)
      )

      .(any_dominated = any(is_dominated))
    },
    by = .(from_id, to_id, percentile)
  ]

  expect_false(any(dominated$any_dominated))
})

test_that("output is saved to dir and function returns path with output_dir", {
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
})

test_that("returns data.table after a previous call saved to output_dir", {
  tmpdir <- tempfile("pareto_frontier_output")
  dir.create(tmpdir)

  invisible(
    default_tester(
      mode = c("WALK", "TRANSIT"),
      fare_structure = fare_structure,
      fare_cutoffs = c(0, 5, 10),
      output_dir = tmpdir
    )
  )

  pf <- default_tester(
    mode = c("WALK", "TRANSIT"),
    fare_structure = fare_structure,
    fare_cutoffs = c(0, 5, 10)
  )

  expect_s3_class(pf, "data.table")
  expect_true(nrow(pf) > 0)
})

test_that("returns empty data.table when no OD pairs are reachable within constraints", {
  far_destinations <- data.table::copy(points[1:5,])
  far_destinations[, `:=`(
    id = paste0(id, "_far"),
    lat = lat + 20,
    lon = lon + 20
  )]

  pf <- default_tester(
    origins = points[1:5,],
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

test_that("very restrictive max_trip_duration does not return over-limit trips", {
  pf <- default_tester(
    origins = points[1:5,],
    destinations = points[1:5,],
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
