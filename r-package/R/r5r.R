#' r5r: Rapid Realistic Routing with 'R5'
#'
#' Rapid realistic routing on multimodal transport networks (walk, bike, public
#' transport and car) using 'R5', the Rapid Realistic Routing on Real-world and
#' Reimagined networks engine <https://github.com/conveyal/r5>. The package
#' allows users to generate detailed routing analysis or calculate travel time
#' matrices using seamless parallel computing on top of the R5 Java machine.
#' While R5 is developed by Conveyal, the package r5r is independently developed
#' by a team at the Institute for Applied Economic Research (Ipea) with
#' contributions from collaborators. Apart from the documentation in this
#' package, users will find additional information on R5 documentation at
#' <https://docs.conveyal.com/>. Although we try to keep new releases of r5r in
#' synchrony with R5, the development of R5 follows Conveyal's independent update
#' process. Hence, users should confirm the R5 version implied by the Conveyal
#' user manual (see <https://docs.conveyal.com/changelog>) corresponds with the
#' R5 version that r5r depends on.
#'
#' @section Usage:
#' Please check the vignettes on the [website](https://ipeagit.github.io/r5r/).
#'
#' @docType package
#' @name r5r
#' @aliases r5r-package
#'
#' @importFrom data.table := %between% fifelse %chin% set
#' @importFrom methods is signature
#' @importFrom curl has_internet
"_PACKAGE"

## quiets concerns of R CMD check re: the .'s that appear in pipelines
if(getRversion() >= "2.15.1") utils::globalVariables(
  c('is', 'duration', 'fromId', 'toId', 'option', 'option', '.SD', 'geometry',
    'route', 'temp_duration', 'temp_route', 'route', 'temp_sign', '.I',
    'segment_duration', 'total_duration', 'wait', 'release_date', 'con',
    "start_lon", "start_lat", "end_lon", "end_lat", "slope", "lat", "lon",
    "walk_multiplier", "bike_multiplier", "found", ".", "%>%", ":=", "%like%",
    "%chin%", "set"))


.onLoad = function(lib, pkg) {
  # rJava::.jpackage(name = "r5r")

  requireNamespace("sf")
  requireNamespace("rJava")
  requireNamespace("data.table")
}


.onAttach <- function(lib, pkg) {

  packageStartupMessage(paste0("Please make sure you have already allocated ",
                               "some memory to Java by running:\n",
                               "  options(java.parameters = '-Xmx2G').\n",
                               "Currently, Java memory is set to ",
                               getOption("java.parameters")))
}
