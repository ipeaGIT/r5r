#' Download R5 Jar file
#' 
#' @description Download a compiled version of R5 (a jar file) and
#' saves it locally. This is a compilation of R5 tailored for the
#' purposes of the package r5r but that keeps R5's essential features.
#'
#' @export
#' @family setup
#' @examples \donttest{
#'
#' library(r5r)
#'
#' download_r5()
#'
#' }
#'
download_r5 <- function(path, version){

  message(paste0('Downloading R5 version', version))

  # # Get metadata with data addresses
  # tempf <- file.path(tempdir(), "metadata.csv")
  # 
  # # check if metadata has already been downloaded
  # if (file.exists(tempf)) {
  #   metadata <- utils::read.csv(tempf, stringsAsFactors=F)
  # 
  # } else {
  #   # download it and save to metadata
  #   httr::GET(url="http://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv", httr::write_disk(tempf, overwrite = T))
  #   metadata <- utils::read.csv(tempf, stringsAsFactors=F)
  # }
  # 
  # return(metadata)
  }



download_r5 <- function(path = NULL,
                       version = "1.4.0",
                       file_name = paste0("r5-", version, "-shaded.jar"),
                       url = "http://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv",
                       quiet = FALSE,
                       cache = TRUE) {
  if (cache) {
    # Check we can find the package
    libs <- .libPaths()[1]
    if (!checkmate::test_directory_exists(file.path(libs, "r5r"))) {
      cache <- FALSE
    }
  }
  
  if (cache) {
    # Check for JAR folder can find the package
    if (!checkmate::test_directory_exists(file.path(libs, "r5r", "jar"))) {
      dir.create(file.path(libs, "r5r", "jar"))
    }
    destfile <- file.path(libs, "r5r", "jar", file_name)
    if (checkmate::test_file_exists(destfile)) {
      message("Using cached version from ", destfile)
      return(destfile)
    }
  } else {
    checkmate::assert_directory_exists(path)
    destfile <- file.path(path, file_name)
  }
  
 # UNCOMMENT url <- paste0(url, "/", version, "/otp-", version, "-shaded.jar")
  message("The OTP will be saved to ", destfile)
  utils::download.file(url = url, destfile = destfile, mode = "wb", quiet = quiet)
  return(destfile)
}
