#' @param time_window An integer. The time window in minutes for which `r5r`
#'   will calculate multiple travel time matrices departing each minute.
#'   Defaults to 10 minutes. By default, the function returns the result based
#'   on median travel times, but the user can set the `percentiles` parameter to
#'   extract more results. Please read the time window vignette for more details
#'   on its usage `vignette("time_window", package = "r5r")`
