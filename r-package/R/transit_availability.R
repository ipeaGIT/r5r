#' Check transit service availability by date
#'
#' @description
#' This function checks the number and proportion of public transport services from the GTFS feeds
#' that are active on specified dates. This is useful to verify that the selected departure
#' dates for routing analysis are valid and have adequate service levels. When routing with public transport, it is crucial to use a departure date where services are operational, as indicated in the GTFS `calendar.txt` file.
#'
#' @details
#' You can specify the dates to check in two ways:
#' \itemize{
#'   \item Using the `dates` argument to provide a vector of specific dates.
#'   \item Using the `start_date` and `end_date` arguments to provide a continuous date range.
#' }
#' You must use one of these two methods, but not both in the same function call.
#'
#' @param r5r_network A routable transport network created with `build_network()`.
#' @param r5r_core The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the `r5r_network` argument instead.
#' @param dates A vector of specific dates to be checked. Can be character strings in
#'   "YYYY-MM-DD" format, or objects of class `Date`. This argument cannot be used with `start_date` or `end_date`.
#' @param start_date The start date for a continuous date range. Must be a single
#'   character string in "YYYY-MM-DD" format or a `Date` object. Must be used with `end_date`.
#' @param end_date The end date for a continuous date range. Must be a single
#'   character string in "YYYY-MM-DD" format or a `Date` object. Must be used with `start_date`.
#' @return A `data.table` with four columns: `date`, `total_services`,
#'   `active_services`, and `pct_active` (the proportion of active services).
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(r5r)
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(data_path)
#'
#' # Example 1: Check a vector of specific dates
#' # Let's check a regular weekday and a Sunday, where service may differ.
#' dates_to_check <- c("2019-05-13", "2019-05-19")
#' availability1 <- transit_availability(r5r_network, dates = dates_to_check)
#' availability1
#' #>          date total_services active_services pct_active
#' #> 1: 2019-05-13           118             116  0.983050847
#' #> 2: 2019-05-19           118               1  0.008474576
#'
#' # Example 2: Check a continuous date range using start_date and end_date
#' availability2 <- transit_availability(
#'   r5r_network,
#'   start_date = "2019-01-01",
#'   end_date = "2019-12-31"
#' )
#' availability2[121:124,]
#' #>          date total_services active_services pct_active
#' #>        <Date>          <int>           <int>       <num>
#' #> 1: 2019-05-01            118              62 0.525423729
#' #> 2: 2019-05-02            118             116 0.983050847
#' #> 3: 2019-05-03            118             116 0.983050847
#' #> 4: 2019-05-04            118               1 0.008474576
#'
#' # plot availability over the year
#' library(ggplot2)
#' ggplot(availability2, aes(x = date, y = pct_active)) +
#'   geom_line() +
#'   geom_point() +
#'   theme_classic(base_size = 16)
#'
#' stop_r5(r5r_network)
#' }
transit_availability <- function(
  r5r_network,
  r5r_core = deprecated(),
  dates = NULL,
  start_date = NULL,
  end_date = NULL
) {
  # deprecating r5r_core --------------------------------------
  if (lifecycle::is_present(r5r_core)) {
    cli::cli_warn(c(
      "!" = "The `r5r_core` argument is deprecated as of r5r v2.3.0.",
      "i" = "Please use the `r5r_network` argument instead."
    ))
    r5r_network <- r5r_core
  }

  # Check inputs
  checkmate::assert_class(r5r_network, "r5r_network")
  jcore <- r5r_network@jcore

  # Argument validation for date inputs (CONSOLIDATED)
  is_valid_dates_vector <- !is.null(dates) &&
    is.null(start_date) &&
    is.null(end_date)
  is_valid_date_range <- is.null(dates) &&
    !is.null(start_date) &&
    !is.null(end_date)

  if (!is_valid_dates_vector && !is_valid_date_range) {
    cli::cli_abort(
      c(
        "Incorrect date arguments provided.",
        "i" = "Please specify dates using one of the following methods:",
        "*" = "Use the {.arg dates} argument to provide a vector of specific dates.",
        "*" = "Use both {.arg start_date} and {.arg end_date} to provide a continuous date range.",
        "x" = "You cannot mix these methods or provide an incomplete date range."
      )
    )
  }

  # Helper function to parse and validate date inputs
  parse_date_input <- function(date_input, arg_name) {
    # Pass Date objects through directly
    if (inherits(date_input, "Date")) {
      return(date_input)
    }

    if (!is.character(date_input)) {
      cli::cli_abort(
        "{.arg {arg_name}} must be a vector of character strings or Date objects."
      )
    }

    # Use regex to strictly check for "YYYY-MM-DD" format
    is_iso_format <- grepl("^\\d{4}-\\d{2}-\\d{2}$", date_input)
    if (any(!is_iso_format)) {
      cli::cli_abort(c(
        "x" = "Invalid date format found in {.arg {arg_name}}.",
        "i" = "Please use the strict {.val 'YYYY-MM-DD'} format for all date strings."
      ))
    }

    # Use a tryCatch block to convert potential errors from as.Date() into NAs
    parsed_dates_list <- lapply(date_input, function(d) {
      tryCatch(
        {
          as.Date(d)
        },
        error = function(e) {
          # If as.Date fails, return NA instead of throwing an error
          as.Date(NA)
        }
      )
    })
    parsed_dates <- do.call("c", parsed_dates_list)

    # Final check for NAs, which now correctly indicate logically impossible dates
    if (anyNA(parsed_dates)) {
      cli::cli_abort(c(
        "x" = "Could not parse all values in {.arg {arg_name}}.",
        "i" = "One or more dates are logically invalid (e.g., '2025-02-29')."
      ))
    }

    return(parsed_dates)
  }

  # Prepare the list of dates to check
  if (!is.null(dates)) {
    dates_as_date <- parse_date_input(dates, "dates")
    dates_formatted <- format(dates_as_date, "%Y-%m-%d")
  } else {
    start_d <- parse_date_input(start_date, "start_date")
    end_d <- parse_date_input(end_date, "end_date")

    if (length(start_d) > 1 || length(end_d) > 1) {
      cli::cli_abort(
        "{.arg start_date} and {.arg end_date} must each be a single date."
      )
    }
    if (start_d > end_d) {
      cli::cli_abort(
        "{.arg start_date} must be before or the same as {.arg end_date}."
      )
    }

    date_sequence <- seq(from = start_d, to = end_d, by = "day")
    dates_formatted <- format(date_sequence, "%Y-%m-%d")
  }

  # Function to process a single date by querying the Java object
  process_single_date <- function(date_str) {
    services_java <- jcore$getTransitServicesByDate(date_str)
    services_dt <- java_to_dt(services_java)

    if (nrow(services_dt) == 0) {
      return(data.table::data.table(
        date = as.Date(date_str),
        total_services = 0L,
        active_services = 0L,
        pct_active = 0.0
      ))
    }

    total_s <- nrow(services_dt)
    active_s <- sum(services_dt$active_on_date, na.rm = TRUE)
    pct_s <- if (total_s > 0) active_s / total_s else 0.0

    return(data.table::data.table(
      date = as.Date(date_str),
      total_services = total_s,
      active_services = active_s,
      pct_active = pct_s
    ))
  }

  # Apply function to all dates and bind results into a single data.table
  results_list <- lapply(dates_formatted, process_single_date)
  final_dt <- data.table::rbindlist(results_list)

  return(final_dt)
}
