#' \code{r5r} package
#'
#' R package for fast realistic routing with R5
#'
#' See the README on
#' \href{https://github.com/ipeaGIT/r5r#readme}{GitHub}
#'
#' @docType package
#' @name r5r
#' @importFrom utils "tail"
#' @importFrom data.table := %like% %between% fifelse
# #' @importFrom magrittr %>%
# #' @importFrom stats na.omit
# #' @importFrom utils head tail object.size
# #' @importFrom stats na.omit
# #' @importFrom Rcpp compileAttributes
# #' @importFrom lwgeom st_geod_length
# #' @importFrom rgdal readOGR
# #' @useDynLib gtfs2gps, .registration = TRUE

# nocov start
NULL

utils::globalVariables(c(".",
                         "%>%",
                         ":=",
                         "%like%"
                         ))

.onLoad = function(lib, pkg) {
  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
  # set number of threads used in data.table to 100%
  options(datatable.optimize = Inf)
  data.table::setDTthreads(percent = 100)
} # nocov end
