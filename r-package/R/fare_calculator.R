#' Title
#'
#' @param r5r_core
#' @param base_fare
#' @param by
#'
#' @return
#'
#' @family fare calculator
#'
#' @examples
#'
#' @export
setup_fare_calculator <- function(r5r_core,
                                  base_fare,
                                  by = "MODE") {


  # check inputs ------------------------------------------------------------

  # r5r_core
  checkmate::assert_class(r5r_core, "jobjRef")

  # max trip duration
  checkmate::assert_numeric(base_fare, lower = 0.0)

  # by MODE, AGENCY, or GENERIC
  by_options <- c("MODE", "AGENCY", "AGENCY_ID", "AGENCY_NAME", "GENERIC")
  checkmate::assert_character(by)
  by <- toupper(by)

  if (!by %chin% by_options) {
    stop(paste0(by, " is not a valid setup option.\nPlease use one of the following: ",
                paste(unique(by_options), collapse = ", ")))
  }

  # call r5r_core method ----------------------------------------------------

  f_struct <- r5r_core$buildFareStructure(rJava::.jfloat(base_fare), by)

  json_string <- f_struct$toJson()
  fare_settings <- jsonlite::parse_json(json_string, simplifyVector = TRUE)

  # Inf values are not supported by Java, so we use -1 to represent them
  if (fare_settings$fare_cap <= 0) {
    fare_settings$fare_cap <- Inf
  }

  # attach debug settings
  debug <- list(
    output_file = "",
    trip_info = "MODE"
  )

  fare_settings$debug_settings <- debug

  # convert data.frames to data.tables, for consistency
  data.table::setDT(fare_settings$fares_per_mode)
  data.table::setDT(fare_settings$fares_per_transfer)
  data.table::setDT(fare_settings$fares_per_route)

  return(fare_settings)
}


#' Write fare calculator settings to file
#'
#' @param fare_structure
#' @param file_path
#'
#' @return
#' @export
#'
#' @family fare calculator
#'
#' @examples
write_fare_calculator <- function(fare_structure, file_path) {

  # get temporary folder
  tmp_dir <- tempdir()

  fare_global_settings <- data.table::data.table(
    setting = c("base_fare",
                "max_discounted_transfers",
                "transfer_time_allowance",
                "fare_cap"),
    value = c(fare_structure$base_fare,
              fare_structure$max_discounted_transfers,
              fare_structure$transfer_time_allowance,
              fare_structure$fare_cap)
  )

  fare_debug_settings <- data.table::data.table(
    setting = c("output_file",
                "trip_info"),
    value = c(fare_structure$debug_settings$output_file,
              fare_structure$debug_settings$trip_info)
  )

  data.table::fwrite(x = fare_global_settings,
                     file = file.path(tmp_dir, "global_settings.csv"))


  data.table::fwrite(x = fare_structure$fares_per_mode,
                     file = file.path(tmp_dir, "fares_per_mode.csv"))

  data.table::fwrite(x = fare_structure$fares_per_transfer,
                     file = file.path(tmp_dir, "fares_per_transfer.csv"))

  data.table::fwrite(x = fare_structure$fares_per_route,
                     file = file.path(tmp_dir, "fares_per_route.csv"))

  data.table::fwrite(x = fare_debug_settings,
                     file = file.path(tmp_dir, "debug_settings.csv"))

  zip::zip(zipfile = file_path,
           files = c(
             normalizePath(file.path(tmp_dir, "global_settings.csv")),
             normalizePath(file.path(tmp_dir, "fares_per_mode.csv")),
             normalizePath(file.path(tmp_dir, "fares_per_transfer.csv")),
             normalizePath(file.path(tmp_dir, "fares_per_route.csv")),
             normalizePath(file.path(tmp_dir, "debug_settings.csv"))
           ),
           mode = "cherry-pick")

}


#' Read fare calculator settings from file
#'
#' @param file_path
#'
#' @return
#' @export
#'
#' @family fare calculator
#'
#' @examples
read_fare_calculator <- function(file_path) {

  # get temporary folder
  tmp_dir <- tempdir()

  # unzip fare settings file
  zip::unzip(zipfile = file_path, exdir = tmp_dir)

  # global properties
  global_settings <- data.table::fread(normalizePath(file.path(tmp_dir, "global_settings.csv")))

  fare_structure <- as.list(global_settings$value)
  names(fare_structure) <- global_settings$setting

  # load individual data.frames
  fare_structure$fares_per_mode <- data.table::fread(file = file.path(tmp_dir, "fares_per_mode.csv"))

  fare_structure$fares_per_transfer <- data.table::fread(file = file.path(tmp_dir, "fares_per_transfer.csv"))

  fare_structure$fares_per_route <-
    data.table::fread(file = file.path(tmp_dir, "fares_per_route.csv"),
                      colClasses = list(character = c("agency_id",
                                                      "agency_name",
                                                      "route_id",
                                                      "route_short_name",
                                                      "route_long_name",
                                                      "mode",
                                                      "fare_type")))

  # debug settings
  debug_options <- data.table::fread(normalizePath(file.path(tmp_dir, "debug_settings.csv")))

  debug_settings <- as.list(debug_options$value)
  names(debug_settings) <- debug_options$setting

  fare_structure$debug_settings <- debug_settings


  return(fare_structure)
}

#' Title
#'
#' @param r5r_core
#' @param fare_calculator_settings
#' @param max_fare
#' @param fare_cutoffs
#'
#' @return
#' @export
#'
#' @examples
set_fare_calculator <- function(r5r_core,
                                fare_calculator_settings = NULL,
                                max_fare = Inf,
                                fare_cutoffs = Inf) {

  # max fare
  checkmate::assert_numeric(max_fare)

  # monetary costs
  checkmate::assert_numeric(fare_cutoffs)

  if (!is.null(fare_calculator_settings)) {
    if (fare_calculator_settings$fare_cap == Inf) {
      fare_calculator_settings$fare_cap = -1
    }

    # Inf and NULL values are not allowed in Java,
    # so -1 is used to indicate max_fare is unconstrained
    if (max_fare != Inf) {
      r5r_core$setMaxFare(rJava::.jfloat(max_fare))
    } else {
      r5r_core$setMaxFare(rJava::.jfloat(-1.0))
    }

    # Inf and NULL values are not allowed in Java,
    # so -1 is used to indicate fare_cutoffs is unconstrained
    if (fare_cutoffs != Inf) {
      r5r_core$setFareCutoffs(rJava::.jfloat(fare_cutoffs))
    } else {
      r5r_core$setFareCutoffs(rJava::.jfloat(-1.0))
    }

    fare_settings_json <- jsonlite::toJSON(fare_calculator_settings, auto_unbox = TRUE)
    json_string <- as.character(fare_settings_json)

    r5r_core$setFareCalculator(json_string)
    r5r_core$setMaxFare(rJava::.jfloat(max_fare))
    r5r_core$setFareCalculatorDebugOutputSettings(fare_calculator_settings$debug_settings$output_file,
                                                  fare_calculator_settings$debug_settings$trip_info)
  } else {
    # clear fare calculator settings in r5r_core
    r5r_core$dropFareCalculator()
  }

}


