# nocov start
utils::globalVariables(c(".", "%>%", ":=", "%like%", "%chin%"))

.onLoad = function(lib, pkg) {
  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
  requireNamespace("dplyr")
  # set number of threads used in data.table to 100%
  options(datatable.optimize = Inf) # nocov
  data.table::setDTthreads(percent = 100) # nocov
}

#' @importFrom magrittr %>%
#' @importFrom data.table := %between% fifelse %chin%
# #' @importFrom methods  is signature
NULL

# nocov end

