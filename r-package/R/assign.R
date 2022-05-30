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


#' Assign transport mode
#'
#' Selects the transport modes used in the routing functions.
#'
#' @param mode A character vector, passed from routing functions.
#' @param mode_egress A character vector, passed from routing functions.
#' @param style Either `"ttm"` or `"dit"`. The first forbids more than one
#'   direct and access modes, and should be used in [travel_time_matrix()],
#'   [accessibility()], [expanded_travel_time_matrix()] and [pareto_frontier()].
#'   The latter allows multiple direct and access modes, and should be used in
#'   [detailed_itineraries()].
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
  if (style == "ttm") {
    checkmate::assert_string(mode_egress)
  } else {
    checkmate::assert_character(mode_egress, min.len = 1, any.missing = FALSE)
  }
  checkmate::assert_names(
    mode_egress,
    subset.of = setdiff(dr_modes, c("CAR_PARK", "BICYCLE_RENT"))
  )

  checkmate::assert(
    checkmate::check_string(style),
    checkmate::check_names(style, subset.of = c("ttm", "dit")),
    combine = "and"
  )

  # assign modes accordingly

  direct_modes <- mode[which(mode %in% dr_modes)]
  transit_modes <- mode[which(mode %in% tr_modes)]

  if (style == "ttm") {
    if (length(direct_modes) > 1) {
      stop(
        "Please use only 1 of {",
        paste0("'", direct_modes, "'", collapse = ","),
        "} when routing."
      )
    }
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
