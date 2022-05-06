#' @param r5r_core An object to connect with the R5 routing engine, created with
#' [setup_r5()].
#' @param origins,destinations Either a `POINT sf` object with WGS84 CRS, or a
#' `data.frame` containing the columns `id`, `lon` and `lat`.
#' @param mode A character vector. The transport modes allowed for access,
#' transfer and vehicle legs of the trips. Defaults to `WALK`. Please see
#' details for other options.
#' @param mode_egress A character vector. The transport mode used after egress
#' from the last public transport. It can be either `WALK`, `BICYCLE` or `CAR`.
#' Defaults to `WALK`. Ignored when public transport is not used.
#' @param departure_datetime A POSIXct object. If working with public transport
#' networks, please check the `calendar.txt` within your GTFS feeds for valid
#' dates. Please see details for further information on how datetimes are
#' parsed.
#' @param max_walk_dist An integer. The maximum walking distance (in meters) to
#' access and egress the transit network, or to make transfers within the
#' network. Defaults to no restrictions, as long as `max_trip_duration` is
#' respected. The max distance is considered separately for each leg (e.g. if
#' you set `max_walk_dist` to 1000, you could potentially walk up to 1 km to
#' reach transit, and up to _another_ 1 km to reach the destination after
#' leaving transit). Please note that this parameter doesn't affect the maximum
#' length of walking-only trips, only walking access, egress and transfer legs.
#' If you want to set a maximum walking distance for walking-only trips you
#' have to use the `max_trip_duration` parameter (e.g. to set a walking-only
#' trip max distance of 1 km, assuming a walking speed of 3.6 km/h, you have to
#' set `max_trip_duration = 1 / 3.6 * 60`).
#' @param max_bike_dist An integer. The maximum cycling distance (in meters) to
#' access and egress the transit network, or to make transfers within the
#' network. Defaults to no restrictions, as long as `max_trip_duration` is
#' respected. The max distance is considered separately for each leg (e.g. if
#' you set `max_bike_dist` to 1000, you could potentially cycle up to 1 km to
#' reach transit, and up to _another_ 1 km to reach the destination after
#' leaving transit). Please note that this parameter doesn't affect the maximum
#' length of cycling-only trips, only cycling access, egress and transfer legs.
#' If you want to set a maximum cycling distance for cycling-only trips you
#' have to use the `max_trip_duration` parameter (e.g. to set a walking-only
#' trip max distance of 5 km, assuming a cycling speed of 12 km/h, you have to
#' set `max_trip_duration = 5 / 12 * 60`).
#' @param max_trip_duration An integer. The maximum trip duration in minutes.
#' Defaults to 120 minutes (2 hours).
#' @param walk_speed A numeric. Average walk speed in km/h. Defaults to 3.6
#' km/h.
#' @param bike_speed A numeric. Average cycling speed in km/h. Defaults to 12
#' km/h.
#' @param max_rides An integer. The maximum number of public transport rides
#' allowed in the same trip. Defaults to 3.
#' @param max_lts An integer between 1 and 4. The maximum level of traffic
#' stress that cyclists will tolerate. A value of 1 means cyclists will only
#' travel through the quietest streets, while a value of 4 indicates cyclists
#' can travel through any road. Defaults to 2. Please see details for more
#' information.
#' @param n_threads An integer. The number of threads to use when running the
#' router in parallel. Defaults to use all available threads (Inf).
#' @param verbose A logical. Whether to show `R5` informative messages when
#' running the router. Defaults to `FALSE` (please note that in such case `R5`
#' error messages are still shown). Setting `verbose` to `TRUE` shows detailed
#' output, which can be useful for debugging issues not caught by `r5r`.
#' @param progress A logical. Whether to show a progress counter when running
#' the router. Defaults to `FALSE`. Only works when `verbose` is set to `FALSE`,
#' so the progress counter does not interfere with `R5`'s output messages.
#' Setting `progress` to `TRUE` may impose a small penalty for computation
#' efficiency, because the progress counter must be synchronized among all
#' active threads.
