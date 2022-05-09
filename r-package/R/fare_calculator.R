#' Setup a fare calculator to use with routing functions
#'
#' @template r5r_core
#' @param base_fare A numeric.
#' @param by A string.
#'
#' @return A fare calculator object.
#'
#' @family fare calculator
#'
#' @examplesIf interactive()
#'
#' @export
setup_fare_calculator <- function(r5r_core, base_fare, by = "MODE") {
  checkmate::assert_class(r5r_core, "jobjRef")
  checkmate::assert_numeric(base_fare, lower = 0.0)

  by_options <- c("MODE", "AGENCY_ID", "AGENCY_NAME", "GENERIC")
  by <- toupper(by)
  checkmate::assert(
    checkmate::check_string(by),
    checkmate::assert_names(by, subset.of = by_options),
    combine = "and"
  )

  # call r5r_core method ----------------------------------------------------

  f_struct <- r5r_core$buildFareStructure(rJava::.jfloat(base_fare), by)

  json_string <- f_struct$toJson()
  fare_calculator <- jsonlite::parse_json(json_string, simplifyVector = TRUE)

  # Inf values are not supported by Java, so we use -1 to represent them
  if (fare_calculator$fare_cap <= 0) {
    fare_calculator$fare_cap <- Inf
  }

  # attach debug settings
  debug <- list(
    output_file = "",
    trip_info = "MODE"
  )

  fare_calculator$debug_settings <- debug

  data.table::setDT(fare_calculator$fares_per_mode)
  data.table::setDT(fare_calculator$fares_per_transfer)
  data.table::setDT(fare_calculator$fares_per_route)

  return(fare_calculator)
}


#' Write a fare calculator object to disk
#'
#' @param fare_calculator A fare calculator object, following the convention
#' set in [setup_fare_calculator()].
#' @param file_path A string.
#'
#' @return The path passed to `file_path`, invisibly.
#'
#' @family fare calculator
#'
#' @examplesIf interactive()
#'
#' @export
write_fare_calculator <- function(fare_calculator, file_path) {

  # get temporary folder
  tmp_dir <- tempdir()

  fare_global_settings <- data.table::data.table(
    setting = c("base_fare",
                "max_discounted_transfers",
                "transfer_time_allowance",
                "fare_cap"),
    value = c(fare_calculator$base_fare,
              fare_calculator$max_discounted_transfers,
              fare_calculator$transfer_time_allowance,
              fare_calculator$fare_cap)
  )

  fare_debug_settings <- data.table::data.table(
    setting = c("output_file",
                "trip_info"),
    value = c(fare_calculator$debug_settings$output_file,
              fare_calculator$debug_settings$trip_info)
  )

  data.table::fwrite(x = fare_global_settings,
                     file = file.path(tmp_dir, "global_settings.csv"))


  data.table::fwrite(x = fare_calculator$fares_per_mode,
                     file = file.path(tmp_dir, "fares_per_mode.csv"))

  data.table::fwrite(x = fare_calculator$fares_per_transfer,
                     file = file.path(tmp_dir, "fares_per_transfer.csv"))

  data.table::fwrite(x = fare_calculator$fares_per_route,
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


#' Read a fare calculator object from a file
#'
#' @param file_path A string.
#'
#' @return A fare calculator object.
#'
#' @family fare calculator
#'
#' @examplesIf interactive()
#' path <- system.file("inst/extdata/poa/fares/fares_poa.zip", package = "r5r")
#' fare_calculator <- read_fare_calculator(path)
#'
#' @export
read_fare_calculator <- function(file_path) {

  # get temporary folder
  tmp_dir <- tempdir()

  # unzip fare settings file
  zip::unzip(zipfile = file_path, exdir = tmp_dir)

  # global properties
  global_settings <- data.table::fread(normalizePath(file.path(tmp_dir, "global_settings.csv")))

  fare_calculator <- as.list(global_settings$value)
  names(fare_calculator) <- global_settings$setting

  # load individual data.frames
  fare_calculator$fares_per_mode <- data.table::fread(file = file.path(tmp_dir, "fares_per_mode.csv"))

  fare_calculator$fares_per_transfer <- data.table::fread(file = file.path(tmp_dir, "fares_per_transfer.csv"))

  fare_calculator$fares_per_route <-
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

  fare_calculator$debug_settings <- debug_settings


  return(fare_calculator)
}

#' Title
#'
#' @template r5r_core
#' @param fare_calculator
#'
#' @return
#'
#' @examples
#'
#' @keywords internal
set_fare_calculator <- function(r5r_core, fare_calculator = NULL) {

  if (!is.null(fare_calculator)) {
    if (fare_calculator$fare_cap == Inf) {
      fare_calculator$fare_cap <- -1
    }

    fare_settings_json <- jsonlite::toJSON(fare_calculator, auto_unbox = TRUE)
    json_string <- as.character(fare_settings_json)

    r5r_core$setFareCalculator(json_string)
    r5r_core$setFareCalculatorDebugOutputSettings(fare_calculator$debug_settings$output_file,
                                                  fare_calculator$debug_settings$trip_info)
  } else {
    # clear fare calculator settings in r5r_core
    r5r_core$dropFareCalculator()
  }

}
