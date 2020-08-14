
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
#'
r5_setup <- function(r5_path, data_path) {
  rJava::.jinit()
  rJava::.jaddClassPath(path = paste0(r5_path, "R5.jar"))
  # rJava::.jaddClassPath(path = paste0(r5_path, "r5r_core.jar"))

  r5r_core <- rJava::.jnew("com.conveyal.r5.R5RCore", data_path)

  return(r5r_core)
}
