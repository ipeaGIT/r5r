#' Download `R5.jar`
#'
#' Downloads `R5.jar` and saves it locally, inside the package directory.
#'
#' @param version A string. The version of R5 to be downloaded. Defaults to the
#'   latest version.
#' @param quiet A logical. Whether to show informative messages when downloading
#'   the file. Defaults to `FALSE`.
#' @param force_update A logical. Whether to overwrite a previously downloaded
#'   `R5.jar` in the local directory. Defaults to `FALSE`.
#' @param temp_dir A logical. Whether the file should be saved in a temporary
#'   directory. Defaults to `FALSE`.
#'
#' @return The path to the downloaded file.
#'
#' @family setup
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' download_r5(version = "6.8.0", temp_dir = TRUE)
#' @export
download_r5 <- function(version = "6.8.0",
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


  # download R5's jar -----------------------------------------------------

  file_url <- fileurl_from_metadata(version)
  filename <- basename(file_url)

  destfile <- data.table::fifelse(
    temp_dir,
    file.path(tempdir(), filename),
    file.path(system.file("jar", package = "r5r"), filename)
  )

  # check if the file exists, and returns its path if it does. otherwise,
  # download it from IPEA's server - if there's no internet connection "fail
  # gracefully" (i.e invisibly returns NULL and outputs a informative message)"

  if (file.exists(destfile) && (force_update == FALSE)) {
    if (!quiet) message("Using cached R5 version from ", destfile)
    return(destfile)
  }

  if (isFALSE(check_connection(file_url))) {
    # if (!quiet)
    #   message(
    #     "Problem connecting to the data server. ",
    #     "Please try again in a few minutes."
    #   )
    return(invisible(NULL))
  }

  # create dir
  jar_dir <- system.file("jar", package = "r5r")
  if (!dir.exists(jar_dir)) dir.create(jar_dir)

  # download JAR
  message("Downloading R5 jar file to ", destfile)
  utils::download.file(
    url = file_url,
    destfile = destfile,
    mode = "wb",
    # method = "curl",
    # extra = "--insecure",
    quiet = quiet
  )

  return(destfile)

}
