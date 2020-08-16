#' Create transport network used for routing in R5
#'
#' @description Combine data inputs in a directory to build a multimodal
#'  transport network used for routing in R5. The directory must contain at
#'  least one street network file (in .pbf format). One or more public transport
#'  data sets (in GTFS.zip format) are optional. If there is more than one GTFS file
#'  in the directory, both files will be merged. If there is already a 'network.dat'
#'  file in the directory the function will simply read it and load it to memory.
#'
#' @param data_path character string, the directory where data inputs are stored
#'                  and where the built network.dat will be saved.
#' @param version character string, the version of R5 to be used. Defaults to
#'                latest version '4.9.0'.
#'
#' @return An rJava object to connect with R5 routing engine
#' @family setup
#' @examples \donttest{
#'
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' path <- system.file("extdata", package = "r5r")
#'
#' r5r_core <- setup_r5(data_path = path)
#' }
#' @export

setup_r5 <- function(data_path, version = "4.9.0") {

  # check directory input
  if (is.null(data_path)) { stop("Please provide data_path.") }

  # expand data_path to full path, as required by rJava api call
  data_path <- path.expand(data_path)

  # check if data_path has osm.pbf and gtfs data
  any_pbf  <- length(grep(".pbf", list.files(data_path))) > 0
  any_gtfs <- length(grep(".zip", list.files(data_path))) > 0

  # stop if there is no input data
  if (any_pbf == FALSE) {
    stop("\nAn OSM PBF file is required to build a network.")
  }


  # check if jar file is stored already. If not, download it
  jar_file <- file.path(.libPaths()[1], "r5r", "jar", paste0("r5r_v", version, ".jar"))

  if (checkmate::test_file_exists(jar_file)) {
    message("Using cached version from ", jar_file)
  } else {
    download_r5(version = version)
  }

  # start R5 JAR
  rJava::.jinit()
  rJava::.jaddClassPath(path = jar_file)


  # check if data_path already has a network.dat file
    dat_file <- file.path(path, "network.dat")

    if (checkmate::test_file_exists(dat_file)) {
      r5_core <- rJava::.jnew("com.conveyal.r5.R5RCore", data_path)
      message("\nUsing cached network.dat from ", dat_file)
      return(r5_core)
      } else {

  # build new r5_core
  r5r_core <- rJava::.jnew("com.conveyal.r5.R5RCore", data_path)

  # display a warning message if there is a PBF file but no GTFS data
  if (any_pbf == TRUE & any_gtfs == FALSE) {
    message("\nNo public transport data (gtfs) provided. Graph will be built
            with the street network only.")
  }

  message("\nFinished building network.dat at ", dat_file)
  return(r5r_core)

  }
}
