#' Extract transit network in sf format
#'
#' @description Extract transit network in `sf` format from a `network.dat` file
#'              built with the \code{\link{setup_r5}} function.
#'
#' @template r5r_core
#'
#' @return A list with two components of a transit network in sf format:
#'         route shapes (LINESTRING) and transit stops (POINT). The same
#'         `route_id`/`short_name` might appear with different geometries. This
#'         occurs when a route has two different shape_ids. Some transit stops
#'         might be returned with geometry `POINT EMPTY` (i.e. missing `NA`
#'         spatial coordinates). This may occur when a transit stop is not
#'         snapped to the road network, possibly because the `gtfs.zip` input
#'         data covers an area larger than the `osm.pbf` input data.
#'
#' @family network functions
#'
#' @examplesIf interactive()
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = path, temp_dir = TRUE)
#'
#' # extract transit network from r5r_core
#' transit_net <- transit_network_to_sf(r5r_core)
#'
#' stop_r5(r5r_core)
#' @export
transit_network_to_sf <- function(r5r_core) {

  # check input
  if(class(r5r_core)[1] != "jobjRef"){
    stop("Input must be an object of class 'jobjRef' built with 'r5r::setup_r5()'")}

  # Get transit network from R5R core
  network <- r5r_core$getTransitNetwork()

  # Convert edges to SF (linestring)
  routes_df <- java_to_dt(network$get(0L))
  routes_df[, geometry := sf::st_as_sfc(geometry)]
  routes_sf <- sf::st_sf(routes_df, crs = 4326) # WGS 84

  # Convert stops to SF (point)
  stops_df <- java_to_dt(network$get(1L))
  stops_df[, lat := ifelse(lat==-1,NA,lat)][, lon := ifelse(lon==-1,NA,lon)]
  stops_sf <- sfheaders::sf_point(stops_df, x='lon', y='lat', keep = TRUE)
  sf::st_crs(stops_sf) <- 4326 # WGS 84

  # gather in a list
  transit_network <- list(stops = stops_sf, routes = routes_sf)

  return(transit_network)
}
