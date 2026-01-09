#' Get GTFS eventual errors encountered in network building
#'
#' This returns a data frame of GTFS errors R5 encountered when building the
#' network. You can call this with the network itself as the main parameter. If
#' network build fails, you won't have a network object, so you can also call
#' this with the `data_path` to where the network is stored.
#'
#' @param r5r_network the R5R network object, or a path to the location where
#'     the network is stored (useful if network build failed).
#'
#' @return A `data.frame`
#'
#' @family support functions
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' library(r5r)
#'
#' # directory with street network and gtfs files
#' data_path <- system.file("extdata/poa", package = "r5r")
#' r5r_network <- build_network(data_path)
#'
#' get_gtfs_errors(r5r_network)
#'
#' @export
get_gtfs_errors <- function (r5r_network) {
    checkmate::assert_multi_class(r5r_network, c("r5r_network", "character"))

    if (class(r5r_network) == "r5r_network") {
      r5r_network = r5r_network@jcore$getDataPath()
    }

    err_file = file.path(r5r_network, "gtfs_errors.csv")

    if (!file.exists(err_file)) {
      cli::cli_abort(c(
        x = "Error file {.path err_file} does not exist",
        i = "Perhaps the network has not been built or was built by an older version of r5r"
      ))
    }

    return(data.table::fread(err_file, header=T))
}
