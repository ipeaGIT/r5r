#' Extract OpenStreetMap network in SF format
#'
#' @param r5_core
#'
#' @return A street network object with two SF fields: vertices and edges.
#' @export
#'
#' @examples
street_network_to_sf <- function(r5_core) {

  # Get street network from R5R core
  network <- r5_core$getStreetNetwork()

  # Convert vertices to SF (point)
  vertices_df <- jdx::convertToR(network$get(0L), array.order = "column-major")
  vertices_sf <- sfheaders::sf_point(vertices_df, x='lon', y='lat', keep = TRUE)
  sf::st_crs(vertices_sf) <- 4326 # WGS 84

  # Convert edges to SF (linestring)
  edges_df <- jdx::convertToR(network$get(1L), array.order = "column-major")
  data.table::setDT(edges_df)[, geometry := sf::st_as_sfc(geometry)]
  edges_sf <- sf::st_sf(edges_df, crs = 4326) # WGS 84

  # Create retorn
  street_network <- list(vertices = vertices_sf, edges = edges_sf)
  class(street_network) <- "street_network"

  return(street_network)
}



