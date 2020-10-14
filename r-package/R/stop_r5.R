#' Stop running r5r core
#'
#' @description Stops running r5r cores.
#'
#' @param ... \code{r5r_core} objects currently running. By default, if no cores
#'            are supplied all running cores are stopped.
#'
#' @examples
#' \dontrun{library(r5r)
#'
#' path <- system.file("extdata/poa", package = "r5r")
#'
#' r5r_core <- setup_r5(data_path = path)
#'
#' stop_r5(r5r_core)
#' }
#'
#' @export

stop_r5 <- function(...) {

  supplied_cores <- list(...)

  # find all running r5r cores in the parent frame

  current_objects <- mget(ls(envir = parent.frame()), envir = parent.frame())

  classes_list <- lapply(current_objects, class)

  running_cores <- current_objects[which(classes_list == "jobjRef")]

  # if no cores have been supplied, remove all running cores
  # else, remove matches between running and supplied cores

  if (length(supplied_cores) == 0) {

    rm(list = names(running_cores), envir = parent.frame())

    message("All r5r cores have been successfully stopped.")

  } else {

    matches_supplied <- running_cores[running_cores %in% supplied_cores]

    # if a match has been found, stop it
    # else, a non r5r core object has been supplied, which raises a warning

    if (length(matches_supplied) >= 1) {

      rm(list = names(matches_supplied), envir = parent.frame())

      message(paste0(paste(names(matches_supplied), collapse = ", "),
                     " has been successfully stopped."))

    } else {

      unknown_object <- current_objects[current_objects %in% supplied_cores]

      warning(paste0(paste(names(unknown_object), collapse = ", "),
                     " is not a r5r core object."))

    }

  }

}
