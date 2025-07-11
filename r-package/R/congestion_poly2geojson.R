#' Save speeds polygon to .geojson temporary file
#'
#' Support function that checks the input of speeds polygon passed to
#' `build_custom_network()` and saves it to a `.geojson` temporary file.
#'
#' @param new_speeds_poly An a s
#'
#' @family Support functions
#'
#' @return The path to a `.geojson` saved as a temporary file.
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#'
#' # read polygons with new speeds
#' congestion_poly <- readRDS(
#'   system.file("extdata/poa/poa_poly_congestion.rds", package = "r5r")
#'   )
#'
#' geojson_path <- r5r:::congestion_poly2geojson(
#'   new_speeds_poly = congestion_poly
#'   )
#'
#' @keywords internal
congestion_poly2geojson <- function(new_speeds_poly){

  # check input class
  checkmate::assert_class(new_speeds_poly, "sf")

  # check input colnames
  checkmate::assert_names(
    x = names(new_speeds_poly),
    must.include = c("poly_id", "scale", "priority", "geometry")
  )

  # check input geometry
  checkmate::assert_subset(
    x = unique(as.character(sf::st_geometry_type(new_speeds_poly))),
    choices = c("POLYGON", "MULTIPOLYGON"),
    empty.ok = FALSE
  )

  # check input spatial projection
  if (sf::st_crs(new_speeds_poly) != sf::st_crs(4326)) {
    stop(
      "The CRS of parameter `new_speeds` must be WGS 84 (EPSG 4326). ",
      "Please use either sf::set_crs() to set it or ",
      "sf::st_transform() to reproject it."
    )
  }

  # save polygons to temp file
  file_path <- tempfile(
    pattern = 'r5r_congestion_poly',
    fileext = ".geojson"
    )

  sf::st_write(new_speeds_poly, file_path, quiet = TRUE)

  if (file.exists(file_path)) { return(file_path)}
}
