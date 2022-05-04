#' @param r5r_core An object to connect with the R5 routing engine, created with
#' [setup_r5].
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
