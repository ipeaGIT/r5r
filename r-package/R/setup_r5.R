#' Create a transport network used for routing in R5
#'
#' Builds a multimodal transport network used for routing in `R5`, combining
#' multiple data inputs present in the directory where the network should be
#' saved to. The directory must contain only one street network file (in
#' `.osm.pbf` format). It may optionally contain one or more public transport
#' GTFS feeds (in `GTFS.zip` format, where `GTFS` is the name of your feed),
#' when used for public transport routing, and a `.tif` file describing the
#' elevation profile of the study area. If there is more than one GTFS feed in
#' the directory, all feeds are merged. If there is already a 'network.dat'
#' file in the directory, the function will simply read it and load it to
#' memory (unless specified not to do so).
#'
#' @template verbose
#' @param data_path A string pointing to the directory where data inputs are
#' stored and where the built `network.dat` will be saved.
#' @param temp_dir A logical. Whether the `R5` Jar file should be saved to a
#' temporary directory. Defaults to `FALSE`.
#' @param elevation A string. The name of the impedance function to be used to
#' calculate impedance for walking and cycling based on street slopes.
#' Available options include `TOBLER` (Default) and `MINETTI`, or `NONE` to
#' ignore elevation. R5 loads elevation data from `.tif` files saved inside the
#' `data_path` directory. See more info in the Details below.
#' @param overwrite A logical. Whether to overwrite an existing `network.dat`
#' or to use a cached file. Defaults to `FALSE` (i.e. use a cached network).
#'
#' @return An `rJava` object to connect with `R5` routing engine.
#'
#' @family setup
#'
#' @section Details:
#' More information about the `TOBLER` and `MINETTI` options to calculate the
#' effects of elevation on travel times can be found in the references below:
#'
#'- Campbell, M. J., et al (2019). Using crowdsourced fitness tracker data to
#'model the relationship between slope and travel rates. Applied geography, 106,
#'93-107. \doi{10.1016/j.apgeog.2019.03.008}.
#'- Minetti, A. E., et al (2002). Energy cost of walking and running at extreme
#'uphill and downhill slopes. Journal of applied physiology. \doi{10.1152/japplphysiol.01177.2001}.
#'- Tobler, W. (1993). Three presentations on geographical analysis and modeling:
#'Non-isotropic geographic modeling speculations on the geometry of geography
#'global spatial analysis. Technical Report. National center for geographic
#'information and analysis. 93 (1). \url{https://escholarship.org/uc/item/05r820mz}.
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' data_path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_core <- setup_r5(data_path)
#' @export
setup_r5 <- function(data_path,
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


  # check Java version installed locally ---------------------------------------

  rJava::.jinit()
  ver <- rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
  ver <- as.numeric(gsub("\\..*", "", ver))
  if (ver != 21) {
    stop(
      "This package requires the Java SE Development Kit 21.\n",
      "Please update your Java installation. ",
      "The jdk 21 can be downloaded from either:\n",
      "  - openjdk: https://jdk.java.net/java-se-ri/21\n",
      "  - oracle: https://docs.oracle.com/en/java/javase/21/install/index.html"
    )
  }

  # expand data_path to full path, as required by rJava api call
  data_path <- path.expand(data_path)

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

  # check if the most recent JAR release is stored already.
  fileurl <- fileurl_from_metadata( r5r_env$r5_jar_version )
  filename <- basename(fileurl)

  jar_file <- data.table::fifelse(
    temp_dir,
    file.path(tempdir(), filename),
    file.path( r5r_env$cache_dir, filename)
  )

  # If there isn't a JAR already larger than 60MB, download it
  if (checkmate::test_file_exists(jar_file) && file.info(jar_file)$size > r5r_env$r5_jar_size) {
    if (!verbose) message("Using cached R5 version from ", jar_file)
  } else {
  check  <- download_r5(temp_dir = temp_dir, quiet = !verbose)
  if (is.null(check)) { return(invisible(NULL)) }
  }

  # r5r jar
  r5r_jar <- system.file("jar/r5r.jar", package = "r5r")
  rJava::.jaddClassPath(path = r5r_jar)

  # R5 jar
  rJava::.jaddClassPath(path = jar_file)

  # JRI jar
  jri_jar <- system.file("jri/JRI.jar", package="rJava")
  rJava::.jaddClassPath(path = jri_jar)

  # check if data_path already has a network.dat file
  dat_file <- file.path(data_path, "network.dat")

  if (checkmate::test_file_exists(dat_file) && !overwrite) {

    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation)

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

    # build new r5r_core
    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation, check=F)
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

  return(r5r_core)

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
