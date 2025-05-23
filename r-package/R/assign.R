#' Check and convert origin and destination inputs
#'
#' @param df Either a `data.frame` or a `POINT sf`.
#' @param name Object name.
#'
#' @return A `data.frame` with columns `id`, `lon` and `lat`.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_points_input <- function(df, name) {
  if (!inherits(df, "data.frame")) {
    stop("'", name, "' must be either a 'data.frame' or a 'POINT sf'.")
  }

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
    data.table::setnames(df, c("x", "y"), c("lon", "lat"))
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
    warning("'", name, "$id' forcefully cast to character.")
  }

  return(df)
}


#' Check and select transport modes from user input
#'
#' Selects the transport modes used in the routing functions. Only one direct
#' and access/egress modes are allowed at a time.
#'
#' @param mode A character vector, passed from routing functions.
#' @param mode_egress A character vector, passed from routing functions.
#'
#' @return A list with the transport modes to be used in the routing.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_mode <- function(mode, mode_egress, style) {
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

  mode <- toupper(unique(mode))
  checkmate::assert(
    checkmate::check_character(mode, min.len = 1, any.missing = FALSE),
    checkmate::check_names(mode, subset.of = all_modes),
    combine = "and"
  )

  mode_egress <- toupper(unique(mode_egress))
  checkmate::assert_string(mode_egress)
  checkmate::assert_names(
    mode_egress,
    subset.of = setdiff(dr_modes, c("CAR_PARK", "BICYCLE_RENT"))
  )

  direct_modes <- mode[which(mode %in% dr_modes)]
  transit_modes <- mode[which(mode %in% tr_modes)]

  if (length(direct_modes) > 1) {
    stop(
      "Please use only 1 of {",
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
    egress_mode = paste0(egress_mode, collapse = ";")
  )

  return(mode_list)
}


#' Check and convert POSIXct objects to strings
#'
#' @param datetime An object of POSIXct class.
#'
#' @return A list with the `date` and `time` of the trip departure as
#'   characters.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_departure <- function(datetime) {
  checkmate::assert_posixct(
    datetime,
    len = 1,
    any.missing = FALSE,
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


#' Assign max street time from walk/bike distance and speed
#'
#' Checks the time duration and speed inputs and converts them to distance.
#'
#' @param max_time A numeric of length 1. Maximum walking distance (in
#'   meters) for the whole trip. Passed from routing functions.
#' @param speed A numeric of length 1. Average walk speed in km/h.
#'   Defaults to 3.6 Km/h. Passed from routing functions.
#' @param max_trip_duration A numeric of length 1. Maximum trip duration in
#'   seconds. Defaults to 120 minutes (2 hours). Passed from routing functions.
#' @param mode A string. Either `"bike"` or `"walk"`.
#'
#' @return An `integer` representing the maximum number of minutes walking.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_max_street_time <- function(max_time, speed, max_trip_duration, mode) {

  checkmate::assert(
    checkmate::check_string(mode),
    checkmate::check_names(mode, subset.of = c("bike", "walk", "car")),
    combine = "and"
  )

  checkmate::assert_number(
    max_time,
    .var.name = paste0("max_", mode, "_time"),
    lower = 1,
    finite = FALSE
  )

  checkmate::assert_number(
    speed,
    finite = TRUE,
    .var.name = paste0(mode, "_speed")
  )

  checkmate::assert_number(max_trip_duration, lower = 1, finite = TRUE)

  if (speed <= 0) {
    stop(
      "Assertion on '", mode, "_speed' failed: ",
      "Must have value greater than 0."
    )
  }

  if (is.infinite(max_time)){
    return(as.integer(max_trip_duration))
  }
  else {
    return(as.integer(max_time))
    }
}


#' Assign max trip duration
#'
#' Check and convert the max trip duration input.
#'
#' @param max_trip_duration A number.
#'
#' @return An `integer` representing the maximum trip duration in minutes.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_max_trip_duration <- function(max_trip_duration,
                                     modes,
                                     max_walk_time,
                                     max_bike_time) {
  checkmate::assert_number(max_trip_duration, lower = 1, finite = TRUE)

  max_trip_duration <- as.integer(max_trip_duration)

  if (modes$transit_mode == "") {
    if (modes$direct_modes == "WALK" & max_walk_time < max_trip_duration) {
      max_trip_duration <- max_walk_time
    }
    if (modes$direct_modes == "BICYCLE" & max_bike_time < max_trip_duration) {
      max_trip_duration <- max_bike_time
    }
  }

  return(max_trip_duration)
}


#' Assign opportunities data
#'
#' Check and create an opportunities dataset.
#'
#' @param destinations Either a `data.frame` or a `POINT sf`.
#' @param opportunities_colnames A character vector with the names of the
#'   opportunities columns in `destinations`.
#'
#' @return A list of `Java-Array` objects.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_opportunities <- function(destinations, opportunities_colnames) {
  checkmate::assert_character(
    opportunities_colnames,
    min.len = 1,
    unique = TRUE,
    any.missing = FALSE
  )
  checkmate::assert_names(
    names(destinations),
    must.include = opportunities_colnames,
    .var.name = "destinations"
  )

  opportunities_data <- lapply(
    opportunities_colnames,
    function(colname) {
      checkmate::assert_numeric(destinations[[colname]])

      opp_array <- as.integer(destinations[[colname]])
      opp_array <- rJava::.jarray(opp_array)

      opp_array
    }
  )

  return(opportunities_data)
}


#' Assign decay function and parameter values
#'
#' Checks and assigns decay function and values.
#'
#' @param decay_function A string, the name of the decay function.
#' @param decay_value A number, the value of decay parameter.
#'
#' @return A `list` with the validated decay function and parameter value.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_decay_function <- function(decay_function, decay_value) {
  all_functions  <- c(
    "step",
    "exponential",
    "fixed_exponential",
    "linear",
    "logistic"
  )
  checkmate::assert(
    checkmate::check_string(decay_function),
    checkmate::check_names(decay_function, subset.of = all_functions),
    combine = "and"
  )
  checkmate::assert_number(decay_value, finite = TRUE, null.ok = TRUE)

  non_null_decay <- c("fixed_exponential", "linear", "logistic")
  if (!is.null(decay_value) & decay_function %in% c("step", "exponential")) {
    stop(
      "Assertion on decay_value failed: must be NULL when decay_function ",
      "is ", decay_function, "."
    )
  } else if (is.null(decay_value) & decay_function %in% non_null_decay) {
    stop(
      "Assertion on decay_value failed: must not be NULL when decay_function ",
      "is ", decay_function, "."
    )
  }

  if (decay_function == "fixed_exponential") {
    if (decay_value <= 0 | decay_value >= 1) {
      stop(
        "Assertion on decay_value failed: must be a number between 0 and 1 ",
        "(exclusive) when decay_function is fixed_exponential."
      )
    }
  }

  if (decay_function %in% c("logistic", "linear")) {
    if (decay_value < 1) {
      stop(
        "Assertion on decay_value failed: must be a number greater than or ",
        "equal to 1 when decay_function is ",
        decay_function, "."
      )
    }
  }

  decay_function <- toupper(decay_function)

  # java does not accept NULL values, so if decay_value is NULL we assign a
  # placeholder number to it (it's ignored in R5 anyway)

  if (is.null(decay_value)) {
    decay_value <- 0
  } else {
    decay_value <- as.double(decay_value)
  }

  decay_list <- list("fun" = decay_function, "value" = decay_value)

  return(decay_list)
}


#' Assign shortest path
#'
#' Check the shortest path input.
#'
#' @param shortest_path A logical.
#'
#' @return A logical.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_shortest_path <- function(shortest_path) {
  checkmate::assert_logical(shortest_path, len = 1, any.missing = FALSE)

  return(shortest_path)
}


#' Assign drop geometry
#'
#' Check the drop geometry input.
#'
#' @param drop_geometry A logical.
#'
#' @return A logical.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_drop_geometry <- function(drop_geometry) {
  checkmate::assert_logical(drop_geometry, len = 1, any.missing = FALSE)

  return(drop_geometry)
}


#' Assign osm_link_ids
#'
#' Check the osm_link_ids input.
#'
#' @param osm_link_ids A logical.
#' @param drop_geometry A logical.
#'
#' @return A logical.
#'
#' @family assigning functions
#'
#' @keywords internal
assign_osm_link_ids <- function(osm_link_ids, drop_geometry) {
  checkmate::assert_logical(osm_link_ids, len = 1, any.missing = FALSE)

  if (isTRUE(drop_geometry) & isTRUE(osm_link_ids)) {
    cli::cli_abort("To set osm_link_ids to `TRUE`, the parameter 'drop_geometry' must also be `FALSE`")
  }
  return(osm_link_ids)
}

