# Run only in GitHub Actions, after installing the intended package in its own library.
baseline <- "--baseline" %in% commandArgs(TRUE)
baseline_library <- Sys.getenv("EGRESS_BASELINE_LIB")
if (nzchar(baseline_library)) .libPaths(c(baseline_library, .libPaths()))
options(java.parameters = "-Xmx4G")
library(r5r)
library(data.table)
cat("Package:", as.character(packageVersion("r5r")), find.package("r5r"), "\n")
data <- system.file("extdata/poa", package = "r5r")
work <- tempfile("egress-network-")
dir.create(work)
stopifnot(all(file.copy(list.files(data, "\\.(pbf|zip|tif)$", full.names = TRUE), work)))
network <- build_network(work, verbose = FALSE)
points <- fread(file.path(data, "poa_hexgrid.csv"))
runtime <- rJava::.jcall("java/lang/Runtime", "Ljava/lang/Runtime;", "getRuntime")
heap <- rJava::.jcall(runtime, "J", "maxMemory")
cat("Actual Java heap:", heap, "\n")
stopifnot(heap == 4 * 1024^3)
loaded_jar <- function(name) {
  cls <- rJava::.jfindClass(name)
  pd <- rJava::.jcall(cls, "Ljava/security/ProtectionDomain;", "getProtectionDomain")
  cs <- rJava::.jcall(pd, "Ljava/security/CodeSource;", "getCodeSource")
  url <- rJava::.jcall(cs, "Ljava/net/URL;", "getLocation")
  URLdecode(sub("^file:", "", rJava::.jcall(url, "S", "toExternalForm")))
}
jars <- c(bridge = loaded_jar("org/ipea/r5r/R5RCore"),
          r5 = loaded_jar("com/conveyal/r5/transit/TransportNetwork"))
print(jars)
sha256 <- function(path) {
  output <- system2("sha256sum", shQuote(normalizePath(path, mustWork = TRUE)), stdout = TRUE)
  stopifnot(is.null(attr(output, "status")), length(output) == 1L)
  sub(" .*", "", output)
}
expected_bridge <- Sys.getenv("EGRESS_EXPECTED_BRIDGE")
stopifnot(nzchar(expected_bridge))
loaded_sha <- sha256(jars[["bridge"]])
expected_sha <- sha256(expected_bridge)
cat("Bridge SHA256 loaded:", loaded_sha, "expected:", expected_sha, "\n")
stopifnot(identical(loaded_sha, expected_sha))
route <- function(origins, destinations, limit, shortest = FALSE, shared = FALSE) detailed_itineraries(
  network, origins, destinations, mode = c("WALK", "TRANSIT"),
  all_to_all = shared,
  departure_datetime = as.POSIXct("2019-05-13 14:00:00", tz = "America/Sao_Paulo"),
  time_window = 10L, max_walk_time = 53L, max_trip_duration = limit,
  shortest_path = shortest, n_threads = 2L, progress = FALSE, osm_link_ids = TRUE)
if (!baseline) {
  source("r-package/tests/testthat/helper-egress.R")
  edges <- street_network_to_sf(network)$edges
}
known <- data.table(
  from_id = c("89a9012aedbffff", "89a90129c4fffff"),
  to_id = c("89a9012997bffff", "89a90128b4fffff"))
baseline_endpoint_misses <- 0L
for (shortest in c(FALSE, TRUE)) for (i in seq_len(nrow(known))) {
  origin <- points[match(known$from_id[i], id)]
  destination <- points[match(known$to_id[i], id)]
  low <- route(origin, destination, 60L, shortest)
  high <- route(origin, destination, 90L, shortest)
  stopifnot(nrow(high) > 0L)
  cat("KNOWN", i, "shortest", shortest, "segments60", nrow(low), "segments90", nrow(high),
      "minimum60", if (nrow(low)) min(low$total_duration) else NA_real_,
      "minimum90", min(high$total_duration), "\n")
  transit_options <- unique(high$option[!high$mode %in% c("WALK", "BICYCLE", "CAR")])
  stopifnot(length(transit_options) > 0L)
  transit <- high[high$option %in% transit_options, ]
  last <- transit[!duplicated(transit$option, fromLast = TRUE), ]
  if (baseline) {
    misses <- sum(vapply(sf::st_geometry(last), function(geometry) {
      coordinates <- unclass(geometry)[, 1:2, drop = FALSE]
      max(abs(tail(coordinates, 1L) - c(destination$lon, destination$lat))) > 1e-7
    }, logical(1)))
    baseline_endpoint_misses <- baseline_endpoint_misses + misses
    cat("BASELINE_ENDPOINT_MISSES", i, "shortest", shortest, "misses", misses, "of", nrow(last), "\n")
    next
  }
  if (min(high$total_duration) <= 60 - 0.1) {
    stopifnot(nrow(low) > 0L, min(low$total_duration) == min(high$total_duration))
  }
  limit <- as.integer(floor(min(high$total_duration)) + 1L)
  stopifnot(limit < 90L)
  lower <- route(origin, destination, limit, shortest)
  stopifnot(nrow(lower) > 0L, min(lower$total_duration) == min(high$total_duration))
  cat("KNOWN_CUTOFF", i, "shortest", shortest, "limit", limit,
      "minimum", min(lower$total_duration), "\n")
  snap <- find_snap(network, destination, mode = "WALK")
  stopifnot(snap$found)
  for (j in seq_len(nrow(last))) {
    coordinates <- unclass(sf::st_geometry(last)[[j]])[, 1:2, drop = FALSE]
    stopifnot(max(abs(coordinates[nrow(coordinates), ] - c(destination$lon, destination$lat))) < 1e-7)
    snap_index <- if (max(abs(c(destination$lon - snap$snap_lon,
                               destination$lat - snap$snap_lat))) < 1e-10) nrow(coordinates) else nrow(coordinates) - 1L
    stopifnot(snap_index >= 2L,
              max(abs(coordinates[snap_index, ] - c(snap$snap_lon, snap$snap_lat))) < 1e-7)
    ids <- as.integer(strsplit(gsub("\\[|\\]", "", last$edge_id_list[j]), ",", fixed = TRUE)[[1L]])
    stopifnot(length(ids) > 0L, !anyNA(ids))
    edge_index <- match(tail(ids, 1L), edges$edge_index)
    stopifnot(!is.na(edge_index))
    edge <- unclass(sf::st_geometry(edges)[[edge_index]])
    stopifnot(egress_follows_directed_partial(coordinates, snap_index, edge))
  }
  cat("KNOWN_DIRECTED_PARTIALS", i, "shortest", shortest, "checked", nrow(last), "\n")
  # Each leg/wait is rounded to 0.1min in the public output.
  totals <- as.data.table(high)[, .(difference = abs(sum(segment_duration + wait) - total_duration[1L]),
                                    tolerance = .N * .1), by = option]
  stopifnot(all(totals$difference <= totals$tolerance + 1e-8),
            all(high$total_duration <= 90 + .05), all(lower$total_duration <= limit + .05))
}
if (baseline) stopifnot(baseline_endpoint_misses > 0L)
if (!baseline) {
  pairs <- fread(".github/fixtures/walking-pairs.csv")
  stopifnot(nrow(pairs) == 300L, !any(pairs$from_id == pairs$to_id))
  origins <- points[match(pairs$from_id, id)]
  destinations <- points[match(pairs$to_id, id)]
  limits <- c(53L, 60L, 90L, 120L)
  for (shortest in c(FALSE, TRUE)) {
    summaries <- list()
    for (limit in limits) {
      routes <- route(origins, destinations, limit, shortest)
      dt <- as.data.table(routes)
      z <- if (nrow(dt)) dt[, .(minimum = min(total_duration)), by = .(from_id, to_id)] else
        data.table(from_id = character(), to_id = character(), minimum = numeric())
      summaries[[as.character(limit)]] <- merge(pairs, z, by = c("from_id", "to_id"), all.x = TRUE)
      cat("AUDIT", "shortest", shortest, limit, "reachable", nrow(z), "of300\n")
      stopifnot(nrow(z) > 0L, all(dt$total_duration <= limit + 0.05))
    }
    contradictions <- 0L
    for (low in limits[-length(limits)]) for (high in limits[limits > low]) {
      a <- copy(summaries[[as.character(low)]])
      b <- summaries[[as.character(high)]]
      setnames(a, "minimum", "low_minimum")
      z <- merge(a, b, by = c("pair_id", "from_id", "to_id"))
      bad <- z[!is.na(minimum) & minimum <= low - 0.1 + 1e-8 &
                 (is.na(low_minimum) | low_minimum > minimum + 1e-8)]
      contradictions <- contradictions + nrow(bad)
      cat("CUTOFF", "shortest", shortest, low, high, "contradictions", nrow(bad),
          "missing", sum(is.na(bad$low_minimum)),
          "worse", sum(!is.na(bad$low_minimum)), "\n")
      if (nrow(bad)) print(bad, nrows = nrow(bad))
    }
    stopifnot(contradictions == 0L)
  }
  # A real Cartesian grid exercises egress sharing and origin-search reuse.
  origins <- points[match(known$from_id, id)]
  destinations <- points[match(known$to_id, id)]
  shared <- route(origins, destinations, 90L, TRUE, TRUE)
  paired <- route(origins[rep(1:2, each = 2L)], destinations[rep(1:2, times = 2L)], 90L, TRUE)
  stopifnot(nrow(shared) > 0L, isTRUE(all.equal(shared, paired)))
  cat("FAST_RAPTOR_SHARED_MATCH pairs", uniqueN(as.data.table(shared)[, .(from_id, to_id)]), "\n")
}
stop_r5(network)
cat("EGRESS_END_TO_END_PASS baseline=", baseline, "\n", sep = "")
