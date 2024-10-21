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

