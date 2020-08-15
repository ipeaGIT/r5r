
utils::globalVariables(c(".",
                         "%>%",
                         ":=",
                         "%like%"
                         ))

.onLoad = function(lib, pkg) {

  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
  options(datatable.optimize = Inf) # nocov

  # set number of threads used in data.table to 100%
  data.table::setDTthreads(percent = 100) # nocov
}

#' @importFrom data.table := %like% %between% fifelse
# #' @importFrom magrittr %>%
# #' @importFrom stats na.omit
# #' @importFrom utils head tail object.size
# #' @importFrom stats na.omit
# #' @importFrom Rcpp compileAttributes
# #' @importFrom lwgeom st_geod_length
# #' @importFrom rgdal readOGR
# #' @useDynLib gtfs2gps, .registration = TRUE


# ## quiets concerns of R CMD check re: the .'s that appear in pipelines
# if(getRversion() >= "2.15.1") utils::globalVariables(
#   c('dist', 'shape_id', 'route_id', 'trip_id', 'stop_id',
#     'service_id', 'stop_sequence', 'agency_id', 'i.stop_lat', 'i.stop_lon', 'i.stop_id',
#     'departure_time', 'arrival_time', 'start_time', 'end_time', 'i.stop_sequence',
#     'shape_pt_lon', 'shape_pt_lat', 'id', 'cumdist', 'i.departure_time',
#     '.N', 'update_newstoptimes', 'shape_pt_sequence', 'geometry',
#     'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
#     'service_duration', 'headway_secs', 'number_of_departures',
#     'cumtime', 'speed', 'i', 'route_type', 'trip_number',
#     '.I', 'interval_id', 'i.interval', '.SD', 'grp', '.GRP'))
