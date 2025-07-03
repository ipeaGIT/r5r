#' Extract transit network in sf format
#'
#' Extracts the transit network from a `network.dat` file (built with
#' [build_network()]) in `sf` format.
#'
#' @template r5r_core
#'
#' @return A list with two components of a transit network in `sf` format:
#' route shapes (`LINESTRING`) and transit stops (`POINT`). The same
#' `route_id`/`short_name` might appear with different geometries. This occurs
#' when the same route is associated to more than one `shape_id`s in the GTFS
#' feed used to create the transit network. Some transit stops might be
#' returned with geometry `POINT EMPTY` (i.e. missing spatial coordinates).
#' This may occur when a transit stop is not snapped to the road network,
#' possibly because the GTFS feed used to create the transit network covers an
#' area larger than the `.osm.pbf` input data.
#'
#' @family network functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(path)
#'
#' # extract transit network from r5r_network
#' transit_net <- transit_network_to_sf(r5r_network)
#'
#' stop_r5(r5r_network)
#' @export
transit_network_to_sf <- function(r5r_core) {
  checkmate::assert_class(r5r_core, "jobjRef")

  network <- r5r_core$getTransitNetwork()

  # Convert edges to SF (linestring)
  routes_df <- java_to_dt(network$get(0L))
  routes_df[, geometry := sf::st_as_sfc(geometry)]
  routes_sf <- sf::st_sf(routes_df, crs = 4326) # WGS 84

  if (any(!sf::st_is_valid(routes_sf))) {
    routes_sf <- sf::st_make_valid(routes_sf)
  }

  routes_sf <- routes_sf[!sf::st_is_empty(routes_sf), ] # removing empty geometries

  # Convert stops to SF (point)
  stops_df <- java_to_dt(network$get(1L))
  stops_df[
    ,
    `:=`(
      lat = data.table::fifelse(lat == -1, NA_real_, lat),
      lon = data.table::fifelse(lon == -1, NA_real_, lon)
    )
  ]
  stops_sf <- sfheaders::sf_point(stops_df, x = "lon", y = "lat", keep = TRUE)
  sf::st_crs(stops_sf) <- 4326 # WGS 84

  transit_network <- list(stops = stops_sf, routes = routes_sf)

  return(transit_network)
}
