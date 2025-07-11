#' Build a transport network used for routing in R5
#'
#' Builds a multimodal transport network used for routing in `R5`, combining
#' multiple data inputs present in the directory where the network should be
#' saved to. The directory must contain only one street network file (in
#' `.osm.pbf` format). It may optionally contain one or more public transport
#' GTFS feeds (in `.zip` format), when used for public transport routing, and a
#' `.tif` file describing the elevation profile of the study area. If there is
#' more than one GTFS feed in the directory, all feeds are automatically merged.
#' If there is already a `'network.dat'` file in the directory, the function will
#' simply read it and load it to memory (unless specified not to do so).
#'
#' @template verbose
#' @param data_path A string pointing to the directory where data inputs are
#'        stored and where the built `network.dat` will be saved.
#' @param temp_dir A logical. Whether the `network.dat` file should be saved to
#'        a temporary directory. Defaults to `FALSE`.
#' @template elevation
#' @param overwrite A logical. Whether to overwrite an existing `network.dat`
#'        or to use a cached file. Defaults to `FALSE` (i.e. use a cached
#'        network).
#'
#' @return A `r5r_network` object representing the built network to connect with
#'         `R5` routing engine.
#'
#' @template elevation_section
#'
#' @family Build network
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' data_path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_network <- build_network(data_path)
#' @export
build_network <- function(data_path,
                          verbose = FALSE,
                          temp_dir = FALSE,
                          elevation = "TOBLER",
                          overwrite = FALSE) {

  # check inputs ------------------------------------------------------------

  checkmate::assert_directory_exists(data_path)
  checkmate::assert_logical(verbose)
  checkmate::assert_logical(temp_dir)
  checkmate::assert_character(elevation)
  checkmate::assert_logical(overwrite)

  elevation <- toupper(elevation)
  if (!(elevation %in% c('TOBLER', 'MINETTI','NONE'))) {
    stop("The 'elevation' parameter only accepts one of the following: c('TOBLER', 'MINETTI','NONE')")
    }

  # expand data_path to full path, as required by rJava api call
  data_path <- path.expand(data_path)

  # check Java version installed locally and init java
  start_r5r_java(data_path = data_path, temp_dir = temp_dir, verbose = verbose)

  # check if data_path has osm.pbf, .tif gtfs data, or a network.dat file
  any_network <- length(grep("network.dat", list.files(data_path))) > 0
  any_pbf  <- length(grep(".pbf", list.files(data_path))) > 0
  any_gtfs <- length(grep(".zip", list.files(data_path))) > 0
  any_tif <- length(grep(".tif", list.files(data_path))) > 0

  # stop if there is no input data
  if (!(any_pbf | any_network)){
    stop("\nAn OSM PBF file is required to build a network.")
    }

  # use no elevation model if there is no raster.tif input data
  if (!(any_tif)) {
    elevation <- 'NONE'
    message("No raster .tif files found. Using elevation = 'NONE'.")
    }

  # check if data_path already has a network.dat file
  dat_file <- file.path(data_path, "network.dat")

  if (checkmate::test_file_exists(dat_file) && !overwrite) {

    r5r_network <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation)

    message("\nUsing cached network.dat from ", dat_file)

  } else {
    # check if the user has permission to write to the data directory. if not,
    # R5 won't be able to create the required files and will fail with a
    # not-that-enlightening error
    error_if_no_write_permission(data_path)

    # stop r5 in case it is already running
    suppressMessages( r5r::stop_r5() )

    # clean up any files that might have been created by previous r5r usage
    # if the files do not exist 'file.remove()' will raise a warning, which is
    # suppressed here
    mapdb_files <- list.files(data_path, full.names = TRUE)
    mapdb_files <- mapdb_files[grepl("\\.mapdb", mapdb_files)]
    suppressWarnings(
      invisible(file.remove(dat_file, mapdb_files))
    )

    # build new r5r_network
    r5r_network <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation, check=F)
    ex = rJava::.jgetEx(clear=TRUE)
    if (!is.null(ex)) {
      msg <- rJava::.jcall(ex, "S", "toString")
      if (grepl("Geographic extent of street layer", msg)) {
        cli::cli_abort("Geographic extent of street layer exceeds limit of 975000 km2.")
      } else {
      ex$printStackTrace()
      return(NULL)
      }
    }

    # display a message if there is a PBF file but no GTFS data
    if (any_pbf == TRUE & any_gtfs == FALSE) {
      message(paste("\nNo public transport data (gtfs) provided.",
                    "Graph will be built with the street network only."))
    }

    message("\nFinished building network.dat at ", dat_file)

  }

  return(wrap_r5r_network(r5r_network))

}

error_if_no_write_permission <- function(data_path) {
  write_permission <- file.access(data_path, mode = 2)

  normalized_path <- normalizePath(data_path)

  if (write_permission == -1) {
    cli::cli_abort(
      c(
        "Permission to write to {.path {normalized_path}} denied.",
        i = paste0(
          "{.pkg r5r} needs write privilege to create the network files. ",
          "Please make sure you have this privilege in the provided directory."
        )
      ),
      class = "dir_permission_denied",
      call = rlang::caller_env()
    )
  }

  return(invisible(TRUE))
}
