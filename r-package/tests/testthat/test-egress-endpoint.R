testthat::skip_on_cran()

test_that("directed partial check rejects wrong ends and loop detours", {
  edge <- rbind(c(0, 0), c(2, 0), c(2, 2))
  correct <- rbind(c(-1, 0), c(0, 0), c(2, 0), c(2, 1), c(3, 1))
  expect_true(egress_follows_directed_partial(correct, 4L, edge))
  expect_true(egress_follows_directed_partial(correct, 4L, rbind(edge[1L, ], edge)))
  wrong <- rbind(c(2, 2), c(2, 1), c(3, 1))
  expect_false(egress_follows_directed_partial(wrong, 2L, edge))
  loop <- rbind(c(0, 0), c(2, 0), c(2, 2), c(0, 0))
  short <- rbind(c(0, 0), c(1, 1), c(1, 2))
  expect_true(egress_follows_directed_partial(short, 2L, loop[4:1, ]))
  detour <- rbind(loop[1:3, ], c(1, 1), c(1, 2))
  expect_false(egress_follows_directed_partial(detour, 4L, loop[4:1, ]))
  endpoint <- rbind(c(0, 0), c(2, 0), c(2, 2), c(3, 2))
  expect_true(egress_follows_directed_partial(endpoint, 3L, edge))
})

test_that("transit egress keeps the destination connection and consistent cutoffs", {
  edges <- street_network_to_sf(r5r_network)$edges
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
      shortest_path = shortest, n_threads = 1L, progress = FALSE, osm_link_ids = TRUE
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
      limit <- as.integer(floor(min(result$total_duration)) + 1L)
      expect_lt(limit, 90L)
      lower <- route(limit, shortest)
      expect_gt(nrow(lower), 0L)
      if (nrow(lower) > 0L) expect_equal(min(lower$total_duration), min(result$total_duration))
      transit_options <- unique(result$option[!result$mode %in% c("WALK", "BICYCLE", "CAR")])
      expect_gt(length(transit_options), 0L)
      transit <- result[result$option %in% transit_options, ]
      last <- transit[!duplicated(transit$option, fromLast = TRUE), ]
      totals <- data.table::as.data.table(result)[,
        .(difference = abs(sum(segment_duration + wait) - total_duration[1L]), tolerance = .N * .1),
        by = option]
      expect_true(all(totals$difference <= totals$tolerance + 1e-8))
      expect_true(all(lower$total_duration <= limit + .05))
      for (i in seq_len(nrow(last))) {
        geometry <- sf::st_geometry(last)[[i]]
        coordinates <- unclass(geometry)[, 1:2, drop = FALSE]
        endpoint <- coordinates[nrow(coordinates), ]
        expect_equal(unname(endpoint), c(destination$lon, destination$lat), tolerance = 1e-7)
        # Snap/end coordinates are appended by construction. Also verify that the
        # preceding partial follows the exported edge in its travel direction.
        snap_index <- if (max(abs(c(destination$lon - snap$snap_lon,
                                   destination$lat - snap$snap_lat))) < 1e-10) nrow(coordinates) else nrow(coordinates) - 1L
        expect_equal(unname(coordinates[snap_index, ]), c(snap$snap_lon, snap$snap_lat), tolerance = 1e-7)
        ids <- as.integer(strsplit(gsub("\\[|\\]", "", last$edge_id_list[i]), ",", fixed = TRUE)[[1L]])
        expect_gt(length(ids), 0L)
        expect_false(anyNA(ids))
        if (!length(ids) || anyNA(ids)) next
        edge_index <- match(tail(ids, 1L), edges$edge_index)
        expect_false(is.na(edge_index))
        expect_gte(snap_index, 2L)
        if (length(ids) && !is.na(edge_index)) {
          edge <- unclass(sf::st_geometry(edges)[[edge_index]])
          expect_true(egress_follows_directed_partial(coordinates, snap_index, edge))
        }
      }
    }
  }
})


test_that("corrected FastRaptor egress agrees in shared and paired searches", {
  origins <- points[match(c("89a9012aedbffff", "89a90129c4fffff"), points$id), ]
  destinations <- points[match(c("89a9012997bffff", "89a90128b4fffff"), points$id), ]
  route <- function(origins, destinations, shared) detailed_itineraries(
    r5r_network, origins, destinations, mode = c("WALK", "TRANSIT"),
    departure_datetime = as.POSIXct("2019-05-13 14:00:00", tz = "America/Sao_Paulo"),
    time_window = 10L, max_walk_time = 53L, max_trip_duration = 90L,
    shortest_path = TRUE, all_to_all = shared, n_threads = 2L,
    progress = FALSE, osm_link_ids = TRUE
  )
  shared <- route(origins, destinations, TRUE)
  paired <- route(origins[rep(1:2, each = 2L), ], destinations[rep(1:2, times = 2L), ], FALSE)
  expect_gt(nrow(shared), 0L)
  expect_true(all(origins$id %in% shared$from_id))
  expect_true(all(destinations$id %in% shared$to_id))
  expect_equal(shared, paired)
})
