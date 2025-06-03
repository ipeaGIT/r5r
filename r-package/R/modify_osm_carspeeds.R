#' Modify OSM Car Speeds in a PBF dataset
#'
#' This function updates car speeds in an PBF dataset by reading modifications from a roadspeeds CSV file
#' and rebuilding the network with the modified speeds.
#'
#' @template r5r_core
#' @param data_dir Character. Path to the directory containing the OSM network data pbf file as well as the roadspeeds CSV file.
#' @param output_dir Character. Directory where the modified network will be written. Defaults to a temporary directory.
#' @param csv_name Character. Path to the CSV file specifying the speed modifications. Must contain columns \code{osm_id} and \code{max_speed}.
#' @param default_speed Numeric. Default speed to use for segments not specified in the CSV. Must be >= 0. Defaults to 1.
#' @param percentage_mode Logical. If \code{TRUE}, values in \code{max_speed} are interpreted as percentages of original speeds; if \code{FALSE}, as absolute speeds (km/h). Defaults to \code{TRUE} - percentages.
#' @param verbose Logical. If \code{TRUE}, creates a verbose R5RCore when rebuilding the network. Defaults to \code{FALSE}.
#'
#' @details
#' The CSV must have columns named \code{osm_id} and \code{max_speed}. \code{max_speed} can be specified as a percentage of the original road speed or as an absolute speed in km/h. The function rebuilds the network in \code{output_dir} or a temporary directory and returns a new r5r_core object.
#'
#' @return An R5 core object representing the rebuilt network with modified car speeds.
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' modify_osm_carspeeds(
#'   data_dir = "path/to/network",
#'   csv_name = "speed_modifications.csv",
#'   output_dir = "path/to/output",
#'   default_speed = 1,
#'   percentage_mode = TRUE,
#'   verbose = TRUE
#' )
#' }
#'
#' @importFrom checkmate assert_file_exists assert_directory_exists assert_numeric assert_logical assert_names
#' @importFrom data.table fread
#' @export
modify_osm_carspeeds <- function(r5r_core,
                                 data_dir,
                                 output_dir = tempdir(),
                                 csv_name,
                                 default_speed = 1,
                                 percentage_mode = TRUE,
                                 verbose = FALSE){

  checkmate::assert_class(r5r_core, "jobjRef")

  data_dir <- normalizePath(data_dir, mustWork = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = FALSE)

  # check directories
  checkmate::assert_directory_exists(data_dir, access = "r")
  checkmate::assert_directory_exists(output_dir, access = "rw")
  if (output_dir == data_dir) { # checkmate doesn't support custom messages
    stop(sprintf("output_dir ('%s') and data_dir ('%s') must be different directories.", output_dir, data_dir))
  }

  # Check for .pbf files
  data_pbf_files <- list.files(data_dir, pattern = "\\.pbf$", full.names = TRUE)
  output_pbf_files <- list.files(output_dir, pattern = "\\.pbf$", full.names = TRUE)
  if (length(data_pbf_files) != 1) { # checkmate doesn't support custom messages
    stop(sprintf("data_dir must contain exactly one .pbf file, found: %d", length(data_pbf_files)))
  }
  if (length(output_pbf_files) != 0) { # checkmate doesn't support custom messages
    stop(sprintf("output_dir must contain zero .pbf files, found: %d", length(output_pbf_files)))
  }


  # check remaining inputs
  csv_name <- normalizePath(file.path(data_dir, csv_name))
  checkmate::assert_file_exists(csv_name, access = "rw", extension = "csv")
  checkmate::assert_numeric(default_speed, lower = 0)
  checkmate::assert_logical(percentage_mode)

  # check colnames in csv
  tempdf <- data.table::fread(csv_name, nrows = 1)
  checkmate::assert_names(
    x = names(tempdf),
    permutation.of = c("osm_id", "max_speed")
    )

  # change speeds
  r5r_core$modifyOSMSpeeds(data_dir,
                           output_dir,
                           csv_name,
                           default_speed,
                           percentage_mode)

  new_core <- r5r::setup_r5(output_dir,
                            verbose = verbose,
                            temp_dir = FALSE,
                            elevation = "TOBLER",
                            overwrite = T)

  message(paste("New car network with modified speeds built at", output_dir))

  return(new_core)
}
