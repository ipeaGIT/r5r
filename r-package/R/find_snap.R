#' Find snapped locations of input points on street network
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param points a spatial sf POINT object, or a data.frame
#'               containing the columns 'id', 'lon', 'lat'
#' @param mode string. Defaults to "WALK", also allows "BICYCLE", and "CAR".
#'
#' @return A data.table with the original points as well as their respective
#'         snapped coordinates on the street network.
#' @export
#'
find_snap <- function(r5r_core,
                      points,
                      mode = "WALK") {

  # check inputs ------------------------------------------------------------

  # r5r_core
  checkmate::assert_class(r5r_core, "jobjRef")

  # modes
  if (!(mode %in% c('WALK','BICYCLE','CAR'))) {
    stop(paste0(mode, " is not a valid 'mode'.\nPlease use one of the following: WALK, BICYCLE, CAR"))
  }

  # origins and destinations
  points  <- assert_points_input(points, "points")

  # snap points to street network
  snap_df <- r5r_core$findSnapPoints(points$id, points$lat, points$lon, mode)
  snap_df <- jdx::convertToR(snap_df)
  data.table::setDT(snap_df)

  snap_df[found == FALSE, `:=`(snap_lat = NA, snap_lon = NA, distance = NA)]

  return(snap_df)
}

