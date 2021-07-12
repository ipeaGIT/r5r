#' Extract transit network in sf format from a network.dat built with setup_r5
#'
#'
#' @param r5r_core a rJava object, the output from 'r5r::setup_r5()'
#'
#' @return A list with two components of a transit network in sf format:
#'         route shapes (LINESTRING) and stops (POINT).
#'
#' @family support functions
#'
#' @examples if (interactive()) {
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path = path)
#'
#' # extract transit network from r5r_core
#' transit_net <- transit_network_to_sf(r5r_core)
#'
#' stop_r5(r5r_core)
#' }
#' @export

transit_network_to_sf <- function(r5r_core) {

  # check input
  if(class(r5r_core)[1] != "jobjRef"){
    stop("Input must be an object of class 'jobjRef' built with 'r5r::setup_r5()'")}

  # Get transit network from R5R core
  network <- r5r_core$getTransitNetwork()

  # Convert edges to SF (linestring)
  routes_df <- jdx::convertToR(network$get(0L), array.order = "column-major")
  data.table::setDT(routes_df)[, geometry := sf::st_as_sfc(geometry)]
  routes_sf <- sf::st_sf(routes_df, crs = 4326) # WGS 84

  # Convert stops to SF (point)
  stops_df <- jdx::convertToR(network$get(1L), array.order = "column-major")
  stops_sf <- sfheaders::sf_point(stops_df, x='lon', y='lat', keep = TRUE)
  sf::st_crs(stops_sf) <- 4326 # WGS 84

  # gather in a list
  transit_network <- list(stops = stops_sf, routes = routes_sf)

  return(transit_network)
}
