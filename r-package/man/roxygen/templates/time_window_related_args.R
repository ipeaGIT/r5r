#' @param time_window An integer. The time window in minutes. Departures are
#'   simulated every minute from `departure_datetime` until `time_window`
#'   minutes later, and travel times are summarized over these departures using
#'   `percentiles` (the median by default). Defaults to 10. See
#'   `vignette("time_window", package = "r5r")`.
