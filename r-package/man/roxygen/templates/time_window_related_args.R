#' @param time_window An integer. The time window in minutes for which `r5r`
#'   will calculate multiple travel time matrices departing each minute.
#'   Defaults to 1 minute. By default, the function returns the result based on
#'   median travel times, but the user can set the `percentiles` parameter to
#'   extract more results.Please read the time window vignette for more details
#'   on its usage `vignette("time_window", package = "r5r")`
#' @param draws_per_minute An integer. The number of Monte Carlo draws to
#'   perform per time window minute when calculating travel time matrices and
#'   when estimating accessibility. Defaults to 5. This would mean 300 draws in
#'   a 60-minute time window, for example. This parameter only affects the
#'   results when the GTFS feeds contain a `frequencies.txt` table.
