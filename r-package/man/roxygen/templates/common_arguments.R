#' @param origins,destinations Either a `POINT sf` object with WGS84 CRS, or a
#'   `data.frame` containing the columns `id`, `lon` and `lat`.
#' @param mode A character vector. The transport modes allowed for access,
#'   transfer and vehicle legs of the trips. Defaults to `WALK`. Please see
#'   details for other options.
#' @param mode_egress A character vector. The transport mode used after egress
#'   from the last public transport. It can be either `WALK`, `BICYCLE` or
#'   `CAR`. Defaults to `WALK`. Ignored when public transport is not used.
#' @param departure_datetime A POSIXct object. Please note that the departure
#'   time only influences public transport legs. When working with public
#'   transport networks, please check the `calendar.txt` within your GTFS feeds
#'   for valid dates. Please see details for further information on how
#'   datetimes are parsed.
#' @param max_walk_time An integer. The maximum walking time (in minutes) to
#'   access and egress the transit network, to make transfers within the network
#'   or to complete walk-only trips. Defaults to no restrictions (numeric value
#'   of `Inf`), as long as `max_trip_duration` is respected. When routing
#'   transit trips, the max time is considered separately for each leg (e.g. if
#'   you set `max_walk_time` to 15, you could get trips with an up to 15 minutes
#'   walk leg to reach transit and another up to 15 minutes walk leg to reach
#'   the destination after leaving transit. In walk-only trips, whenever
#'   `max_walk_time` differs from `max_trip_duration`, the lowest value is
#'   considered.
#' @param max_bike_time An integer. The maximum cycling time (in minutes) to
#'   access and egress the transit network, to make transfers within the network
#'   or to complete bicycle-only trips. Defaults to no restrictions (numeric
#'   value of `Inf`), as long as `max_trip_duration` is respected. When routing
#'   transit trips, the max time is considered separately for each leg (e.g. if
#'   you set `max_bike_time` to 15, you could get trips with an up to 15 minutes
#'   cycle leg to reach transit and another up to 15 minutes cycle leg to reach
#'   the destination after leaving transit. In bicycle-only trips, whenever
#'   `max_bike_time` differs from `max_trip_duration`, the lowest value is
#'   considered.
#' @param max_car_time An integer. The maximum driving time (in minutes) to
#'   access and egress the transit network. Defaults to no restrictions, as long
#'   as `max_trip_duration` is respected. The max time is considered separately
#'   for each leg (e.g. if you set `max_car_time` to 15 minutes, you could
#'   potentially drive up to 15 minutes to reach transit, and up to _another_ 15
#'   minutes to reach the destination after leaving transit). Defaults to `Inf`,
#'   no limit.
#' @param max_trip_duration An integer. The maximum trip duration in minutes.
#'   Defaults to 120 minutes (2 hours).
#' @param walk_speed A numeric. Average walk speed in km/h. Defaults to 3.6
#'   km/h.
#' @param bike_speed A numeric. Average cycling speed in km/h. Defaults to 12
#'   km/h.
#' @param max_rides An integer. The maximum number of public transport rides
#'   allowed in the same trip. Defaults to 3.
#' @param max_lts An integer between 1 and 4. The maximum level of traffic
#'   stress that cyclists will tolerate. A value of 1 means cyclists will only
#'   travel through the quietest streets, while a value of 4 indicates cyclists
#'   can travel through any road. Defaults to 2. Please see details for more
#'   information.
#' @param n_threads An integer. The number of threads to use when running the
#'   router in parallel. Defaults to use all available threads (Inf).
#' @param progress A logical. Whether to show a progress counter when running
#'   the router. Defaults to `FALSE`. Only works when `verbose` is set to
#'   `FALSE`, so the progress counter does not interfere with `R5`'s output
#'   messages. Setting `progress` to `TRUE` may impose a small penalty for
#'   computation efficiency, because the progress counter must be synchronized
#'   among all active threads.
#' @param output_dir Either `NULL` or a path to an existing directory. When not
#'   `NULL` (the default), the function will write one `.csv` file with the
#'   results for each origin in the specified directory. In such case, the
#'   function returns the path specified in this parameter. This parameter is
#'   particularly useful when running on memory-constrained settings because
#'   writing the results directly to disk prevents `r5r` from loading them to
#'   RAM memory.
