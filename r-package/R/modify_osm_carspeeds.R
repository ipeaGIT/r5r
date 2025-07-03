#' Create a transport network used for routing in R5 with modified OSM car speeds
#'
#' The function builds a transport network with modified OSM car speeds. The new
#' speed factors must me passed from a `.csv` file indication the new max speed
#' of each OSM edge id.
#'
#' @param pbf_path Character. Path to the `.pbf` file of the OSM network.
#' @param csv_path Character. Path to the CSV file witha a table specifying the
#'        speed modifications. The table must contain columns \code{osm_id} and
#'        \code{max_speed}.
#' @param output_dir Character. Directory where the modified network will be
#'        written. Defaults to a temporary directory.
#' @param default_speed Numeric. Default speed to use for segments not specified
#'        in the CSV. Must be >= 0. Defaults to `NULL` so that roads not listed
#'        in. the CSV have their speeds unchanged.
#' @param percentage_mode Logical. If \code{TRUE}, values in \code{max_speed} are
#'        interpreted as percentages of original speeds; if \code{FALSE}, as
#'        absolute speeds (km/h). Defaults to \code{TRUE} - percentages.
#' @param verbose Logical. If \code{TRUE}, the function modifies the network verbosely and
#'        creates a verbose R5RCore. Defaults to \code{FALSE}.
#'
#' @details
#' The CSV must have columns named \code{osm_id} and \code{max_speed}. \code{max_speed}
#' can be specified as a percentage of the original road speed or as an absolute
#' speed in km/h. The function rebuilds the network in \code{output_dir} and
#' returns a new `r5r_core` object.
#'
#' @family modify_osm_car_speeds
#'
#' @return An R5 core object representing the rebuilt network with modified car speeds.
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # path to OSM .pbf file
#' pbf_path <- system.file("extdata/poa/poa_osm.pbf", package = "r5r")
#'
#' # path to CSV with a table pointing to the new speed info
#' speeds_csv_path <- system.file("extdata/poa/poa_osm_congestion.csv", package = "r5r")
#'
#' r5r_core_new_speed <- r5r::modify_osm_carspeeds(
#'   pbf_path = pbf_path,
#'   csv_path = speeds_csv_path,
#'   output_dir = tempdir(),
#'   percentage_mode = TRUE
#' )
#'
#' @export
modify_osm_carspeeds <- function(pbf_path,
                                 csv_path,
                                 output_dir = tempdir_unique(),
                                 default_speed = NULL,
                                 percentage_mode = TRUE,
                                 verbose = FALSE){

  # Standardize format of passed paths
  pbf_path <- normalizePath(pbf_path, mustWork = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = FALSE)
  original_dir <-  normalizePath(dirname(pbf_path))
  csv_path <- normalizePath(csv_path, mustWork = F)

  # Assert quality of output directory
  checkmate::assert_directory_exists(output_dir, access = "rw")
  output_pbf_files <- list.files(output_dir, pattern = "\\.pbf$", full.names = TRUE)
  if (length(output_pbf_files) != 0) {
    stop(sprintf("output_dir must contain zero .pbf files, found: %d", length(output_pbf_files)))
  }

  # check remaining inputs
  checkmate::assert_file_exists(pbf_path, access = "r", extension = "pbf")
  checkmate::assert_file_exists(csv_path, access = "r", extension = "csv")
  checkmate::assert_numeric(default_speed, lower = 0, finite = TRUE, null.ok = TRUE)
  checkmate::assert_logical(percentage_mode)

  if (isFALSE(percentage_mode) && !is.null(default_speed) && default_speed==1) {
    cli::cli_warn(
      "{.arg percentage_mode} is {.code FALSE}, but {.arg default_speed} is still {.val 1}.
     When {.arg percentage_mode} is FALSE, {.arg default_speed} must be given in km/h."
    )
  }
  # default speed to keep unlisted roads unchanged
  if (is.null(default_speed)) {
    default_speed <- 1
  }

  # check colnames in csv
  tempdf <- data.table::fread(csv_path, nrows = 1)
  checkmate::assert_names(
    x = names(tempdf),
    must.include = c("osm_id", "max_speed")
    )

  # change speeds
  start_r5r_java(original_dir) # initialize rJava if needed

  speed_setter <- rJava::.jnew("org.ipea.r5r.Utils.SpeedSetter",
                               pbf_path,
                               csv_path,
                               output_dir,
                               verbose)
  speed_setter$setDefaultValue(rJava::.jfloat(default_speed))
  speed_setter$setPercentageMode(percentage_mode)
  speed_setter$runSpeedSetter()

  new_core <- r5r::setup_r5(output_dir,
                            verbose = verbose,
                            temp_dir = FALSE,
                            elevation = "TOBLER",
                            overwrite = TRUE)

  cli::cli_inform("New car network with modified speeds built at {.path {output_dir}}")

  return(new_core)
}
