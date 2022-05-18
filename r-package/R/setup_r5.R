#' Create a transport network used for routing in R5
#'
#' Builds a multimodal transport network used for routing in `R5`, combining
#' multiple data inputs present in the directory where the network should be
#' saved to. The directory must contain at least one street network file (in
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
#' @param version A string. The version of `R5` to be used. Defaults to the
#' latest version.
#' @param temp_dir A logical. Whether the `R5` Jar file should be saved to a
#' temporary directory. Defaults to `FALSE`.
#' @param elevation A string. The name of the impedance function to be used to
#' calculate impedance for walking and cycling based on street slopes.
#' Available options include `TOBLER` (Default) and `MANETTI`, or `NONE` to
#' ignore elevation. R5 loads elevation data from `.tif` files saved inside the
#' `data_path` directory.
#' @param overwrite A logical. Whether to overwrite an existing `network.dat`
#' or to use a cached file. Defaults to `FALSE` (i.e. use a cached network).
#'
#' @return An `rJava` object to connect with `R5` routing engine.
#'
#' @family setup
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_core <- setup_r5(path)
#' @export
setup_r5 <- function(data_path,
                     version = "6.7.0",
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
  if (ver != 11) {
    stop(
      "This package requires the Java SE Development Kit 11.\n",
      "Please update your Java installation. ",
      "The jdk 11 can be downloaded from either:\n",
      "  - openjdk: https://jdk.java.net/java-se-ri/11\n",
      "  - oracle: https://www.oracle.com/java/technologies/javase-jdk11-downloads.html"
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
  if (!(any_pbf | any_network))
    stop("\nAn OSM PBF file is required to build a network.")

  # use no elevation model if there is no raster.tif input data
  if (!(any_tif)) {
    elevation <- 'NONE'
    message("No raster .tif files found. Using elevation = 'NONE'.")
    }

  # check if the most recent JAR release is stored already. If it's not
  # download it

  fileurl <- fileurl_from_metadata(version)
  filename <- basename(fileurl)

  jar_file <- data.table::fifelse(
    temp_dir,
    file.path(tempdir(), filename),
    file.path(system.file("jar", package = "r5r"), filename)
  )

  if (checkmate::test_file_exists(jar_file)) {
    if (!verbose) message("Using cached R5 version from ", jar_file)
  } else {
  check  <- download_r5(version = version, temp_dir = temp_dir, quiet = !verbose)
  if (is.null(check)) {  return(invisible(NULL)) }
  }

  # start r5r and R5 JAR
  existing_files <- list.files(system.file("jar", package = "r5r"))
  r5r_jar <- file.path(
    system.file("jar", package = "r5r"),
    existing_files[grepl("r5r", existing_files)]
  )

  # r5r jar
  rJava::.jaddClassPath(path = r5r_jar)
  # R5 jar
  rJava::.jaddClassPath(path = jar_file)

  # check if data_path already has a network.dat file
  dat_file <- file.path(data_path, "network.dat")

  if (checkmate::test_file_exists(dat_file) && !overwrite) {

    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation)

    message("\nUsing cached network.dat from ", dat_file)

  } else {

    # clean up any files that might have been created by previous r5r usage
    # if the files do not exist 'file.remove()' will raise a warning, which is
    # suppressed here
    mapdb_files <- list.files(data_path)
    mapdb_files <- mapdb_files[grepl("\\.mapdb", mapdb_files)]
    suppressWarnings(
      invisible(file.remove(dat_file, mapdb_files))
    )

    # build new r5r_core
    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose, elevation)

    # display a message if there is a PBF file but no GTFS data
    if (any_pbf == TRUE & any_gtfs == FALSE) {
      message(paste("\nNo public transport data (gtfs) provided.",
                    "Graph will be built with the street network only."))
    }

    message("\nFinished building network.dat at ", dat_file)

  }

  # finish R5's setup by pre-calculating distances between transit stops and street network
  r5r_core$buildDistanceTables()

  return(r5r_core)

}
