#' Set verbose argument
#'
#' Indicates whether R5 should output informative messages or not. Please note
#' that R5 error messages are still reported even when `verbose` is `FALSE`.
#'
#' @template r5r_network
#' @param verbose A logical, passed from the function above.
#'
#' @param verbose A logical, passed from function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_verbose <- function(r5r_network, verbose) {
  checkmate::assert_logical(verbose, len = 1, any.missing = FALSE)

  if (verbose) {
    r5r_network$verboseMode()
  } else {
    r5r_network$silentMode()
  }

  return(invisible(TRUE))
}


#' Set progress argument
#'
#' Indicates whether or not a progress counter must be printed during
#' computations. Applies to all routing functions.
#'
#' @template r5r_network
#' @param progress A logical, passed from the function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_progress <- function(r5r_network, progress) {
  checkmate::assert_logical(progress, len = 1, any.missing = FALSE)

  r5r_network$setProgress(progress)

  return(invisible(TRUE))
}


#' Set number of threads
#'
#' Sets the number of threads to be used by the r5r `.jar`.
#'
#' @template r5r_network
#' @param n_threads A number, passed from the function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_n_threads <- function(r5r_network, n_threads) {
  checkmate::assert_number(n_threads, lower = 1)

  if (is.infinite(n_threads)) {
    r5r_network$setNumberOfThreadsToMax()
  } else {
    n_threads <- as.integer(n_threads)
    r5r_network$setNumberOfThreads(n_threads)
  }

  return(invisible(TRUE))
}


#' Set max Level of Transit Stress (LTS)
#'
#' @template r5r_network
#' @param max_lts A number (between 1 and 4). The maximum level of traffic
#'   stress that cyclists will tolerate. A value of 1 means cyclists will only
#'   travel through the quietest streets, while a value of 4 indicates cyclists
#'   can travel through any road.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_max_lts <- function(r5r_network, max_lts) {
  checkmate::assert_number(max_lts)

  if (max_lts < 1 | max_lts > 4) {
    stop(
      max_lts,
      " is not a valid value for the maximum Level of Transit Stress (LTS).\n",
      "Please enter a value between 1 and 4."
    )
  }

  r5r_network$setMaxLevelTrafficStress(as.integer(max_lts))

  return(invisible(TRUE))
}


#' Set max number of rides
#'
#' Sets the maximum number of rides a trip can use in R5.
#'
#' @template r5r_network
#' @param max_rides A number. The max number of public transport rides allowed
#'   in the same trip. Passed from routing function.
#'
#' @return No return value, called for side effects.
#'
#' @family setting functions
#'
#' @keywords internal
set_max_rides <- function(r5r_network, max_rides) {
  checkmate::assert_number(max_rides, lower = 1, finite = TRUE)

  r5r_network$setMaxRides(as.integer(max_rides))

  return(invisible(TRUE))
}


#' Set walk and bike speed
#'
#' This function receives the walk and bike 'speed' inputs in Km/h from routing
#' functions above and converts them to meters per second, which is then used
#' to set these speed profiles in r5r JAR.
#'
#' @template r5r_network
#' @param speed A number representing the speed in km/h.
#' @param mode A string. Either `"bike"` or `"walk"`.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_speed <- function(r5r_network, speed, mode) {
  checkmate::assert(
    checkmate::check_string(mode),
    checkmate::check_names(mode, subset.of = c("bike", "walk")),
    combine = "and"
  )
  var_name <- paste0(mode, "_speed")
  checkmate::assert_number(speed, finite = TRUE, .var.name = var_name)
  if (speed <= 0) {
    stop(
      "Assertion on '", var_name, "' failed: Must have value greater than 0."
    )
  }

  speed <- speed * 5 / 18

  if (mode == "walk") {
    r5r_network$setWalkSpeed(speed)
  } else {
    r5r_network$setBikeSpeed(speed)
  }

  return(invisible(TRUE))
}


#' Set time window
#'
#' Sets the time window to be used by R5.
#'
#' @template r5r_network
#' @param time_window A number.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_time_window <- function(r5r_network, time_window) {
  checkmate::assert_number(time_window, lower = 1, finite = TRUE)

  time_window <- as.integer(time_window)

  r5r_network$setTimeWindowSize(time_window)

  return(invisible(TRUE))
}


#' Set percentiles
#'
#' Sets the percentiles to be used by R5.
#'
#' @template r5r_network
#' @param percentiles An integer vector of maximum length 5.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_percentiles <- function(r5r_network, percentiles) {
  checkmate::assert_numeric(
    percentiles,
    lower = 1,
    upper = 99,
    max.len = 5,
    unique = TRUE,
    any.missing = FALSE,
    finite = TRUE
  )

  percentiles <- as.integer(percentiles)

  r5r_network$setPercentiles(percentiles)

  return(invisible(TRUE))
}


#' Set number of Monte Carlo draws
#'
#' Sets the number of Monte Carlo draws to be used by R5.
#'
#' @template r5r_network
#' @param draws_per_minute A number.
#' @param time_window A number.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_monte_carlo_draws <- function(r5r_network, draws_per_minute, time_window) {
  # time_window is previously checked in set_time_window()
  checkmate::assert_number(draws_per_minute, lower = 1, finite = TRUE)

  draws <- time_window * draws_per_minute
  draws <- as.integer(draws)

  r5r_network$setNumberOfMonteCarloDraws(draws)

  return(invisible(TRUE))
}


#' Set the fare structure used when calculating transit fares
#'
#' Sets the fare structure used by our "generic" fare calculator. A value of
#' `NULL` is passed to `fare_structure` by the upstream routing and
#' accessibility functions when fares are not to be calculated.
#'
#' @template r5r_network
#' @template fare_structure
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_fare_structure <- function(r5r_network, fare_structure) {
  if (!is.null(fare_structure)) {
    assert_fare_structure(fare_structure)

    if (!("type" %in% names(fare_structure))) {
      # this is an R5R fare structure object
      if (fare_structure$fare_cap == Inf) {
        fare_structure$fare_cap <- -1
      }
      if (fare_structure$transfer_time_allowance == Inf) {
        fare_structure$transfer_time_allowance <- -1
      }
      if (fare_structure$max_discounted_transfers == Inf) {
        fare_structure$max_discounted_transfers <- -1
      }
    }

    fare_settings_json <- jsonlite::toJSON(fare_structure, auto_unbox = TRUE)
    json_string <- as.character(fare_settings_json)

    r5r_network$setFareCalculator(json_string)
  } else {
    r5r_network$dropFareCalculator()
  }

  return(invisible(TRUE))
}


#' Set max fare
#'
#' Sets the max fare allowed when calculating transit fares.
#'
#' @template r5r_network
#' @param max_fare A number.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_max_fare <- function(r5r_network, max_fare) {
  checkmate::assert_number(max_fare, lower = 0)

  # Inf values are not allowed in Java, so -1 is used to indicate when max_fare
  # is unconstrained

  if (!is.infinite(max_fare)) {
    r5r_network$setMaxFare(rJava::.jfloat(max_fare))
  } else {
    r5r_network$setMaxFare(rJava::.jfloat(-1.0))
  }

  return(invisible(TRUE))
}


#' Set output directory
#'
#' Sets whether r5r should save output to a specified directory.
#'
#' @template r5r_network
#' @param output_dir A path.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_output_dir <- function(r5r_network, output_dir) {
  checkmate::assert_string(output_dir, null.ok = TRUE)

  if (!is.null(output_dir)) {
    checkmate::assert_directory_exists(output_dir)
    r5r_network$setCsvOutput(output_dir)
  } else {
    r5r_network$setCsvOutput("")
  }

  return(invisible(TRUE))
}


#' Set cutoffs
#'
#' Sets the cutoffs used when calculating accessibility.
#'
#' @template r5r_network
#' @param cutoffs A numeric vector.
#' @param decay_function A string, the name of the decay function.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_cutoffs <- function(r5r_network, cutoffs, decay_function) {
  checkmate::assert_numeric(
    cutoffs,
    min.len = 1,
    max.len = 12,
    any.missing = FALSE,
    finite = TRUE,
    null.ok = TRUE
  )

  non_null_cutoffs <- c("step", "exponential", "linear", "logistic")
  if (!is.null(cutoffs) & decay_function == "fixed_exponential") {
    stop(
      "Assertion on cutoffs failed: must be NULL when decay_function ",
      "is ", decay_function, "."
    )
  } else if (is.null(cutoffs) & decay_function %in% non_null_cutoffs) {
    stop(
      "Assertion on cutoffs failed: must not be NULL when decay_function ",
      "is ", decay_function, "."
    )
  }

  # java does not accept NULL values, so if cutoffs is NULL we assign a
  # placeholder number to it (it's ignored in R5 anyway)

  if (is.null(cutoffs)) {
    cutoffs <- 0L
  } else {
    cutoffs <- as.integer(cutoffs)
  }

  r5r_network$setCutoffs(cutoffs)

  return(invisible(TRUE))
}


#' Set monetary cutoffs
#'
#' Sets the monetary cutoffs that should be considered when calculating the
#' Pareto frontier.
#'
#' @template r5r_network
#' @param fare_cutoffs A path.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_fare_cutoffs <- function(r5r_network, fare_cutoffs) {
  checkmate::assert_numeric(
    fare_cutoffs,
    lower = 0,
    any.missing = FALSE,
    min.len = 1,
    unique = TRUE
  )

  r5r_network$setFareCutoffs(rJava::.jfloat(fare_cutoffs))

  return(invisible(TRUE))
}


#' Set breakdown
#'
#' Sets whether travel time matrices should include detailed trip information or
#' not.
#'
#' @template r5r_network
#' @param breakdown A logical.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_breakdown <- function(r5r_network, breakdown) {
  checkmate::assert_logical(breakdown, any.missing = FALSE, len = 1)

  r5r_network$setTravelTimesBreakdown(breakdown)

  return(invisible(TRUE))
}


#' Set expanded travel times
#'
#' Sets whether travel time matrices should return results for each minute of
#' the specified time window.
#'
#' @template r5r_network
#' @param expanded A logical.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_expanded_travel_times <- function(r5r_network, expanded) {
  checkmate::assert_logical(expanded, any.missing = FALSE, len = 1)

  r5r_network$setExpandedTravelTimes(expanded)

  return(invisible(TRUE))
}


#' Set suboptimal minutes
#'
#' Sets the number of suboptimal minutes considered in [detailed_itineraries()]
#' routing. From R5 documentation: "This parameter compensates for the fact that
#' GTFS does not contain information about schedule deviation (lateness). The
#' min-max travel time range for some trains is zero, since the trips are
#' reported to always have the same timings in the schedule. Such an option
#' does not overlap (temporally) its alternatives, and is too easily eliminated
#' by an alternative that is only marginally better. We want to effectively
#' push the max travel time of alternatives out a bit to account for the fact
#' that they don't always run on schedule".
#'
#' @template r5r_network
#' @param suboptimal_minutes A number.
#' @template fare_structure
#' @param shortest_path A logical.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_suboptimal_minutes <- function(r5r_network,
                                   suboptimal_minutes,
                                   fare_structure,
                                   shortest_path) {
  checkmate::assert_number(suboptimal_minutes, lower = 0, finite = TRUE)

  if (!is.null(fare_structure) && suboptimal_minutes > 0) {
    stop(
      "Assertion on 'suboptimal_minutes' failed: Must be 0 when calculating ",
      "fares with detailed_itineraries()."
    )
  }

  if (shortest_path && suboptimal_minutes > 0) {
    stop(
      "Assertion on 'suboptimal_minutes' failed: Must be 0 when ",
      "'shortest_path' is TRUE."
    )
  }

  suboptimal_minutes <- as.integer(suboptimal_minutes)

  r5r_network$setSuboptimalMinutes(suboptimal_minutes)

  return(invisible(TRUE))
}


#' Reverse Origins and Destinations for Direct Modes
#'
#' Swaps the `origins` and `destinations` data frames if certain conditions are
#' met, specifically to optimize routing performance with R5's one-to-many
#' algorithm. The function reverses the direction of analysis when the transit
#' mode is empty and the direct modes are WALK or BICYCLE and when the number of
#' origin points is greater than the number of destination points.
#'
#' @param origins A data frame representing origin locations.
#' @param destinations A data frame representing destination locations.
#' @param mode_list A named list containing the routing modes:
#'
#' @return List origins and destinations unchanges or in swapper order
#'
#' @family setting functions
#'
#' @keywords internal
reverse_if_direct_mode <- function(origins, destinations, mode_list, data_path) {

  # In direct modes, reverse origin/destination to take advantage of R5's One to Many algorithm
  if (
    mode_list$transit_mode == "" &&
    mode_list$direct_modes %in% c("WALK", "BICYCLE") &&
    nrow(origins) > nrow(destinations) &&
    !exists_tiff(data_path) # only if no elevation data is present
    ) {
    temp <- origins
    origins <- destinations
    destinations <- temp
  }

  return(list(origins = origins, destinations = destinations))
}


#' Set elevation
#'
#' Verifies whether elevation mode is correct.
#'
#' @param elevation Character.
#'
#' @return Character. Corretly formatted elevation.
#' @family setting functions
#'
#' @keywords internal
set_elevation <- function(elevation) {
  elevation <- toupper(elevation)
  valid_elev <- c("TOBLER", "MINETTI", "NONE")
  if (!elevation %in% valid_elev) {
    cli::cli_abort(c(
      "Invalid value for {.arg elevation}: {.val {elevation}}.",
      "x" = "Must be one of: {.val {valid_elev}}")
    )
  }

  elevation
}

