#' Class to internally handle Java reference to R5RCore
#'
#' @keywords internal
setClass(
  "R5R_core",
  slots = list(r5r_core = "jobjRef")
)

#' Constructor for R5R_core object
#'
#' @description
#' Wraps a Java R5RCore as an R5R_core.
#' @param r5r_core A \code{jobjRef} Java object reference to R5RCore.
#' @keywords internal
wrap_r5r_core <- function(r5r_core) {
  # if (!identical(r5r_core$identify(), "I am an R5R core!")) {
  #   stop('Provided object is not a valid reference to a java R5R core.')
  # }
  new("R5R_core", r5r_core = r5r_core)
}

setGeneric("get_core", function(object) standardGeneric("get_core"))

setMethod("get_core", "R5R_core", function(object) {
  object@r5r_core
})
