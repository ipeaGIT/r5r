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
#' download_r5(version = "6.4.0", temp_dir = TRUE)
#' }

download_r5 <- function(version = "6.4.0",
                        quiet = FALSE,
                        force_update = FALSE,
                        temp_dir = FALSE) {

  # check inputs ----------------------------------------------------------

  checkmate::assert_logical(quiet)
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(temp_dir)


  # set timeout options ---------------------------------------------------

  old_options <- options()
  on.exit(options(old_options), add = TRUE)

  options(timeout = max(600, getOption("timeout")))


  # download metadata -----------------------------------------------------

  # download metadata with jar file addresses
  metadata <- download_metadata()

  # invalid version input
  if (!(version %in% metadata$version)) {
    stop(
      "Error: Invalid value to argument 'version'. ",
      "Please use one of the following: ",
      paste(unique(metadata$version), collapse = "; ")
    )
  }

  # generate inputs
  metadata <- metadata[metadata$version == version, ]
  metadata <- subset(metadata, release_date == max(metadata$release_date))
  url <- subset(metadata, version == version)$download_path
  file_name <- basename(url)
  destfile <- file.path(system.file("jar", package = "r5r"), file_name)

  # if temp_dir
  if (temp_dir) destfile <- file.path(tempdir(), file_name)

  # download R5's jar -----------------------------------------------------

  # check if the file exists, and returns its path if it does. otherwise,
  # download it from IPEA's server - if there's no internet connection "fail
  # gracefully" (i.e invisibly returns NULL and outputs a informative message)"

  if (file.exists(destfile) && (force_update == FALSE)) {
    if (!quiet) message("Using cached R5 version from ", destfile)
    return(destfile)
  }

  if (!check_connection(url)) {
    if (!quiet)
      message(
        "Problem connecting to the data server. ",
        "Please try again in a few minutes."
      )
    return(invisible(NULL))
  }

  jar_dir <- system.file("jar", package = "r5r")
  if (!dir.exists(jar_dir)) dir.create(jar_dir)

  if (!quiet) message("R5 will be saved to ", destfile)
  utils::download.file(
    url = url,
    destfile = destfile,
    mode = "wb",
    quiet = quiet
  )

  return(destfile)

}
