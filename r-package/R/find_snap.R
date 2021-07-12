#' Find snapped locations of input points on street network
#'
#' @description R5 tries to snap origin and destination points to the street
#' network in two rounds. First, it uses a search radius of 300 meters. If the
#' first round is unsuccessful, then R5 expands the search radius to 1.6 km.
#' Points that aren't linked to the street network after those two rounds are
#' returned with `NA` coordinates and `found = FALSE`. Please note that the
#' location of the snapped points depends on the transport mode set by the user.
#'
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param points a spatial sf POINT object, or a data.frame
#'               containing the columns 'id', 'lon', 'lat'
#' @param mode string. Defaults to "WALK", also allows "BICYCLE", and "CAR".
#'
#' @return A data.table with the original points as well as their respective
#'         snapped coordinates on the street network and the Euclidean distance
#'         between original points and their respective snapped location. Points
#'         that could not be snapped show `NA` coordinates and `found = FALSE`.
#'
#' @family support functions
#'
#' @export
#'
#' @examples if (interactive()) {
#'
#' library(r5r)
#'
#' # build transport network
#' path <- system.file("extdata/spo", package = "r5r")
#' r5r_core <- setup_r5(data_path = path)
#'
#' # load origin/destination points
#' points <- read.csv(file.path(path, "spo_hexgrid.csv"))
#'
#' # find where origin or destination points are snapped
#' snap_df <- find_snap(r5r_core,
#'                      points = points,
#'                      mode = 'CAR')
#'
#' stop_r5(r5r_core)
#' }

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
  system.time(snap_df <- r5r_core$findSnapPoints(points$id, points$lat, points$lon, mode))
  system.time(snap_df <- jdx::convertToR(snap_df))
  data.table::setDT(snap_df)

  snap_df[found == FALSE, `:=`(snap_lat = NA, snap_lon = NA, distance = NA)]

  return(snap_df)
}



