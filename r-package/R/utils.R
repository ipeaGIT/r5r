
#' Assert travel times breakdown stat parameter value
#'
#' @param breakdown_stat Name of statistic function (minimum or average/mean).
#'
#' @return A character with the validated statistic function name.
#' @family support functions
#'
#' @keywords internal
assert_breakdown_stat <- function(breakdown_stat) {
  # list of all decay functions
  stat_functions  <- c('MIN', 'MINIMUM', 'MEAN', 'AVG', 'AVERAGE')

  # check if decay_function is valid
  checkmate::assert_character(breakdown_stat)
  breakdown_stat <- toupper(breakdown_stat)

  if (!breakdown_stat %chin% stat_functions) {
    stop(paste0(breakdown_stat, " is not a valid 'statistic function'.\nPlease use one of the following: ",
                paste(unique(stat_functions), collapse = ", ")))
  }

  return(breakdown_stat)
}


#' Set suboptimal minutes
#'
#' @description Set suboptimalMinutes parameter in R5.
#'
#' @template r5r_core
#' @param suboptimal_minutes numeric. The number of suboptimal minutes in a public transport
#'                  point-to-point query. From R5's documentation:
#'                  This parameter compensates for the fact that GTFS does not
#'                  contain information about schedule deviation (lateness).
#'                  The min-max travel time range for some trains is zero, since
#'                  the trips are reported to always have the same timings in the
#'                  schedule. Such an option does not overlap (temporally) its
#'                  alternatives, and is too easily eliminated by an alternative
#'                  that is only marginally better. We want to effectively push
#'                  the max travel time of alternatives out a bit to account for
#'                  the fact that they don't always run on schedule.
#'
#' @return No return value, called for side effects.
#' @family support functions
#'
#' @keywords internal
set_suboptimal_minutes <- function(r5r_core, suboptimal_minutes) {

  checkmate::assert_numeric(suboptimal_minutes)

  # R5 defaults subOptimalMinutes to 5L
  if (is.infinite(suboptimal_minutes)) suboptimal_minutes <- 5L

  r5r_core$setSuboptimalMinutes(as.integer(suboptimal_minutes))

}


#' Get most recent JAR file url from metadata
#'
#' Returns the most recent JAR file url from metadata, depending on the version.
#'
#' @param version A string, the version of R5's to get the filename of.
#'
#' @return The a url a string.
#'
#' @family support functions
#'
#' @keywords internal
fileurl_from_metadata <- function(version) {

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


#' Check internet connection with Ipea server
#'
#' @description
#' Checks if there is internet connection to Ipea server to download r5r data.
#'
#' @param file_url A string with the file_url address of an geobr dataset
#'
#' @return Logical. `TRUE` if url is working, `FALSE` if not.
#' @family support functions
#'
#' @keywords internal
check_connection <- function(file_url = 'https://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv'){

  # file_url <- 'http://google.com/'               # ok
  # file_url <- 'http://www.google.com:81/'   # timeout
  # file_url <- 'http://httpbin.org/status/300' # error

  # check if user has internet connection
  if (!curl::has_internet()) { message("\nNo internet connection.")
    return(FALSE)
  }

  # message
  msg <- "Problem connecting to data server. Please try it again in a few minutes."

  # test server connection
  x <- try(silent = TRUE,
           httr::GET(file_url, # timeout(5),
                     config = httr::config(ssl_verifypeer = FALSE)))
  # link offline
  if (class(x)[1]=="try-error") {
    message( msg )
    return(FALSE)
  }

  # link working fine
  else if ( identical(httr::status_code(x), 200L)) {
    return(TRUE)
  }

  # link not working or timeout
  else if (! identical(httr::status_code(x), 200L)) {
    message(msg )
    return(FALSE)

  } else if (httr::http_error(x) == TRUE) {
    message(msg)
    return(FALSE)
  }

}

