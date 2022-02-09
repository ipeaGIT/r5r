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
  checkmate::assert_numeric(base_fare, lower = 1)
  base_fare <- as.integer(base_fare)

  # call r5r_core method ----------------------------------------------------

  f_struct <- r5r_core$buildFareStructure(base_fare, by)

  # collect and convert data returned by r5r_core
  base_fare <- f_struct$getBaseFare()
  max_discounted_transfers <- f_struct$getMaxDiscountedTransfers()
  transfer_time_allowance <- f_struct$getTransferTimeAllowance()
  fare_cap <- f_struct$getFareCap()
  if (fare_cap <= 0) { fare_cap <- Inf }

  fare_per_mode <- f_struct$getFarePerModeTable()
  fare_per_mode <- java_to_dt(fare_per_mode)

  fare_per_transfer <- f_struct$getFarePerTransferTable()
  fare_per_transfer <- java_to_dt(fare_per_transfer)

  routes_info <- f_struct$getRoutesInfoTable()
  routes_info <- java_to_dt(routes_info)

  debug <- list(
    output_file = "",
    trip_info = "MODE"
  )

  # prepare outputs ----------------------------------------------------

  fare_settings <- list(
    base_fare = base_fare,
    max_discounted_transfers = max_discounted_transfers,
    transfer_time_allowance = transfer_time_allowance,
    fare_cap = fare_cap,

    fare_per_mode = fare_per_mode,
    fare_per_transfer = fare_per_transfer,
    routes_info = routes_info,

    debug_settings = debug
  )

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


  data.table::fwrite(x = fare_structure$fare_per_mode,
                     file = file.path(tmp_dir, "fare_per_mode.csv"))

  data.table::fwrite(x = fare_structure$fare_per_transfer,
                     file = file.path(tmp_dir, "fare_per_transfer.csv"))

  data.table::fwrite(x = fare_structure$routes_info,
                     file = file.path(tmp_dir, "routes_info.csv"))

  data.table::fwrite(x = fare_debug_settings,
                     file = file.path(tmp_dir, "debug_settings.csv"))

  zip::zip(zipfile = file_path,
           files = c(
             normalizePath(file.path(tmp_dir, "global_settings.csv")),
             normalizePath(file.path(tmp_dir, "fare_per_mode.csv")),
             normalizePath(file.path(tmp_dir, "fare_per_transfer.csv")),
             normalizePath(file.path(tmp_dir, "routes_info.csv")),
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
  fare_structure$fare_per_mode <- data.table::fread(file = file.path(tmp_dir, "fare_per_mode.csv"))

  fare_structure$fare_per_transfer <- data.table::fread(file = file.path(tmp_dir, "fare_per_transfer.csv"))

  fare_structure$routes_info <-
    data.table::fread(file = file.path(tmp_dir, "routes_info.csv"),
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


