############# Support functions for r5r

#' Set verbose argument
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param verbose logical, passed from function above
#'
#' @return No return value, called for side effects.
#' @family support functions

set_verbose <- function(r5r_core, verbose) {

  # in silent mode only errors are reported

  checkmate::assert_logical(verbose)

  if (verbose) r5r_core$verboseMode()
  else r5r_core$silentMode()

}



#' Set max street time
#'
#' @param max_walk_dist numeric, Maximum walking distance (in meters) for the
#'                      whole trip. Passed from routing functions.
#' @param walk_speed numeric, Average walk speed in Km/h. Defaults to 3.6 Km/h.
#'                    Passed from routing functions.
#' @param max_trip_duration numeric, Maximum trip duration in seconds. Defaults
#'                          to 120 minutes (2 hours). Passed from routing functions.
#'
#' @return An `integer` representing the maximum number of minutes walking
#' @family support functions

set_max_street_time <- function(max_walk_dist, walk_speed, max_trip_duration) {

  checkmate::assert_numeric(max_walk_dist)
  checkmate::assert_numeric(walk_speed)

  if (is.infinite(max_walk_dist)) return(max_trip_duration)

  max_street_time <- as.integer(round(60 * max_walk_dist / (walk_speed * 1000), digits = 0))

  if (max_street_time == 0) stop(paste("'max_walk_dist' is too low.",
                                       "Please make sure distances are in meters, not kilometers."))

  # if max_street_time ends up being higher than max_trip_duration, uses
  # max_trip_duration as a ceiling

  if (max_street_time > max_trip_duration) max_street_time <- max_trip_duration

  return(max_street_time)

}



#' Select transport mode
#'
#' @param mode character string passed from routing functions.
#' @param mode_egress character string passed from routing functions.
#'
#' @return A `list` with the transport modes used in the routing.
#' @family support functions

select_mode <- function(mode, mode_egress) {

  # list all available modes
  dr_modes  <- c('WALK','BICYCLE','CAR','BICYCLE_RENT','CAR_PARK')
  tr_modes  <- c('TRANSIT', 'TRAM','SUBWAY','RAIL','BUS','FERRY','CABLE_CAR','GONDOLA','FUNICULAR')
  all_modes <- c(tr_modes, dr_modes)

  # check for invalid input --------------------------------------------------
  mode <- toupper(unique(mode))
  mode_egress <- toupper(unique(mode_egress))[1]

  lapply(mode, function(x) {
    if (!x %chin% all_modes) {
      stop(paste0(x, " is not a valid 'mode'.\nPlease use one of the following: ",
                  paste(unique(all_modes), collapse = ", "))) }
    })
  lapply(mode_egress, function(x) {
    if (!x %chin% dr_modes) {
      stop(paste0(x, " is not a valid 'mode'.\nPlease use one of the following: ",
                  paste(unique(dr_modes), collapse = ", "))) }
    })

  # assign modes accordingly  --------------------------------------------------
  direct_modes <- mode[which(mode %chin% dr_modes)]
  transit_mode <- mode[which(mode %chin% tr_modes)]

  # No public transport
  if ( length(transit_mode) == 0) {
    if (sum(mode %in% c('WALK', 'BICYCLE')>0)){ direct_modes <- access_mode <- mode[which(mode %chin% c('WALK', 'BICYCLE'))][1] }
    if (sum(mode %in% "CAR")>0){ direct_modes <- access_mode <- 'CAR' }
    transit_mode <- ""
    mode_egress <- ""

  } else {

  # with public transport
    # all pt modes
    if ("TRANSIT" %in% transit_mode){ transit_mode <- tr_modes }

    # if only transit mode is passed, assume 'WALK' as access_mode
    if (length(direct_modes) == 0) { access_mode <- direct_modes <- 'WALK' }

    # if transit & direct modes are passed, consider direct as access & egress_modes
    if (length(direct_modes) != 0) { access_mode <- direct_modes }
  }

  # create output as a list
  mode_list <- list('direct_modes' = paste0(direct_modes, collapse = ";"),
                    'transit_mode' = paste0(transit_mode, collapse = ";"),
                    'access_mode'  = paste0(access_mode, collapse = ";"),
                    'egress_mode'  = paste0(mode_egress[1], collapse = ";"))

  return(mode_list)
}



#' Generate date and departure time strings from POSIXct
#'
#' @param datetime An object of POSIXct class.
#'
#' @return A `list` with the `date` and `time` of the trip departure as characters
#' @return A list with 'date' and 'departure_time' names.
#'
#' @family support functions

posix_to_string <- function(datetime) {

  checkmate::assert_posixct(datetime)

  tz = attr(datetime, "tzone")
  if(is.null(tz)){tz <- ""}

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
#' @return A data.frame with columns \code{id}, \code{lon} and \code{lat}.
#' @family support functions

assert_points_input <- function(df, name) {

  # check if 'df' is a data.frame or a POINT sf

  if (is(df, "data.frame")) {

    if (is(df, "sf")) {

      if (as.character(sf::st_geometry_type(df, by_geometry = FALSE)) != "POINT") {

        stop(paste0("'", name, "' must be either a 'data.frame' or a 'POINT sf'."))

      }

      df <- sfheaders::sf_to_df(df, fill = TRUE)
      data.table::setDT(df)
      data.table::setnames(df, "x", "lon")
      data.table::setnames(df, "y", "lat")
      checkmate::assert_names(names(df), must.include = c("id"), .var.name = name)
    }

    checkmate::assert_names(names(df), must.include = c("id", "lat", "lon"), .var.name = name)

    if (!is.character(df$id)) {

      df$id <- as.character(df$id)
      warning(paste0("'", name, "$id' forcefully cast to character."))

    }

    checkmate::assert_numeric(df$lon, .var.name = paste0(name, "$lon"))
    checkmate::assert_numeric(df$lat, .var.name = paste0(name, "$lat"))

    return(df)

  }

  stop(paste0("'", name, "' must be either a 'data.frame' or a 'sf POINT'."))

}



#' Set number of threads
#'
#' @description Sets number of threads to be used by the r5r .jar.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param n_threads Any object.
#'
#' @return No return value, called for side effects.
#' @family support functions

set_n_threads <- function(r5r_core, n_threads) {

  checkmate::assert_numeric(n_threads)

  if (is.infinite(n_threads)) {

    r5r_core$setNumberOfThreadsToMax()
    data.table::setDTthreads(percent = 100)

  } else {

    n_threads <- as.integer(n_threads)
    r5r_core$setNumberOfThreads(n_threads)
    data.table::setDTthreads(threads = n_threads)

  }

}



#' Set walk and bike speed
#'
#' @description This function receives the walk and bike 'speed' inputs in Km/h
#' from routing functions above and converts them to meters per second, which is
#' then used to set these speed profiles in r5r JAR.
#'
#' @param r5r_core a rJava object to connect with R5 routing engine
#' @param speed A numeric representing the speed in km/h.
#' @param mode Either \code{"bike"} or \code{"walk"}.
#'
#' @return No return value, called for side effects.
#' @family support functions

set_speed <- function(r5r_core, speed, mode) {

  checkmate::assert_numeric(speed, .var.name = paste0(mode, "_speed"))

  # convert from km/h to m/s
  speed <- speed * 5 / 18

  if (mode == "walk") r5r_core$setWalkSpeed(speed)
  else r5r_core$setBikeSpeed(speed)

}

#' Set max Level of Transit Stress (LTS)
#'
#' @param r5r_core rJava object to connect with R5 routing engine
#' @param max_lts numeric (between 1 and 4). The maximum level of traffic stress
#' that cyclists will tolerate. A value of 1 means cyclists will only travel
#' through the quietest streets, while a value of 4 indicates cyclists can travel
#' through any road.
#'
#' @return No return value, called for side effects.
#' @family support functions
#'
set_max_lts <- function(r5r_core, max_lts) {
  checkmate::assert_numeric(max_lts)

  if (max_lts < 1 | max_lts > 4) {
    stop(paste0(max_lts, " is not a valid value for the maximum Level of Transit Stress (LTS).\n",
                "Please enter a value between 1 and 4."))
  }

  r5r_core$setMaxLevelTrafficStress(as.integer(max_lts))
}

#' Set max number of transfers
#'
#' @description Set maxTransfers parameter in R5.
#'
#' @param r5r_core rJava object to connect with R5 routing engine
#' @param max_rides numeric. The max number of public transport rides
#'                  allowed in the same trip. Passed from routing function.
#'
#' @return No return value, called for side effects.
#' @family support functions
#'

set_max_rides <- function(r5r_core, max_rides) {

  checkmate::assert_numeric(max_rides)

  # R5 defaults maxTransfers to 8L
  if (is.infinite(max_rides)) max_rides <- 8L

  r5r_core$setMaxRides(as.integer(max_rides))

}

#' Set suboptimal minutes
#'
#' @description Set suboptimalMinutes parameter in R5.
#'
#' @param r5r_core rJava object to connect with R5 routing engine
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

set_suboptimal_minutes <- function(r5r_core, suboptimal_minutes) {

  checkmate::assert_numeric(suboptimal_minutes)

  # R5 defaults subOptimalMinutes to 5L
  if (is.infinite(suboptimal_minutes)) suboptimal_minutes <- 5L

  r5r_core$setSuboptimalMinutes(as.integer(suboptimal_minutes))

}



#' Download metadata of R5 jar files
#' @description Support function to download metadata internally used in r5r
#'
#' @return A `data.frame` with url address of r5r Jar files
#' @family support functions
#'
download_metadata <- function(){

  # create tempfile to save metadata
  metadata_file <- file.path(tempdir(), "metadata_r5r.csv")

  # IF metadata has been downloaded before
  if (checkmate::test_file_exists(metadata_file)) {

    # skip

    } else {

  # Download medata
    # test server connection
    metadata_link <- 'https://www.ipea.gov.br/geobr/r5r/metadata.csv'
    check_connection(metadata_link)

    # download it and save it to JAR folder
    utils::download.file(url=metadata_link, destfile=metadata_file,
                         overwrite=TRUE, quiet=TRUE)
  }

  # read metadata
  metadata <- utils::read.csv(metadata_file,
                              colClasses = 'character', header = T, sep = ';')

  return(metadata)
}



#' Check internet connection with Ipea server
#'
#' @description
#' Checks if there is internet connection to Ipea server to download geobr data.
#'
#' @param file_url A string with the file_url address of an geobr dataset
#'
#' @return No return value, called for side effects.
#' @family support functions
#'
check_connection <- function(file_url = 'https://www.ipea.gov.br/geobr/metadata/metadata_gpkg.csv'){

  # check internet connection
  if (!curl::has_internet()) {
    message("No internet connection.")
    return(invisible(NULL))
  }

  # test server connection
  # crul::ok(file_url)
  if (httr::http_error(httr::GET(file_url))) {
    message("Problem connecting to data server. Please try geobr again in a few minutes.")
    return(invisible(NULL))
  }
}
