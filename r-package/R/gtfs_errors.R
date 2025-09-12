#' Get GTFS errors encountered in network building
#' 
#' This returns a data frame of GTFS errors R5 encountered when building the network.
#' Any high-priority errors will prevent routing from functioning, while other errors
#' may lead to unexpected results.
#' 
#' @param r5r_network the R5R network object
#' 
#' Since GTFS errors are not stored as part of the cached network, this function will only
#' return results on a newly built network, and will error on a network loaded from a cache.
#' 
#' @export
gtfs_errors <- function (r5r_network) {
    checkmate::assert_class(r5r_network, "r5r_network")

    jerr = r5r_network@jcore$gtfsErrors

    if (rJava::is.jnull(jerr)) {
        stop("Errors are only available when transport network is first built")
    } else {
        # indirection to make it visible again
        dt = java_to_dt(jerr)
        return(dt)
    }
}