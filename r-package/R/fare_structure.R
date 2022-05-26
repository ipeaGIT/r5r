#' Setup a fare structure to calculate the monetary costs of trips
#'
#' Creates a basic fare structure that describes how transit fares should be
#' calculated in [travel_time_matrix()], [expanded_travel_time_matrix()],
#' [accessibility()] and [pareto_frontier()]. This fare structure can be
#' manually edited and adjusted to the existing rules in your study area, as
#' long as they stick to some basic premises. Please see fare structure
#' vignette for more information on how the fare structure works.
#'
#' @template r5r_core
#' @param base_fare A numeric. A base value used to populate the fare
#'   structure.
#' @param by A string. Describes how `fare_type`s (a classification we created
#'   to assign fares to different routes) are distributed among routes.
#'   Possible values are `MODE`, `AGENCY` and `GENERIC`. `MODE` is used when
#'   the mode is what determines the price of a route (e.g. if all the buses of
#'   a given city cost $5). `AGENCY` is used when the agency that operates each
#'   route is what determines its price (i.e. when two different routes/modes
#'   operated by a single agency cost the same; note that you can also use
#'   `AGENCY_NAME`, if the agency_ids listed in your GTFS cannot be easily
#'   interpreted). `GENERIC` is used when all the routes cost the same. Please
#'   note that this classification can later be edited to better suit your
#'   needs (when, for example, two types of buses cost the same, but one offers
#'   discounts after riding the subway and the other one doesn't), but this
#'   parameter may save you some work.
#' @param debug_path Either a path to a `.csv` file or `NULL`. When `NULL` (the
#'   default), fare debugging capabilities are disabled - i.e. there's no way
#'   to check if the fare calculation is correct. When a path is provided,
#'   `r5r` saves different itineraries and their respective fares to the
#'   specified file. How each itinerary is described is controlled by
#'   `debug_info`.
#' @param debug_info Either a string (when `debug_path` is a path) or `NULL`
#'   (the default). Doesn't have any effect if `debug_path` is `NULL`. When a
#'   string, accepts the values `MODE`, `ROUTE` and `MODE_ROUTE`. These values
#'   dictates how itinerary information is written to the output. Let's suppose
#'   we have an itinerary composed by two transit legs: first a subway leg
#'   whose route_id is 001, and then a bus legs whose route_id is 007. If
#'   `debug_info` is `MODE`, then this itinerary will be described as
#'   `SUBWAY|BUS`. If `ROUTE`, as `001|007`. If `MODE_ROUTE`, as `SUBWAY
#'   001|BUS 007`. Please note that the final debug information will contain
#'   not only the itineraries that were in fact used in the itineraries
#'   returned in [travel_time_matrix()], [accessibility()] and
#'   [pareto_frontier()], but all the itineraries that `R5` checked when
#'   calculating the routes. This imposes a performance penalty when tracking
#'   debug information (but has the positive effect of returning a larger
#'   sample of itineraries, which might help finding some implementation issues
#'   on the fare structure).
#'
#' @return A fare structure object.
#'
#' @family fare structure
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path)
#'
#' fare_structure <- setup_fare_structure(r5r_core, base_fare = 5)
#'
#' # to debug fare calculation
#' fare_structure <- setup_fare_structure(
#'   r5r_core,
#'   base_fare = 5,
#'   debug_path = "fare_debug.csv",
#'   debug_info = "MODE"
#' )
#'
#' fare_structure$debug_settings
#'
#' # debugging can be manually turned off by setting output_file to ""
#' fare_structure$debug_settings <- ""
#'
#' @export
setup_fare_structure <- function(r5r_core,
                                 base_fare,
                                 by = "MODE",
                                 debug_path = NULL,
                                 debug_info = NULL) {
  checkmate::assert_class(r5r_core, "jobjRef")
  checkmate::assert_numeric(base_fare, lower = 0, len = 1, any.missing = FALSE)

  by_options <- c("MODE", "AGENCY_ID", "AGENCY_NAME", "GENERIC")
  by <- toupper(by)
  checkmate::assert(
    checkmate::check_string(by),
    checkmate::check_names(by, subset.of = by_options),
    combine = "and"
  )

  checkmate::assert_string(debug_path, pattern = "\\.csv$", null.ok = TRUE)

  if (is.null(debug_path) && !is.null(debug_info)) {
    stop("Please specify a file to write debug info to with 'debug_path'.")
  } else if (!is.null(debug_path) && is.null(debug_info)) {
    debug_info <- "ROUTE"
  }

  debug_info_options <- c("MODE", "ROUTE", "MODE_ROUTE")
  checkmate::assert_string(debug_info, null.ok = TRUE)
  if (!is.null(debug_info)) {
    debug_info <- toupper(debug_info)
    checkmate::assert_names(debug_info, subset.of = debug_info_options)
  }

  # r5r_core method to build fare structure returns a json

  f_struct <- r5r_core$buildFareStructure(rJava::.jfloat(base_fare), by)
  json_string <- f_struct$toJson()

  fare_structure <- jsonlite::parse_json(json_string, simplifyVector = TRUE)

  # Inf values are not supported by Java, so we use -1 to represent them

  if (fare_structure$fare_cap <= 0) fare_structure$fare_cap <- Inf

  if (!is.null(debug_path)) {
    debug <- list(
      output_file = debug_path,
      trip_info = debug_info
    )
  } else {
    debug <- list(
      output_file = "",
      trip_info = "MODE"
    )
  }
  fare_structure$debug_settings <- debug

  data.table::setDT(fare_structure$fares_per_mode)
  data.table::setDT(fare_structure$fares_per_transfer)
  data.table::setDT(fare_structure$fares_per_route)

  return(fare_structure)
}


#' Write a fare structure object to disk
#'
#' Writes a fare structure object do disk. Fare structure is saved as a
#' collection of `.csv` files inside a `.zip` file.
#'
#' @template fare_structure
#' @param file_path A path to a `.zip` file. Where the fare structure should be
#'   written to.
#'
#' @return The path passed to `file_path`, invisibly.
#'
#' @family fare structure
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_core <- setup_r5(data_path)
#'
#' fare_structure <- setup_fare_structure(r5r_core, base_fare = 5)
#'
#' tmpfile <- tempfile("sample_fare_structure", fileext = ".zip")
#' write_fare_structure(fare_structure, tmpfile)
#'
#' @export
write_fare_structure <- function(fare_structure, file_path) {
  checkmate::assert_string(file_path, pattern = "\\.zip$", null.ok = TRUE)

  fare_global_settings <- data.table::data.table(
    setting = c(
      "max_discounted_transfers",
      "transfer_time_allowance",
      "fare_cap"
    ),
    value = c(
      fare_structure$max_discounted_transfers,
      fare_structure$transfer_time_allowance,
      fare_structure$fare_cap
    )
  )

  fare_debug_settings <- data.table::data.table(
    setting = c("output_file", "trip_info"),
    value = c(
      fare_structure$debug_settings$output_file,
      fare_structure$debug_settings$trip_info
    )
  )

  tmpdir <- tempfile(pattern = "r5r_fare_structure")
  dir.create(tmpdir)
  tmpfile <- function(path) file.path(tmpdir, path)

  data.table::fwrite(fare_global_settings, tmpfile("global_settings.csv"))
  data.table::fwrite(
    fare_structure$fares_per_mode,
    tmpfile("fares_per_mode.csv")
  )
  data.table::fwrite(
    fare_structure$fares_per_transfer,
    tmpfile("fares_per_transfer.csv")
  )
  data.table::fwrite(
    fare_structure$fares_per_route,
    tmpfile("fares_per_route.csv")
  )
  data.table::fwrite(fare_debug_settings, tmpfile("debug_settings.csv"))

  zip::zip(
    zipfile = file_path,
    files = c(
      normalizePath(tmpfile("global_settings.csv")),
      normalizePath(tmpfile("fares_per_mode.csv")),
      normalizePath(tmpfile("fares_per_transfer.csv")),
      normalizePath(tmpfile("fares_per_route.csv")),
      normalizePath(tmpfile("debug_settings.csv"))
    ),
    mode = "cherry-pick"
  )

  return(invisible(file_path))
}


#' Read a fare structure object from a file
#'
#' @param file_path A path pointing to a fare structure with a `.zip`
#'   extension.
#'
#' @return A fare structure object.
#'
#' @family fare structure
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
#' fare_structure <- read_fare_structure(path)
#'
#' @export
read_fare_structure <- function(file_path) {

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


#' Set the fare structure used when calculating transit fares
#'
#' @template r5r_core
#' @template fare_structure
#'
#' @return Invisibly returns `TRUE`. Called for side effects.
#'
#' @keywords internal
set_fare_structure <- function(r5r_core, fare_structure = NULL) {

  if (!is.null(fare_structure)) {
    if (fare_structure$fare_cap == Inf) {
      fare_structure$fare_cap <- -1
    }

    fare_settings_json <- jsonlite::toJSON(fare_structure, auto_unbox = TRUE)
    json_string <- as.character(fare_settings_json)

    r5r_core$setFareCalculator(json_string)
    r5r_core$setFareCalculatorDebugOutputSettings(fare_structure$debug_settings$output_file,
                                                  fare_structure$debug_settings$trip_info)
  } else {
    # clear fare structure settings in r5r_core
    r5r_core$dropFareCalculator()
  }

  return(invisible(TRUE))
}
