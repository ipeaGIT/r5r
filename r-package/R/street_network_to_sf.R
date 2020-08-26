#' Extract OpenStreetMap network in sf format from a network.dat built with setup_r5
#'
#'
#' @param r5r_core a rJava object, the output from 'r5r::setup_r5()'
#'
#' @return A list with two components of a street network in sf format: vertices
#'         (POINT) and edges (LINESTRING).
#'
#' @family support functions
#'
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata", package = "r5r")
#' r5r_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' street_net <- street_network_to_sf(r5r_core)
#' }
#' @export

street_network_to_sf <- function(r5r_core) {

  # check input
  if(class(r5r_core)[1] != "jobjRef"){
  stop("Input must be an object of class 'jobjRef' built with 'r5r::setup_r5()'")}

  # Get street network from R5R core
  network <- r5r_core$getStreetNetwork()

  # Convert vertices to SF (point)
  vertices_df <- jdx::convertToR(network$get(0L), array.order = "column-major")
  vertices_sf <- sfheaders::sf_point(vertices_df, x='lon', y='lat', keep = TRUE)
  sf::st_crs(vertices_sf) <- 4326 # WGS 84

  # Convert edges to SF (linestring)
  edges_df <- jdx::convertToR(network$get(1L), array.order = "column-major")
  data.table::setDT(edges_df)[, geometry := sf::st_as_sfc(geometry)]
  edges_sf <- sf::st_sf(edges_df, crs = 4326) # WGS 84

  # gather in a list
  street_network <- list(vertices = vertices_sf, edges = edges_sf)

  return(street_network)
}
