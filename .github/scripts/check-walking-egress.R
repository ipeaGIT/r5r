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
  sub("^file:", "", rJava::.jcall(url, "S", "toExternalForm"))
}
jars <- c(bridge = loaded_jar("org/ipea/r5r/R5RCore"),
          r5 = loaded_jar("com/conveyal/r5/transit/TransportNetwork"))
print(jars)
print(tools::md5sum(jars))
route <- function(origins, destinations, limit, shortest = FALSE) detailed_itineraries(
  network, origins, destinations, mode = c("WALK", "TRANSIT"),
  all_to_all = FALSE,
  departure_datetime = as.POSIXct("2019-05-13 14:00:00", tz = "America/Sao_Paulo"),
  time_window = 10L, max_walk_time = 53L, max_trip_duration = limit,
  shortest_path = shortest, n_threads = 2L, progress = FALSE, osm_link_ids = TRUE)
known <- data.table(
  from_id = c("89a9012aedbffff", "89a90129c4fffff"),
  to_id = c("89a9012997bffff", "89a90128b4fffff"))
for (i in seq_len(nrow(known))) {
  origin <- points[match(known$from_id[i], id)]
  destination <- points[match(known$to_id[i], id)]
  low <- route(origin, destination, 60L)
  high <- route(origin, destination, 90L)
  stopifnot(nrow(high) > 0L)
  cat("KNOWN", i, "segments60", nrow(low), "segments90", nrow(high),
      "minimum90", min(high$total_duration), "\n")
  if (baseline) {
    stopifnot(nrow(low) == 0L, min(high$total_duration) < 60)
  } else {
    stopifnot(min(high$total_duration) > 60 || nrow(low) > 0L)
    transit_options <- unique(high$option[!high$mode %in% c("WALK", "BICYCLE", "CAR")])
    stopifnot(length(transit_options) > 0L)
    transit <- high[high$option %in% transit_options, ]
    last <- transit[!duplicated(transit$option, fromLast = TRUE), ]
    ends <- lapply(sf::st_geometry(last), function(g) tail(unclass(g), 1L)[1L, 1:2])
    stopifnot(all(vapply(ends, function(x) max(abs(x - c(destination$lon, destination$lat))) < 1e-7, logical(1))))
    shortest <- route(origin, destination, 90L, TRUE)
    stopifnot(nrow(shortest) > 0L)
    # Each leg/wait is rounded to 0.1min in the public output.
    totals <- as.data.table(high)[, .(difference = abs(sum(segment_duration + wait) - total_duration[1L]),
                                      tolerance = .N * .1), by = option]
    stopifnot(all(totals$difference <= totals$tolerance + 1e-8))
  }
}
if (!baseline) {
  pairs <- fread(".github/fixtures/walking-pairs.csv")
  stopifnot(nrow(pairs) == 300L, !any(pairs$from_id == pairs$to_id))
  origins <- points[match(pairs$from_id, id)]
  destinations <- points[match(pairs$to_id, id)]
  limits <- c(53L, 60L, 90L, 120L)
  summaries <- list()
  for (limit in limits) {
    routes <- route(origins, destinations, limit)
    dt <- as.data.table(routes)
    z <- if (nrow(dt)) dt[, .(minimum = min(total_duration)), by = .(from_id, to_id)] else
      data.table(from_id = character(), to_id = character(), minimum = numeric())
    summaries[[as.character(limit)]] <- merge(pairs, z, by = c("from_id", "to_id"), all.x = TRUE)
    cat("AUDIT", limit, "reachable", nrow(z), "of300\n")
    stopifnot(nrow(z) > 0L, all(dt$total_duration <= limit + 0.05))
  }
  contradictions <- 0L
  for (low in limits[-length(limits)]) for (high in limits[limits > low]) {
    a <- copy(summaries[[as.character(low)]])
    b <- summaries[[as.character(high)]]
    setnames(a, "minimum", "low_minimum")
    z <- merge(a, b, by = c("pair_id", "from_id", "to_id"))
    n <- z[is.na(low_minimum) & !is.na(minimum) & minimum <= low - 0.1 + 1e-8, .N]
    contradictions <- contradictions + n
    cat("CUTOFF", low, high, "contradictions", n, "\n")
  }
  stopifnot(contradictions == 0L)
}
stop_r5(network)
cat("EGRESS_END_TO_END_PASS baseline=", baseline, "\n", sep = "")
