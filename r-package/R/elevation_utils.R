############# Support functions for r5r

#' Tobler's hiking function
#'
#' @description Calculates effect of the topography on walking speeds, using
#'              Tobler's hiking function.
#'
#' @param slope numeric. Terrain's slope.
#'
#' @return numeric. Tobler's weighting factor
#' @family elevation support functions
tobler_hiking <- function(slope) {
  C <- 1.19403

  tobler_factor <- C * exp(-3.5 * abs(slope+0.05))

  return(1 / tobler_factor)
}

#' Apply elevation to street network
#'
#' @description Loads a Digital Elevation Model (DEM) from a raster file and
#'              weights the street network for walking and cycling according to
#'              the terrain's slopes
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param raster_files string. Path to raster files containing the study area's
#'                     topography. If a list is provided, all the rasters are
#'                     automatically merged.
#'
#' @return No return value, called for side effects.
#' @family elevation support functions
apply_elevation <- function(r5r_core, raster_files) {
  # load raster files containing elevation data
  if (length(raster_files) == 1) {
    dem <- raster::raster(raster_files[1])
  } else {
    dem_files <- lapply(raster_files, raster::raster)
    dem <- do.call(raster::merge, dem_files)
  }

  # extract street edges from r5r_core
  edges <- r5r_core$getEdges()
  edges <- jdx::convertToR(edges)
  data.table::setDT(edges)

  # extract each edge's elevation from DEM and store in edges data.frame
  start_elev  <- raster::extract(dem, edges[, .(start_lon, start_lat)])
  end_elev <- raster::extract(dem, edges[, .(end_lon, end_lat)])

  edges[, start_elev := start_elev]
  edges[, end_elev := end_elev ]

  # calculate slopes and flatten segments that are too steep
  edges[, slope := (end_elev - start_elev) / length]
  edges[is.na(slope), slope := 0.0]
  edges[slope < -1.0, slope := 0.0]
  edges[slope >  1.0, slope := 0.0]

  # calculate walk_multiplier using Tobler's Hiking function
  edges[, walk_multiplier := tobler_hiking(slope)]

  # calculate bike_multiplier using OTP's bike speed coefficient function
  # included in r5r_core
  # the function has 2 parameters: slope and altitute
  bike_mult <- r5r_core$bikeSpeedCoefficientOTP(edges$slope, edges$start_elev)
  edges[, bike_multiplier := 1 / bike_mult] # values need to be inverted

  # update walk and bike weights in r5r_core
  id <- as.integer(edges$edge_index)
  fct_walk <- as.double(edges$walk_multiplier)
  fct_bike <- as.double(edges$bike_multiplier)
  r5r_core$updateEdges(id, fct_walk, fct_bike)
}
