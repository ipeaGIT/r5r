#' Get most recent JAR file url from metadata
#'
#' Returns the most recent JAR file url from metadata, depending on the version.
#'
#' @param version A string. The version of R5 to be downloaded. When `NULL`, it
#'        defaults to the latest version.
#'
#' @return A url a string.
#'
#' @family support functions
#'
#' @keywords internal
fileurl_from_metadata <- function(version = NULL) {

  # R5 version
  if(is.null(version)) {version = r5r_env$r5_jar_version}

  checkmate::assert_string(version)

  metadata <- system.file("extdata/metadata_r5r.csv", package = "r5r")
  metadata <- data.table::fread(metadata)

  # check for invalid 'version' input

  if (!(version %in% metadata$version)) {
    stop(
      "Error: Invalid value to argument 'version'. ",
      "Please use one of the following: ",
      paste(unique(metadata$version), collapse = "; ")
    )
  }

  # check which jar file to download based on the 'version' parameter

  env <- environment()
  metadata <- metadata[version == get("version", envir = env)]
  metadata <- metadata[release_date == max(release_date)]
  url <- metadata$download_path
  return(url)

}


check_transit_availability_on_date <- function(r5r_core,
                                               departure_date){

  # check services Available on the departure date
  services <- r5r_core$getTransitServicesByDate(departure_date)
  services <- java_to_dt(services)

  # count services available
  data.table::setDT(services)
  services_available <- services[, sum(active_on_date) / .N ]

  if (services_available == 0 | is.na(services_available)) {
    cli::cli_abort("There are no transit services available on the selected
                   departure date: {.val {departure_date}}. Please ensure there
                   is a GTFS in your data path & that the departure date falls
                   within the GTFS calendar."
                   )
    }


  if (services_available < 0.2) {
    cli::cli_alert_warning("Less than 20% of the transit services in the GTFS are running
                   on the selected departure date.")
  }
}


#' Initialize Java and Check Version
#'
#' Sets up Java logging for r5r and ensures Java SE Development Kit 21 is installed.
#'
#' @param data_path A character string. The directory where the log file should be saved.
#'
#' @return No return value. The function will stop execution with an error if Java 21 is not found.
#'
#' @details
#' This function initializes the Java Virtual Machine (JVM) with a log path for r5r, and checks that
#' the installed Java version is 21. If not, it stops with an informative error message and download links.
#'
#' @family support functions
#'
#' @keywords internal
start_r5r_java <- function(data_path) {
  log_filename <- paste0("r5rlog_", format(Sys.time(), "%Y%m%d"), ".log")
  log_path <- file.path(data_path, log_filename)
  rJava::.jinit(parameters = paste0("-DLOG_PATH=", log_path))
  ver <- rJava::.jcall("java.lang.System", "S", "getProperty", "java.version")
  ver <- as.numeric(gsub("\\..*", "", ver))
  if (ver != 21) {
    stop(
      "This package requires the Java SE Development Kit 21.\n",
      "Please update your Java installation. ",
      "The jdk 21 can be downloaded from either:\n",
      "  - {rJavaEnv} package: https://www.ekotov.pro/rJavaEnv/\n",
      "  - openjdk: https://jdk.java.net/java-se-ri/21\n",
      "  - oracle: https://docs.oracle.com/en/java/javase/21/install/index.html"
    )
  }

  # r5r jar
  r5r_jar <- system.file("jar/r5r.jar", package = "r5r")
  rJava::.jaddClassPath(path = r5r_jar)
}
