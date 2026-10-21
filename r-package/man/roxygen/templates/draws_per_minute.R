#' @param draws_per_minute An integer. The number of Monte Carlo draws to
#'   perform per minute of `time_window`. Defaults to 5. This would mean 300
#'   draws in a 60-minute time window, for example. With the default routing
#'   algorithm, this parameter only affects the results when the GTFS feeds
#'   contain a `frequencies.txt` table; otherwise, r5r still routes a departure
#'   every minute of `time_window`, in a deterministic way. In functions that
#'   accept a `fare_structure`, passing one switches to the McRaptor algorithm,
#'   which instead routes `time_window * draws_per_minute` departure times
#'   sampled at random within the window (the same in every call from the same
#'   origin). This parameter then affects the results with or without
#'   frequencies.
