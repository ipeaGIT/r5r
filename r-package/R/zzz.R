# nocov start
utils::globalVariables(c(".", "%>%", ":=", "%like%", "%chin%"))

.onLoad = function(lib, pkg) {
  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
  # set number of threads used in data.table to 100%
  options(datatable.optimize = Inf) # nocov
  data.table::setDTthreads(percent = 100) # nocov
}

#' @importFrom data.table := %between% fifelse %chin%
#' @importFrom methods is signature
NULL



## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1") utils::globalVariables(
  c('is', 'duration', 'fromId', 'toId', 'option', 'option', '.SD', 'geometry',
    'route', 'temp_duration', 'temp_route', 'route', 'temp_sign', '.I'))




# nocov end

