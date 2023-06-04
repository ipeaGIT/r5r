#' r5r: Rapid Realistic Routing with 'R5'
#'
#' Rapid realistic routing on multimodal transport networks (walk, bike, public
#' transport and car) using `R5`, the Rapid Realistic Routing on Real-world and
#' Reimagined networks engine <https://github.com/conveyal/r5>. The package
#' allows users to generate detailed routing analysis or calculate travel time
#' matrices using seamless parallel computing on top of the R5 Java machine.
#' While `R5` is developed by Conveyal, the package `r5r` is independently
#' developed by a team at the Institute for Applied Economic Research (Ipea)
#' with contributions from collaborators. Apart from the documentation in this
#' package, users will find additional information on `R5` documentation at
#' <https://docs.conveyal.com/>. Although we try to keep new releases of `r5r`
#' in synchrony with `R5`, the development of `R5` follows Conveyal's
#' independent update process. Hence, users should confirm if the `R5` version
#' implied by the Conveyal user manual (see
#' <https://docs.conveyal.com/changelog>) corresponds with the `R5` version
#' that `r5r` depends on.
#'
#' @section Usage:
#' Please check the vignettes on the [website](https://ipeagit.github.io/r5r/).
#'
#' @docType package
#' @name r5r
#' @aliases r5r-package
#'
#' @importFrom data.table := %between% %chin%
#'
#' @keywords internal
"_PACKAGE"

if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    c(
      "duration",
      "from_id",
      "to_id",
      "option",
      ".SD",
      "geometry",
      "route",
      "temp_duration",
      "temp_route",
      "route",
      "temp_sign",
      ".I",
      "segment_duration",
      "total_duration",
      "wait",
      "release_date",
      "con",
      "start_lon",
      "start_lat",
      "end_lon",
      "end_lat",
      "slope",
      "lat",
      "lon",
      "walk_multiplier",
      "bike_multiplier",
      "found",
      ".",
      "%>%",
      ":=",
      "%like%",
      "%chin%",
      "set",
      "travel_time",
      "id_orig",
      "lat_orig",
      "lon_orig",
      "id_dest",
      "lat_dest",
      "lon_dest",
      "i.lon",
      "i.lat",
      "total_time",
      "setting",
      "cutoff",
      'travel_time_p50',
      'id',
      'i.travel_time_p50',
      'i.isochrone'
    )
  )
}

.onAttach <- function(lib, pkg) {
  packageStartupMessage(
    "Please make sure you have already allocated ",
    "some memory to Java by running:\n",
    "  options(java.parameters = '-Xmx2G').\n",
    "You should replace '2G' by the amount of memory you'll require. ",
    "Currently, Java memory is set to ", getOption("java.parameters")
  )
}
