#' Extract OpenStreetMap network in sf format from a network.dat file
#'
#' @template r5r_core
#'
#' @return A list with two components of a street network in sf format: vertices
#'         (POINT) and edges (LINESTRING).
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
#' # extract street network from r5r_network
#' street_net <- street_network_to_sf(r5r_network)
#'
#' stop_r5(r5r_network)
#' @export
street_network_to_sf <- function(r5r_core) {

  # check input
  if(class(r5r_core)[1] != "jobjRef"){
  stop("Input must be an object of class 'jobjRef' built with 'r5r::build_network()'")}

  # Get street network from R5R core
  network <- r5r_core$getStreetNetwork()

  # Convert vertices to SF (point)
  vertices_df <- java_to_dt(network$get(0L))
  vertices_sf <- sfheaders::sf_point(vertices_df, x='lon', y='lat', keep = TRUE)
  sf::st_crs(vertices_sf) <- 4326 # WGS 84

  # Convert edges to SF (linestring)
  edges_df <- java_to_dt(network$get(1L))
  edges_df[, geometry := sf::st_as_sfc(geometry)]
  edges_sf <- sf::st_sf(edges_df, crs = 4326) # WGS 84

  # gather in a list
  street_network <- list(vertices = vertices_sf, edges = edges_sf)

  return(street_network)
}
