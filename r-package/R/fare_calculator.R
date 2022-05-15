#' Setup a fare calculator to account for monetary costs in routing and accessibility functions
#'
#' Creates a basic fare calculator that describes how transit fares should be
#' calculated in [travel_time_matrix()], [expanded_travel_time_matrix()],
#' [accessibility()] and [pareto_frontier()]. This fare calculator can be
#' manually edited and adjusted to the existing rules in your study area, as
#' long as they stick to some basic premises. Please see fare calculator
#' vignette for more information on how the fare calculator works.
#'
#' @template r5r_core
#' @param base_fare A numeric. A base value used to populate the fare
#' calculator.
#' @param by A string. Describes how `fare_type`s (a classification we created
#' to assign fares to different routes) are distributed among routes. Possible
#' values are `MODE`, `AGENCY` and `GENERIC`. `MODE` is used when the mode is
#' what determines the price of a route (e.g. if all the buses of a given city
#' cost $5). `AGENCY` is used when the agency that operates each route is what
#' determines its price (i.e. when two different routes/modes operated by a
#' single agency cost the same; note that you can also use `AGENCY_NAME`, if
#' the agency_ids listed in your GTFS cannot be easily interpreted). `GENERIC`
#' is used when all the routes cost the same. Please note that this
#' classification can later be edited to better suit your needs (when, for
#' example, two types of buses cost the same, but one offers discounts after
#' riding the subway and the other one doesn't), but this parameter may save
#' you some work.
#' @param debug_path Either a path to a `.csv` file or `NULL`. When `NULL` (the
#' default), fare debugging capabilities are disabled - i.e. there's no way to
#' check if the fare calculation is correct. When a path is provided, `r5r`
#' saves different itineraries and their respective fares to the specified
#' file. How each itinerary is described is controlled by `debug_info`.
#' @param debug_info Either a string (when `debug_path` is a path) or `NULL`
#' (the default). Doesn't have any effect if `debug_path` is `NULL`. When a
#' string, accepts the values `MODE`, `ROUTE` and `MODE_ROUTE`. These values
#' dictates how itinerary information is written to the output. Let's suppose
#' we have an itinerary composed by two transit legs: first a subway leg whose
#' route_id is 001, and then a bus legs whose route_id is 007. If `debug_info`
#' is `MODE`, then this itinerary will be described as `SUBWAY|BUS`. If
#' `ROUTE`, as `001|007`. If `MODE_ROUTE`, as `SUBWAY 001|BUS 007`. Please note
#' that the final debug information will contain not only the itineraries that
#' were in fact used in the itineraries returned in [travel_time_matrix()],
#' [accessibility()] and [pareto_frontier()], but all the itineraries that `R5`
#' checked when calculating the routes. This imposes a performance penalty when
#' tracking debug information (but has the positive effect of returning a
#' larger sample of itineraries, which might help finding some implementation
#' issues on the fare calculator).
#'
#' @return A fare calculator object.
#'
#' @family fare calculator
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path)
#'
#' fare_calculator <- setup_fare_calculator(r5r_core, base_fare = 5)
#'
#' # to debug fare calculation
#' fare_calculator <- setup_fare_calculator(
#'   r5r_core,
#'   base_fare = 5,
#'   debug_path = "fare_debug.csv",
#'   debug_info = "MODE"
#' )
#'
#' fare_calculator$debug_settings
#'
#' # debugging can be manually turned off by setting output_file to ""
#' fare_calculator$debug_settings <- ""
#'
#' @export
setup_fare_calculator <- function(r5r_core,
                                  base_fare,
                                  by = "MODE",
                                  debug_path = NULL,
                                  debug_info = NULL) {
  checkmate::assert_class(r5r_core, "jobjRef")
  checkmate::assert_numeric(base_fare, lower = 0.0)

  by_options <- c("MODE", "AGENCY_ID", "AGENCY_NAME", "GENERIC")
  by <- toupper(by)
  checkmate::assert(
    checkmate::check_string(by),
    checkmate::check_names(by, subset.of = by_options),
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
#' Writes a fare calculator object do disk. Fare calculators are saved as a
#' collection of `.csv` files inside a `.zip` file.
#'
#' @template fare_calculator
#' @param file_path A path to a `.zip` file. Where the fare calculator should be
#' written to.
#'
#' @return The path passed to `file_path`, invisibly.
#'
#' @family fare calculator
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path)
#'
#' fare_calculator <- setup_fare_calculator(r5r_core, base_fare = 5)
#'
#' tmpfile <- tempfile("sample_fare_calculator", fileext = ".zip")
#' write_fare_calculator(fare_calculator, tmpfile)
#'
#' @export
write_fare_calculator <- function(fare_calculator, file_path) {

  # get temporary folder
  tmp_dir <- tempdir()

  fare_global_settings <- data.table::data.table(
    setting = c("max_discounted_transfers",
                "transfer_time_allowance",
                "fare_cap"),
    value = c(fare_calculator$max_discounted_transfers,
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
#' @param file_path A path pointing to a fare calculator with a `.zip`
#' extension.
#'
#' @return A fare calculator object.
#'
#' @family fare calculator
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
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


#' Set the fare calculator used when calculating transit fares
#'
#' @template r5r_core
#' @template fare_calculator
#'
#' @return Invisibly returns `TRUE`. Called for side effects.
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

  return(invisible(TRUE))
}
