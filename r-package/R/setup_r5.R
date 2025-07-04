#' Create a transport network used for routing in R5
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `setup_r5()` was renamed to [`build_network()`] to create a more consistent
#' API. **`setup_r5()` is being deprecated** after *r5r* v2.3.0 and will be
#' **removed in a future release**. Please switch to [`build_network()`].
#'
#' @template verbose
#' @param data_path A string pointing to the directory where data inputs are
#' stored and where the built `network.dat` will be saved.
#' @param temp_dir A logical. Whether the `R5` Jar file should be saved to a
#' temporary directory. Defaults to `FALSE`.
#' @param elevation A string. The name of the impedance function to be used to
#' calculate impedance for walking and cycling based on street slopes.
#' Available options include `TOBLER` (Default) and `MINETTI`, or `NONE` to
#' ignore elevation. R5 loads elevation data from `.tif` files saved inside the
#' `data_path` directory. See more info in the Details below.
#' @param overwrite A logical. Whether to overwrite an existing `network.dat`
#' or to use a cached file. Defaults to `FALSE` (i.e. use a cached network).
#'
#' @return An `rJava` object to connect with `R5` routing engine.
#'
#' @family Build network
#' @keywords internal
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' data_path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_network <- setup_r5(data_path)
#' @export
setup_r5 <- function(data_path,
                     verbose = FALSE,
                     temp_dir = FALSE,
                     elevation = "TOBLER",
                     overwrite = FALSE) {

  # Deprecation warning --------------------------------------------------------
  cli::cli_warn(c(
    "!" = "{.fn setup_r5} is being deprecated in *r5r* v2.3.0 and will be removed in a future release.",
    "i" = "Please use {.fn r5r::build_network} instead."
  ))

  # lifecycle::deprecate_soft(
  #   when = "2.3.0",
  #   what = "setup_r5()",
  #   with = "r5r::build_network()"
  #   )

  # # Optional base-R signal for tools that watch .Deprecated()
  # .Deprecated("build_network", package = "r5r")


  # Pass through to the replacement -------------------------------------------

  r5r_network <- build_network(
    data_path,
    verbose = verbose,
    temp_dir = temp_dir,
    elevation = elevation,
    overwrite = overwrite
    )

  return(wrap_r5r_core(r5r_network))
}
