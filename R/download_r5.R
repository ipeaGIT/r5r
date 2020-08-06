#' Download R5 .jar file
#'
#' The function downloads a compiled version of R5 (a j.ar file) and
#' saves it locally. This is a compilation of R5 tailored for the
#' purposes of the package r5r but that keeps R5's essential features.
#'
#' @export
#' @family general support functions
#' @examples \donttest{
#'
#' library(r5r)
#'
#' download_r5()
#'
#' }
#'
download_r5 <- function(version){

  message(paste0('Downloading R5 version', version))

  # Get metadata with data addresses
  tempf <- file.path(tempdir(), "metadata.csv")

  # check if metadata has already been downloaded
  if (file.exists(tempf)) {
    metadata <- utils::read.csv(tempf, stringsAsFactors=F)

  } else {
    # download it and save to metadata
    httr::GET(url="http://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv", httr::write_disk(tempf, overwrite = T))
    metadata <- utils::read.csv(tempf, stringsAsFactors=F)
  }

  return(metadata)
  }
