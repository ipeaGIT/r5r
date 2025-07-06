#' Class to internally handle Java reference to R5RCore
#'
#' @family r5r_network
#'
#' @keywords internal
setClass(
  "r5r_network",
  slots = list(jcore = "jobjRef")
)

#' Constructor for r5r_network object
#'
#' @description
#' Wraps a Java R5RCore as an r5r_network.
#'
#' @param jcore A \code{jobjRef} Java object reference to R5RCore.
#' @return \code{r5r_network}
#'
#' @family r5r_network
#'
#' @keywords internal
wrap_r5r_network <- function(jcore) {
  if (!identical(jcore$identify(), "I am an R5R core!")) {
    stop('Provided object is not a valid reference to a java R5R core.')
  }
  methods::new("r5r_network", jcore = jcore)
}

#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
