testthat::skip_on_cran()

test_that("transit egress keeps the destination connection and consistent cutoffs", {
  cases <- list(
    c("89a9012aedbffff", "89a9012997bffff"),
    c("89a90129c4fffff", "89a90128b4fffff")
  )
  for (pair in cases) {
    origin <- points[match(pair[1], points$id), ]
    destination <- points[match(pair[2], points$id), ]
    snap <- find_snap(r5r_network, destination, mode = "WALK")
    expect_true(snap$found)
    route <- function(limit, shortest = FALSE) detailed_itineraries(
      r5r_network, origin, destination,
      mode = c("WALK", "TRANSIT"),
      departure_datetime = as.POSIXct("2019-05-13 14:00:00", tz = "America/Sao_Paulo"),
      time_window = 10L, max_walk_time = 53L, max_trip_duration = limit,
      shortest_path = shortest, n_threads = 1L, progress = FALSE
    )
    low <- route(60L)
    high <- route(90L)
    expect_gt(nrow(high), 0L)
    if (nrow(high) == 0L) next
    for (shortest in c(FALSE, TRUE)) {
      result <- if (shortest) route(90L, TRUE) else high
      expect_gt(nrow(result), 0L)
      if (nrow(result) == 0L) next
      if (min(result$total_duration) <= 60 - 0.1) {
        lower <- if (shortest) route(60L, TRUE) else low
        expect_gt(nrow(lower), 0L)
        if (nrow(lower) > 0L) expect_equal(min(lower$total_duration), min(result$total_duration))
      }
      transit_options <- unique(result$option[!result$mode %in% c("WALK", "BICYCLE", "CAR")])
      expect_gt(length(transit_options), 0L)
      transit <- result[result$option %in% transit_options, ]
      last <- transit[!duplicated(transit$option, fromLast = TRUE), ]
      for (geometry in sf::st_geometry(last)) {
        coordinates <- unclass(geometry)[, 1:2, drop = FALSE]
        endpoint <- coordinates[nrow(coordinates), ]
        expect_equal(unname(endpoint), c(destination$lon, destination$lat), tolerance = 1e-7)
        # The requested endpoint is appended by construction; also check the independently
        # snapped street endpoint immediately before the off-street connection.
        snap_index <- if (max(abs(c(destination$lon - snap$snap_lon,
                                   destination$lat - snap$snap_lat))) < 1e-10) nrow(coordinates) else nrow(coordinates) - 1L
        expect_equal(unname(coordinates[snap_index, ]), c(snap$snap_lon, snap$snap_lat), tolerance = 1e-7)
      }
    }
  }
})
