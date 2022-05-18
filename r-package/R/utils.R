#' Set verbose argument
#'
#' R5 error messages are still reported even when `verbose` is `FALSE`.
#'
#' @template r5r_core
#'
#' @param verbose A logical, passed from function above.
#'
#' @return No return value, called for side effects.
#'
#' @family support functions
#'
#' @keywords internal
set_verbose <- function(r5r_core, verbose) {
  checkmate::assert_logical(verbose, len = 1, any.missing = FALSE)

  if (verbose) r5r_core$verboseMode()
  else r5r_core$silentMode()
}


#' Set progress argument
#'
#' Indicates whether or not a progress counter must be printed during
#' computations. Applies to all routing functions.
#'
#' @template r5r_core
#' @param progress A logical, passed from function above.
#'
#' @return No return value, called for side effects.
#'
#' @family support functions
#'
#' @keywords internal
set_progress <- function(r5r_core, progress) {
  checkmate::assert_logical(progress, len = 1)

  r5r_core$setProgress(progress)
}


#' Set max street time
#'
#' Converts a time duration and speed input and converts it to distances.
#'
#' @param max_walk_dist A numeric of length 1. Maximum walking distance (in
#'   meters) for the whole trip. Passed from routing functions.
#' @param walk_speed A numeric of length 1. Average walk speed in km/h.
#'   Defaults to 3.6 Km/h. Passed from routing functions.
#' @param max_trip_duration A numeric of length 1. Maximum trip duration in
#'   seconds. Defaults to 120 minutes (2 hours). Passed from routing functions.
#'
#' @return An `integer` representing the maximum number of minutes walking.
#'
#' @family support functions
#'
#' @keywords internal
set_max_street_time <- function(max_walk_dist, walk_speed, max_trip_duration) {
  checkmate::assert_number(max_walk_dist)
  checkmate::assert_number(walk_speed)

  if (walk_speed == 0) {
    stop("Assertion on speed failed: must have value greater than 0.")
  }

  if (is.infinite(max_walk_dist)) return(as.integer(max_trip_duration))

  max_street_time <- as.integer(
    round(60 * max_walk_dist / (walk_speed * 1000), digits = 0)
  )

  if (max_street_time == 0) {
    stop(
      "'max_walk_dist' is too low. ",
      "Please make sure distances are in meters, not kilometers."
    )
  }

  # if max_street_time ends up being higher than max_trip_duration, uses
  # max_trip_duration as a ceiling

  if (max_street_time > max_trip_duration) max_street_time <- max_trip_duration

  return(as.integer(max_street_time))
}


#' Select transport mode
#'
#' @param mode A character vector, passed from routing functions.
#' @param mode_egress A character vector, passed from routing functions.
#'
#' @return A list with the transport modes to be used in the routing.
#'
#' @family support functions
#'
#' @keywords internal
select_mode <- function(mode, mode_egress) {
  dr_modes <- c("WALK", "BICYCLE", "CAR", "BICYCLE_RENT", "CAR_PARK")
  tr_modes <- c(
    "TRANSIT",
    "TRAM",
    "SUBWAY",
    "RAIL",
    "BUS",
    "FERRY",
    "CABLE_CAR",
    "GONDOLA",
    "FUNICULAR"
  )
  all_modes <- c(tr_modes, dr_modes)

  # check for invalid input

  mode <- toupper(unique(mode))
  mode_egress <- toupper(unique(mode_egress))

  checkmate::assert(
    checkmate::check_character(mode, min.len = 1),
    checkmate::check_names(mode, subset.of = all_modes),
    combine = "and"
  )
  checkmate::assert(
    checkmate::check_string(mode_egress),
    checkmate::check_names(
      mode_egress,
      subset.of = setdiff(dr_modes, c("CAR_PARK", "BICYCLE_RENT"))
    ),
    combine = "and"
  )

  # assign modes accordingly

  direct_modes <- mode[which(mode %in% dr_modes)]
  transit_modes <- mode[which(mode %in% tr_modes)]

  if (length(direct_modes) > 1) {
    stop(
      "Please use only of {",
      paste0("'", direct_modes, "'", collapse = ","),
      "} when routing."
    )
  }

  if (any(c("CAR_PARK", "BICYCLE_RENT") %in% direct_modes)) {
    stop("CAR_PARK and BICYCLE_RENT are currently unsupported by r5r.")
  }

  access_mode <- direct_modes

  if (length(transit_modes) == 0) {
    transit_modes <- ""
    egress_mode <- ""
  } else {
    if ("TRANSIT" %in% transit_modes) transit_modes <- tr_modes

    # if only transit mode is passed, assume "WALK" as access_mode
    if (length(direct_modes) == 0) access_mode <- direct_modes <- "WALK"

    egress_mode <- mode_egress
  }

  mode_list <- list(
    direct_modes = paste0(direct_modes, collapse = ";"),
    transit_mode = paste0(transit_modes, collapse = ";"),
    access_mode = paste0(access_mode, collapse = ";"),
    egress_mode = egress_mode
  )

  return(mode_list)
}



#' Generate date and departure time strings from POSIXct
#'
#' @param datetime An object of POSIXct class.
#'
#' @return A list with the `date` and `time` of the trip departure as
#'   characters.
#'
#' @family support functions
#'
#' @keywords internal
posix_to_string <- function(datetime) {
  checkmate::assert_posixct(
    datetime,
    len = 1,
    .var.name = "departure_datetime"
  )

  tz <- attr(datetime, "tzone")
  if (is.null(tz)) tz <- ""

  datetime_list <- list(
    date = strftime(datetime, format = "%Y-%m-%d", tz = tz),
    time = strftime(datetime, format = "%H:%M:%S", tz = tz)
  )

  return(datetime_list)
}


#' Assert class of origin and destination inputs and the type of its columns
#'
#' @param df Any object.
#' @param name Object name.
#'
#' @return A `data.frame` with columns `id`, `lon` and `lat`.
#'
#' @family support functions
#'
#' @keywords internal
assert_points_input <- function(df, name) {
  if ("data.frame" %in% class(df)) {
    if ("sf" %in% class(df)) {
      if (
        as.character(sf::st_geometry_type(df, by_geometry = FALSE)) != "POINT"
      ) {
        stop("'", name, "' must be either a 'data.frame' or a 'POINT sf'.")
      }

      if (sf::st_crs(df) != sf::st_crs(4326)) {
        stop(
          "'", name, "' CRS must be WGS 84 (EPSG 4326). ",
          "Please use either sf::set_crs() to set it or ",
          "sf::st_transform() to reproject it."
        )
      }

      df <- sfheaders::sf_to_df(df, fill = TRUE)
      data.table::setDT(df)
      data.table::setnames(df, "x", "lon")
      data.table::setnames(df, "y", "lat")
    }

    checkmate::assert_names(
      names(df),
      must.include = c("id", "lat", "lon"),
      .var.name = name
    )
    checkmate::assert_numeric(df$lon, .var.name = paste0(name, "$lon"))
    checkmate::assert_numeric(df$lat, .var.name = paste0(name, "$lat"))

    if (!is.character(df$id)) {
      df$id <- as.character(df$id)
      warning(paste0("'", name, "$id' forcefully cast to character."))
    }

    return(df)
  }

  stop(paste0("'", name, "' must be either a 'data.frame' or a 'POINT sf'."))
}


#' Assert decay function and parameter values
#'
#' @param decay_function Name of decay function.
#' @param decay_value Value of decay parameter.
#'
#' @return A `list` with the validated decay function and parameter value.
#' @family support functions
#'
#' @keywords internal
assert_decay_function <- function(decay_function, decay_value) {
  # list of all decay functions
  decay_functions  <- c('STEP','EXPONENTIAL','FIXED_EXPONENTIAL','LINEAR','LOGISTIC')

  # check if decay_function is valid
  checkmate::assert_character(decay_function)
  decay_function <- toupper(decay_function)

  if (!decay_function %chin% decay_functions) {
    stop(paste0(decay_function, " is not a valid 'decay function'.\nPlease use one of the following: ",
                paste(unique(decay_functions), collapse = ", ")))
  }

  # check if decay_value is numeric and within correct bounds
  checkmate::assert_numeric(decay_value)
  decay_value <- as.double(decay_value)

  if (decay_function %chin% c("FIXED_EXPONENTIAL")) {
    if (decay_value <= 0 | decay_value >= 1) {
      stop(paste0(decay_value, " is not a valid decay_value parameter for the FIXED EXPONENTIAL decay function.\n",
                  "Please enter a value between 0 and 1 (exclusive)."))
    }
  }

  if (decay_function %chin% c("LOGISTIC", "LINEAR")) {
    if (decay_value < 1) {
      stop(paste0(decay_value, " is not a valid decay_value parameter for the ", decay_function, " decay function.\n",
                  "Please enter a value greater than or equal to 1."))
    }
  }

  decay_list <- list("fun" = decay_function, "value" = decay_value)
  return(decay_list)
}

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


#' Set number of threads
#'
#' @description Sets number of threads to be used by the r5r .jar.
#'
#' @param n_threads A number.
#'
#' @return No return value, called for side effects.
#'
#' @family support functions
#'
#' @keywords internal
set_n_threads <- function(r5r_core, n_threads) {
  checkmate::assert_number(n_threads, lower = 1)

  if (is.infinite(n_threads)) {
    r5r_core$setNumberOfThreadsToMax()
  } else {
    n_threads <- as.integer(n_threads)
    r5r_core$setNumberOfThreads(n_threads)
  }
}


#' Set walk and bike speed
#'
#' @description This function receives the walk and bike 'speed' inputs in Km/h
#' from routing functions above and converts them to meters per second, which is
#' then used to set these speed profiles in r5r JAR.
#'
#' @template r5r_core
#' @param speed A numeric representing the speed in km/h.
#' @param mode Either \code{"bike"} or \code{"walk"}.
#'
#' @return No return value, called for side effects.
#' @family support functions
#'
#' @keywords internal
set_speed <- function(r5r_core, speed, mode) {

  checkmate::assert_numeric(speed, .var.name = paste0(mode, "_speed"))

  # convert from km/h to m/s
  speed <- speed * 5 / 18

  if (mode == "walk") r5r_core$setWalkSpeed(speed)
  else r5r_core$setBikeSpeed(speed)

}


#' Set max Level of Transit Stress (LTS)
#'
#' @template r5r_core
#' @param max_lts A number (between 1 and 4). The maximum level of traffic
#'   stress that cyclists will tolerate. A value of 1 means cyclists will only
#'   travel through the quietest streets, while a value of 4 indicates cyclists
#'   can travel through any road.
#'
#' @return No return value, called for side effects.
#'
#' @family support functions
#'
#' @keywords internal
set_max_lts <- function(r5r_core, max_lts) {
  checkmate::assert_number(max_lts)

  if (max_lts < 1 | max_lts > 4) {
    stop(
      max_lts,
      " is not a valid value for the maximum Level of Transit Stress (LTS).\n",
      "Please enter a value between 1 and 4."
    )
  }

  r5r_core$setMaxLevelTrafficStress(as.integer(max_lts))
}


#' Set max number of transfers
#'
#' @description Set maxTransfers parameter in R5.
#'
#' @template r5r_core
#' @param max_rides numeric. The max number of public transport rides
#'                  allowed in the same trip. Passed from routing function.
#'
#' @return No return value, called for side effects.
#' @family support functions
#'
#' @keywords internal
set_max_rides <- function(r5r_core, max_rides) {

  checkmate::assert_number(max_rides, lower = 0)

  # R5 defaults maxTransfers to 8L
  if (is.infinite(max_rides)) max_rides <- 8L

  r5r_core$setMaxRides(as.integer(max_rides))

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


#' Get all possible combinations of origin-destination pairs
#'
#' @param origins A data.frame with columns `id`, `lon`, `lat`
#' @param destinations A data.frame with columns `id`, `lon`, `lat`
#'
#' @return A data.frame with all possible combinations of origins and destinations.
#'
#' @family support functions
#'
#' @keywords internal
get_all_od_combinations <- function(origins, destinations){

  # cross join to get all possible id combinations
  df <- data.table::CJ(origins$id, destinations$id, unique = TRUE)

  # rename df
  data.table::setnames(df, 'V1', 'id_orig')
  data.table::setnames(df, 'V2', 'id_dest')

  # bring spatial coordinates from origin and destination
  df[origins, on=c('id_orig'='id'), c('lon_orig', 'lat_orig') := list(i.lon, i.lat)]
  df[destinations, on=c('id_dest'='id'), c('lon_dest', 'lat_dest') := list(i.lon, i.lat)]

  return(df)
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

