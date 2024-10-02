#' Download `R5.jar`
#'
#' Downloads `R5.jar` and saves it locally, inside the package directory.
#'
#' @param version A string. The version of R5 to be downloaded. When `NULL`, it
#'        defaults to the latest version.
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
#' download_r5(temp_dir = TRUE)
#' @export
download_r5 <- function(version = NULL,
                        quiet = FALSE,
                        force_update = FALSE,
                        temp_dir = FALSE) {

  # R5 version
  if(is.null(version)) {version = r5r_env$r5_jar_version}


  # check inputs ----------------------------------------------------------

  checkmate::assert_logical(quiet)
  checkmate::assert_logical(force_update)
  checkmate::assert_logical(temp_dir)


  # set timeout options ---------------------------------------------------

  old_options <- options()
  on.exit(options(old_options), add = TRUE)

  options(timeout = max(600, getOption("timeout")))


  # download R5 jar -----------------------------------------------------

  if (!dir.exists(r5r_env$cache_dir)) {dir.create(r5r_env$cache_dir, recursive = TRUE)}

  file_url <- fileurl_from_metadata(version)
  filename <- basename(file_url)

  jar_file <- data.table::fifelse(
    temp_dir,
    file.path(tempdir(), filename),
    file.path( r5r_env$cache_dir , filename)
  )

  # check if the file exists and is not corrupted
  if (file.exists(jar_file) && file.info(jar_file)$size < r5r_env$r5_jar_size && isFALSE(force_update)) {
    stop(message("R5 Jar file is corrupted. To fix this problem, download it again with 'r5r::download_r5(force_update = TRUE)'"))
  }

  # check if the file exists, and returns its path if it does. otherwise,
  # download it from IPEA's server - if there's no internet connection "fail
  # gracefully" (i.e invisibly returns NULL and outputs a informative message)"
  if (file.exists(jar_file) && (force_update == FALSE)) {
    if (!quiet) message("Using cached R5 version from ", jar_file)
    return(jar_file)
  }

  # download JAR
  message("Downloading R5 jar file to ", jar_file)

  try(silent = TRUE,
      utils::download.file(
        url = file_url,
        destfile = jar_file,
        mode = "wb",
        # method = "curl",
        # extra = "--insecure",
        quiet = quiet
      )
  )

  # try(silent = TRUE,
  #     httr::GET(url=file_url,
  #               if(isFALSE(quiet)){ httr::progress()},
  #               httr::write_disk(jar_file, overwrite = TRUE),
  #               config = httr::config(ssl_verifypeer = FALSE))
  # )


# Halt function if download failed (file must exist and be larger than 60 MB)
if (!file.exists(jar_file) | file.info(jar_file)$size < r5r_env$r5_jar_size) {
  message('Internet connection not working properly.')
  return(invisible(NULL))
  }

  return(jar_file)

}
