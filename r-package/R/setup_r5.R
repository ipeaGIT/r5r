#' Create transport network used for routing in R5
#'
#' Combine data inputs in a directory to build a multimodal transport network
#' used for routing in R5. The directory must contain at least one street
#' network file (in .pbf format). One or more public transport data sets (in
#' GTFS.zip format) are optional. If there is more than one GTFS file in the
#' directory, both files will be merged. If there is already a 'network.dat'
#' file in the directory the function will simply read it and load it to memory.
#'
#' @param data_path character string, the directory where data inputs are stored
#'                  and where the built network.dat will be saved.
#' @param version character string, the version of R5 to be used. Defaults to
#'                latest version '6.4.0'.
#' @param verbose logical, TRUE to show detailed output messages (Default) or
#'                FALSE to show only eventual ERROR and WARNING messages.
#' @param temp_dir logical, whether the R5 Jar file should be saved in temporary
#'                 directory. Defaults to FALSE
#' @param use_elevation logical. If TRUE, load any tif files containing
#'                      elevation found in the data_path folder and calculate
#'                      impedances for walking and cycling based on street
#'                      slopes.
#' @param overwrite logical, whether to overwrite an existing `network.dat` or
#'                  to use a cached file. Defaults to FALSE (i.e. use a cached
#'                  network).
#'
#' @return An rJava object to connect with R5 routing engine
#' @family setup
#' @examples if (interactive()) {
#'
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_core <- setup_r5(data_path = path, temp_dir = TRUE)
#'
#' }
#' @export

setup_r5 <- function(data_path,
                     version = "6.4.0",
                     verbose = TRUE,
                     temp_dir = FALSE,
                     use_elevation = FALSE,
                     overwrite = FALSE) {

  # check inputs ------------------------------------------------------------

  checkmate::assert_directory_exists(data_path)
  checkmate::assert_logical(verbose)
  checkmate::assert_logical(temp_dir)
  checkmate::assert_logical(use_elevation)
  checkmate::assert_logical(overwrite)

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

  # check if data_path has osm.pbf and gtfs data, or a network.dat file
  any_network <- length(grep("network.dat", list.files(data_path))) > 0
  any_pbf  <- length(grep(".pbf", list.files(data_path))) > 0
  any_gtfs <- length(grep(".zip", list.files(data_path))) > 0

  # stop if there is no input data
  if (!(any_pbf | any_network))
    stop("\nAn OSM PBF file is required to build a network.")

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
    if (!verbose) message("Using cached version from ", jar_file)
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

    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose)

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
    r5r_core <- rJava::.jnew("org.ipea.r5r.R5RCore", data_path, verbose)

    # display a message if there is a PBF file but no GTFS data
    if (any_pbf == TRUE & any_gtfs == FALSE) {
      message(paste("\nNo public transport data (gtfs) provided.",
                    "Graph will be built with the street network only."))
    }

    message("\nFinished building network.dat at ", dat_file)

  }

  # elevation

  if (use_elevation) {
    # check for any elevation files in data_path (*.tif)
    tif_files <- list.files(
      path = data_path,
      pattern = "*.tif$",
      full.names = TRUE
    )

    # if there are any .tif files in the data_path folder, apply elevation to street network
    if (length(tif_files) > 0) {
      if (verbose)
        message(
          length(tif_files), " TIFF file(s) found in data path. ",
          "Loading elevation into street edges.\n",
          "DISCLAIMER: this is an r5r specific feature, and it will be ",
          "deprecated once native support\n",
          "for elevation data is added to R5."
        )

      apply_elevation(r5r_core, tif_files)
    }
  }

  # finish R5's setup by pre-calculating distances between transit stops and street network
  r5r_core$buildDistanceTables()

  return(r5r_core)

}
