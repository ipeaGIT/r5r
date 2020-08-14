
#' Creates and R5R object associated to a data folder
#'
#'
#'
#'
#' @param data_path
#'
#' @return
#' @export
#'
#' @examples
#'
r5_setup <- function(data_path, version='4.9.0') {


  # jar file
  jar_file <- file.path(.libPaths()[1], "r5r", "jar", paste0("r5r_v", version, ".jar"))

  if (checkmate::test_file_exists(jar_file)) {
    message("Using cached version from ", jar_file)
  } else { download_r5(version='4.9.0') }


  rJava::.jinit()
  rJava::.jaddClassPath(path = jar_file)
  # rJava::.jaddClassPath(path = paste0(r5_path, "r5r_core.jar"))

  r5r_core <- rJava::.jnew("com.conveyal.r5.R5RCore", data_path)

  return(r5r_core)
}
