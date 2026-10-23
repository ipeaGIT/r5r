testthat::skip_on_cran()

test_that("transit egress keeps the destination connection and consistent cutoffs", {
  cases <- list(
    c("89a9012aedbffff", "89a9012997bffff"),
    c("89a90129c4fffff", "89a90128b4fffff")
  )
  for (pair in cases) {
    origin <- points[match(pair[1], points$id), ]
    destination <- points[match(pair[2], points$id), ]
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
    expect_true(min(high$total_duration) > 60 || nrow(low) > 0L)
    for (shortest in c(FALSE, TRUE)) {
      result <- if (shortest) route(90L, TRUE) else high
      expect_gt(nrow(result), 0L)
      last <- result[!duplicated(result$option, fromLast = TRUE), ]
      for (geometry in sf::st_geometry(last)) {
        endpoint <- tail(unclass(geometry), 1L)[1L, 1:2]
        expect_equal(unname(endpoint), c(destination$lon, destination$lat), tolerance = 1e-7)
      }
    }
  }
})
