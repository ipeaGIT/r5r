#' Class to internally handle Java reference to R5RCore
#'
#' @family r5r_core
#'
#' @keywords internal
setClass(
  "r5r_core",
  slots = list(jcore = "jobjRef")
)

#' Constructor for r5r_core object
#'
#' @description
#' Wraps a Java R5RCore as an r5r_core.
#'
#' @param jcore A \code{jobjRef} Java object reference to R5RCore.
#' @return \code{r5r_core}
#'
#' @family r5r_core
#'
#' @keywords internal
wrap_r5r_core <- function(jcore) {
  if (!identical(jcore$identify(), "I am an R5R core!")) {
    stop('Provided object is not a valid reference to a java R5R core.')
  }
  new("r5r_core", jcore = jcore)
}

#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
