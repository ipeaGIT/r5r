#' @param draws_per_minute An integer. The number of Monte Carlo draws to
#'   perform per time window minute when calculating travel time matrices and
#'   when estimating accessibility. Defaults to 5. This would mean 300 draws in
#'   a 60-minute time window, for example. This parameter only affects the
#'   results when the GTFS feeds contain a `frequencies.txt` table. If the GTFS
#'   feed does not have a frequency table, r5r still allows for multiple runs
#'   over the set `time_window` but in a deterministic way.
