#' Set verbose argument
#'
#' Indicates whether R5 should output informative messages or not. Please note
#' that R5 error messages are still reported even when `verbose` is `FALSE`.
#'
#' @template r5r_core
#' @param verbose A logical, passed from the function above.
#'
#' @param verbose A logical, passed from function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_verbose <- function(r5r_core, verbose) {
  checkmate::assert_logical(verbose, len = 1, any.missing = FALSE)

  if (verbose) {
    r5r_core$verboseMode()
  } else {
    r5r_core$silentMode()
  }

  return(invisible(TRUE))
}


#' Set progress argument
#'
#' Indicates whether or not a progress counter must be printed during
#' computations. Applies to all routing functions.
#'
#' @template r5r_core
#' @param progress A logical, passed from the function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_progress <- function(r5r_core, progress) {
  checkmate::assert_logical(progress, len = 1)

  r5r_core$setProgress(progress)

  return(invisible(TRUE))
}


#' Set number of threads
#'
#' Sets the number of threads to be used by the r5r `.jar`.
#'
#' @template r5r_core
#' @param n_threads A number, passed from the function above.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
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

  return(invisible(TRUE))
}


#' Set max Level of Transit Stress (LTS)
#'
#' @template r5r_core
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

  return(invisible(TRUE))
}


#' Set max number of rides
#'
#' Sets the maximum number of rides a trip can use in R5.
#'
#' @template r5r_core
#' @param max_rides A number. The max number of public transport rides allowed
#'   in the same trip. Passed from routing function.
#'
#' @return No return value, called for side effects.
#'
#' @family setting functions
#'
#' @keywords internal
set_max_rides <- function(r5r_core, max_rides) {
  checkmate::assert_number(max_rides, lower = 0, finite = TRUE)

  r5r_core$setMaxRides(as.integer(max_rides))

  return(invisible(TRUE))
}


#' Set walk and bike speed
#'
#' This function receives the walk and bike 'speed' inputs in Km/h from routing
#' functions above and converts them to meters per second, which is then used
#' to set these speed profiles in r5r JAR.
#'
#' @template r5r_core
#' @param speed A number representing the speed in km/h.
#' @param mode A string. Either `"bike"` or `"walk"`.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @family setting functions
#'
#' @keywords internal
set_speed <- function(r5r_core, speed, mode) {
  checkmate::assert_number(speed, lower = 0, .var.name = paste0(mode, "_speed"))

  speed <- speed * 5 / 18

  if (mode == "walk") {
    r5r_core$setWalkSpeed(speed)
  } else {
    r5r_core$setBikeSpeed(speed)
  }

  return(invisible(TRUE))
}
