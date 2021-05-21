#' Find snapped locations of input points on street network
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param points a spatial sf POINT object, or a data.frame
#'               containing the columns 'id', 'lon', 'lat'
#' @param mode string. Defaults to "WALK", also allows "BICYCLE", and "CAR".
#' @param n_threads numeric. The number of threads to use in parallel computing.
#'                  Defaults to use all available threads (Inf).
#'
#' @return A data.table with the original points as well as their respective
#'         snapped coordinates on the street network.
#' @export
#'
find_snap <- function(r5r_core,
                      points,
                      mode = "WALK",
                      n_threads = Inf) {

  # set data.table options --------------------------------------------------

  old_options <- options()
  old_dt_threads <- data.table::getDTthreads()

  on.exit({
    options(old_options)
    data.table::setDTthreads(old_dt_threads)
  })

  options(datatable.optimize = Inf)

  # check inputs ------------------------------------------------------------

  # r5r_core
  checkmate::assert_class(r5r_core, "jobjRef")

  # modes
  if (!(mode %in% c('WALK','BICYCLE','CAR'))) {
    stop(paste0(mode, " is not a valid 'mode'.\nPlease use one of the following: WALK, BICYCLE, CAR"))
  }

  # origins and destinations
  points  <- assert_points_input(points, "points")

  # set number of threads to be used by r5 and data.table
  set_n_threads(r5r_core, n_threads)

  # snap points to street network
  snap_df <- r5r_core$findSnapPoints(points$id, points$lat, points$lon, mode)
  snap_df <- jdx::convertToR(snap_df)
  setDT(snap_df)

  snap_df[found == FALSE, `:=`(snap_lat = NA, snap_lon = NA, distance = NA)]

  return(snap_df)
}

