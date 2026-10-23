# Focused oracle for the known fixtures: their last public edge ID identifies
# the nonzero terminal street. This is not a general decoder of paths with
# repeated edge IDs (the public list is a set) or OSM-less terminal streets.
egress_follows_directed_partial <- function(coordinates, snap_index, edge, tolerance = 1e-7) {
  deduplicate <- function(x) {
    x <- unname(as.matrix(x)[, 1:2, drop = FALSE])
    if (nrow(x) > 1L) x <- x[c(TRUE, rowSums(abs(x[-1L, , drop = FALSE] -
                                                 x[-nrow(x), , drop = FALSE])) > 0), , drop = FALSE]
    x
  }
  edge <- deduplicate(edge)
  if (nrow(edge) < 2L || snap_index < 2L) return(FALSE)
  snap <- coordinates[snap_index, 1:2]
  actual <- deduplicate(coordinates[seq_len(snap_index), , drop = FALSE])
  for (i in seq_len(nrow(edge) - 1L)) {
    delta <- edge[i + 1L, ] - edge[i, ]
    fraction <- sum((snap - edge[i, ]) * delta) / sum(delta^2)
    closest <- edge[i, ] + max(0, min(1, fraction)) * delta
    if (max(abs(closest - snap)) > tolerance) next
    expected <- deduplicate(rbind(edge[seq_len(i), , drop = FALSE], snap))
    if (nrow(expected) >= 2L && nrow(actual) >= nrow(expected) &&
        max(abs(tail(actual, nrow(expected)) - expected)) <= tolerance) return(TRUE)
  }
  FALSE
}
