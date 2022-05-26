#' Select transport mode (non-detailed_itineraries)
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
#' @family mode selectors
#'
#' @keywords internal
select_mode <- function(mode, mode_egress, style) {
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
