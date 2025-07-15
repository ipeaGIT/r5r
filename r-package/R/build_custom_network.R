#' Create a custom transport network used for routing in R5 with modified OSM car speeds
#'
#' The function builds a transport network with modified OSM car speeds. The
#' function has two modes, hereby refereed to as "edge mode" and "polygon mode".
#' See the Details section below.
#'
#' @param data_path Character. Path to the directory with the`.pbf` file of the
#'        OSM network and optionally supporting data such as elevation and GTFS.
#' @param new_carspeeds A `data.frame` specifying the speed modifications. The
#'        table must contain columns \code{osm_id} and \code{max_speed}. OR
#'        A `sf data.frame` specifying the speed modifications. The table must
#'        contain columns \code{sf polygon}, \code{scale}, \code{priority}. See
#'        `details`.
#' @param output_path Character. A string pointing to the directory where the
#'        modified `network.dat` will be saved. Must be different from
#'        \code{data_path}. Defaults to a temporary directory.
#' @param default_speed Numeric. Default speed to use for road segments not
#'        specified in `new_carspeeds`. Must be `>= `0. Defaults to `NULL` so that
#'        roads not listed have their speeds unchanged. When set to `0`, the road
#'        segment is assumed to be closed.
#' @param percentage_mode Logical. Only OSM mode. If \code{TRUE}, values in \code{max_speed} are
#'        interpreted as percentages of original speeds; if \code{FALSE}, as
#'        absolute speeds (km/h). Defaults to \code{TRUE} - percentages.
#' @template verbose
#' @param verbose_network Whether the returned core has paremeter `verbose = TRUE`.
#' @template elevation
#'
#' @return A `r5r_network` object representing the built network to connect with
#'         `R5` routing engine, and a `network.dat` file saved in the `output_path`.
#'
#' @details
#' - **Edge mode:** The new speed factors must be passed as a `data.frame`
#' indicating the new max speed of each OSM edge id. The table must contain
#' columns \code{osm_id} and \code{max_speed}. Values in \code{max_speed} can be
#' interpreted as percentages of original speeds or as absolute speeds (km/h) by
#' using `percentage_mode` parameter.
#'
#' - **Polygon mode:** The new speed factors must be passed through "congestion
#' region(s)" specified as an `sf data.frame` containing  in each row an
#' `sf polygon` outlining the "congestion region", \code{scale} and \code{priority}.
#' Values in \code{scale} can only be interpreted as percentages of original
#' speeds as `percentage_mode` must be `TRUE`. \code{Priority} is used to apply
#' a hierarchy in case of overlapping polygons.
#' @template elevation_section
#'
#' @family Build network
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # path to OSM .pbf file
#' data_path <- system.file("extdata/poa", package = "r5r")
#'
#' # data.frame with new speed info
#' edge_speeds <- read.csv(file.path(data_path, "poa_osm_congestion.csv"))
#'
# r5r_network_new_speeds <- r5r::build_custom_network(
#   data_path = data_path,
#   new_carspeeds = edge_speeds,
#   output_path = tempdir(),
#   percentage_mode = TRUE
# )
#'
#' # sf with congestion polygons
#' congestion_poly <- readRDS(file.path(data_path, "poa_poly_congestion.rds"))
#'
#' r5r_network_congestion <- r5r::build_custom_network(
#'   data_path = data_path,
#'   new_carspeeds = congestion_poly,
#'   output_path = tempdir(),
#'   percentage_mode = TRUE
#' )
#'
#'
#' @export
build_custom_network <- function(data_path,
                                 new_carspeeds,
                                 output_path = tempdir_unique(),
                                 default_speed = NULL,
                                 percentage_mode = TRUE,
                                 verbose = FALSE,
                                 verbose_network = FALSE,
                                 elevation = "TOBLER"){

  # check inputs
  checkmate::assert_class(new_carspeeds, "data.frame")
  checkmate::assert_numeric(default_speed, lower = 0, finite = TRUE, null.ok = TRUE)
  checkmate::assert_logical(percentage_mode)
  if (isFALSE(percentage_mode) && !is.null(default_speed) && default_speed==1) {
    cli::cli_warn(
      "{.arg percentage_mode} is {.code FALSE}, but {.arg default_speed} is still {.val 1}.
     When {.arg percentage_mode} is FALSE, {.arg default_speed} must be given in km/h."
    )
  }

  checkmate::assert_character(elevation)
  elevation <- toupper(elevation)
  valid_elev <- c("TOBLER", "MINETTI", "NONE")

  if (!elevation %in% valid_elev) {
    cli::cli_abort(c(
      "Invalid value for {.arg elevation}: {.val {elevation}}.",
      "x" = "Must be one of: {.val {valid_elev}}")
    )
  }

  if(inherits(new_carspeeds, "sf") & isFALSE(percentage_mode)) {
    cli::cli_abort(
      "The `percentage_mode` must be `TRUE` when passing an `sf` objecto to `new_carspeeds`."
    )
  }

  # Standardize format of passed paths
  data_path <- normalizePath(data_path, mustWork = FALSE)
  output_path <- normalizePath(output_path, mustWork = FALSE)

  # Assert quality of directories
  checkmate::assert_directory_exists(data_path, access = "r")
  checkmate::assert_directory_exists(output_path, access = "rw")
  if (output_path == data_path) {
    stop(sprintf("output_path ('%s') and data_path ('%s') must be different directories.", output_path, data_path))
  }

  # manipulate data_path directory
  data_pbf_files <- list.files(data_path, pattern = "\\.pbf$", full.names = TRUE)
  if (length(data_pbf_files) != 1) {
    cli::cli_abort(
      "`.path {output_path}` must contain exactly one {.file .pbf} file; found {length(data_pbf_files)} file{?s}."
    )
  }


  pbf_path <- data_pbf_files[[1]]
  checkmate::assert_file_exists(pbf_path, access = "r", extension = "pbf")

  # copy over all supporting files
  files_to_copy <- list.files(
    data_path,
    pattern = "\\.(zip|tif)$",
    full.names = TRUE,
    ignore.case = TRUE,
    recursive = FALSE
  )

  # message copied files
  formatted_files <- paste0("{.file ", basename(files_to_copy), "}", collapse = ", ")
  cli::cli_inform(c(
    i = "Copying {length(files_to_copy)} file{?s}: {formatted_files} to {.path {output_path}}"
  ))
  file.copy(
    from = files_to_copy,
    to = file.path(output_path, basename(files_to_copy)),
    overwrite = TRUE
  )

  # manipulate output_path directory
  output_pbf_files <- list.files(output_path, pattern = "\\.pbf$", full.names = TRUE)
  if (length(output_pbf_files) > 1) {
    cli::cli_abort(
      "`.path {output_path}` must contain at most one {.file .pbf} file; found {length(output_pbf_files)} file{?s}."
      )
    }
  if (length(output_pbf_files) == 1) {
    #message(sprintf("Deleting existing pbf file in output folder: %s\n", output_pbf_files[[1]]))
    cli::cli_inform(c(i = "Deleting existing {.file {output_pbf_files[[1]]}} from the output folder."))
    # write access for output_path directory has been checked so file can be deleted
    file.remove(output_pbf_files[[1]])
  }


  # default speed to keep unlisted roads unchanged
  if (is.null(default_speed)) {
    default_speed <- 1
  }

  start_r5r_java(output_path) # initialize rJava if needed

  # establish mode
  if (inherits(new_carspeeds, "sf")) {
    # polygon mode
    geojson_path <- congestion_poly2geojson(new_carspeeds)

    dest_path <- file.path(output_path, basename(pbf_path))
    file.copy(from = pbf_path, to = dest_path, overwrite = TRUE)
    new_network <- r5r::build_network(output_path,
                                      verbose = verbose_network,
                                      temp_dir = FALSE,
                                      elevation = elevation,
                                      overwrite = TRUE)
    new_network@jcore$applyCongestion(geojson_path,
                                "scale", "priority", "poly_id",
                                rJava::.jfloat(default_speed))
  }
  else {
    # Edge mode
    # change speeds
    speed_map <- dt_to_speed_map(new_carspeeds)
    message("Building speed modifier...")

    speed_setter <- rJava::.jnew("org.ipea.r5r.Utils.SpeedSetter",
                                 pbf_path,
                                 speed_map,
                                 output_path,
                                 verbose)
    speed_setter$setDefaultValue(rJava::.jfloat(default_speed))
    speed_setter$setPercentageMode(percentage_mode)
    speed_setter$runSpeedSetter()

    message("Building new network...")
    new_network <- r5r::build_network(output_path,
                                      verbose = verbose_network,
                                      temp_dir = FALSE,
                                      elevation = elevation,
                                      overwrite = TRUE)
  }

  cli::cli_inform("Custom network with modified car speeds built at {.path {output_path}}")
  return(new_network)
}
