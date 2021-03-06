#' Download R5 Jar file
#'
#' @description Download a compiled JAR file of R5 and saves it locally.
#' The JAR file is saved within the package directory. The package uses a
#' compilation of R5 tailored for the purposes of r5r that keeps R5's
#' essential features. Source code available at https://github.com/ipeaGIT/r5r.
#'
#' @param version character string with the version of R5 to be downloaded.
#'                Defaults to latest version '6.4'.
#' @param quiet logical, passed to download.file. Defaults to FALSE
#' @param force_update logical, Replaces the jar file stored locally with a new
#'                     one. Defaults to FALSE.
#' @param temp_dir logical, whether the R5 Jar file should be saved in temporary
#'                 directory. Defaults to FALSE
#'
#' @return A jar file is saved locally in the r5r package directory
#' @family setup
#' @export
#' @examples if (interactive()) {
#'
#' library(r5r)
#'
#' download_r5(version = "6.2", temp_dir = TRUE)
#' }

download_r5 <- function(version = "6.4.0",
                        quiet = FALSE,
                        force_update = FALSE,
                        temp_dir = FALSE) {

  # check inputs ------------------------------------------------------------

  checkmate::assert_logical(quiet)
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(temp_dir)


  # set timeout options --------------------------------------------------

  old_options <- options()

  on.exit({
    options(old_options)
  })

  options(timeout=600)


  # download metadata ------------------------------------------------------------

  # download metadata with jar file addresses
  metadata <- download_metadata()

  # invalid version input
  if (!(version %in% metadata$version)){
    stop(paste0("Error: Invalid Value to argument 'version'. Please use one of the following: ",
                paste(unique(metadata$version), collapse = "; ")))
  } else {
    # generate inputs
    metadata <- metadata[metadata$version == version, ]
    metadata <- subset(metadata, release_date == max(metadata$release_date))
    url <- subset(metadata, version == version)$download_path
    file_name = basename(url)
    libs <- .libPaths()[1]
    destfile <- file.path(libs, "r5r", "jar", file_name)
  }

  # if temp_dir
  if (temp_dir) destfile <- file.path(tempdir(), file_name)

  # check cached file ----------------------------------------------------------

  # check for existing file

  if (checkmate::test_file_exists(destfile) && (force_update == FALSE)) {
    message("Using cached R5 version from ", destfile)
    return(destfile)
  } else {


  # Download JAR file ------------------------------------------------------------

    # download file if it does not exist
    if (!checkmate::test_directory_exists(file.path(libs, "r5r", "jar"))) {
      dir.create(file.path(libs, "r5r", "jar"))
    }
    message("R5 will be saved to ", destfile)
    check_connection(url)
    utils::download.file(url = url, destfile = destfile, mode = "wb", quiet = quiet)
    return(destfile)

  }
}
