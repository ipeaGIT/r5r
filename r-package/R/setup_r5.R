#' Creates transport network used for routing in R5
#'
#' @description Combines data inputs in a directory to build a multimodal
#'  transport networked used for routing in R5. The directory must contain at
#'  least one street network file (in .pbf format) OR a public transport data
#'  set (in GTFS format). If there is more than one GTFS file in the directory
#'  R5 will merge both files to build the transport network.
#'
#' @param data_path character string, the directory where data inputs are stored
#'                  and where the built network.dat will be saved.
#' @param version character string, the version of R5 to be used. Defaults to
#'                latest version '4.9.0'.
#'
#'
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

setup_r5 <- function(data_path, version='4.9.0') {

  # check directory input
  if(is.null(data_path)){ stop(paste0("Please provide data_path")) }

  # check if data_path has osm.pbf and gtfs data
  any_pbf <- sum(list.files(data_path) %like% '.pbf') > 0
  any_gtfs <- sum(list.files(data_path) %like% '.zip') > 0

  # stop if there is no input data
  if ( any_pbf==FALSE & any_gtfs==FALSE){
    stop(paste0("No street network data (.pbf) and no public transport data
                (gtfs) provided"))}

  if ( any_pbf==FALSE & any_gtfs==TRUE){
    stop(paste0("\nAn OSM PBF file is required to build a network."))}

  # path to jar file
  jar_file <- file.path(.libPaths()[1], "r5r", "jar", paste0("r5r_v", version, ".jar"))

  # check if jar file is stored already. If not, download it
  if (checkmate::test_file_exists(jar_file)) {
    message("Using cached version from ", jar_file)
  } else { download_r5(version=version) }

  # start r5 c
  rJava::.jinit()
  rJava::.jaddClassPath(path = jar_file)
  r5r_core <- rJava::.jnew("com.conveyal.r5.R5RCore", data_path)

  # Warning message if there is only one of either OSM or GTFS data set
  if ( any_pbf==TRUE & any_gtfs==FALSE){
    message(paste0("\nNo public transport data (gtfs) provided. Graph will be
                built with the street network only."))}

  return(r5r_core)
}
