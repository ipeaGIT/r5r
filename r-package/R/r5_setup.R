
#' Creates and R5R object associated to a data folder
#'
#'
#'
#'
#' @param r5_path
#' @param data_path
#'
#' @return
#' @export
#'
#' @examples
r5_setup <- function(r5_path, data_path) {
  .jinit()
  .jaddClassPath(path = r5_path)

  r5r_core <- .jnew("R5RCore", data_path)

  return(r5r_core)
}
