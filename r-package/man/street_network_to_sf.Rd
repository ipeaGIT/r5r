% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/street_network_to_sf.R
\name{street_network_to_sf}
\alias{street_network_to_sf}
\title{Extract OpenStreetMap network in sf format from a network.dat built with setup_r5}
\usage{
street_network_to_sf(r5r_core)
}
\arguments{
\item{r5r_core}{a rJava object, the output from 'r5r::setup_r5()'}
}
\value{
A list with two components of a street network in sf format: vertices
(POINT) and edges (LINESTRING).
}
\description{
Extract OpenStreetMap network in sf format from a network.dat built with setup_r5
}
\examples{
if (interactive()) {

library(r5r)

# build transport network
path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path)

# extract street network from r5r_core
street_net <- street_network_to_sf(r5r_core)

stop_r5(r5r_core)
}
}
\seealso{
Other support functions: 
\code{\link{assert_decay_function}()},
\code{\link{assert_points_input}()},
\code{\link{check_connection}()},
\code{\link{download_metadata}()},
\code{\link{find_snap}()},
\code{\link{posix_to_string}()},
\code{\link{select_mode}()},
\code{\link{set_max_lts}()},
\code{\link{set_max_rides}()},
\code{\link{set_max_street_time}()},
\code{\link{set_n_threads}()},
\code{\link{set_speed}()},
\code{\link{set_suboptimal_minutes}()},
\code{\link{set_verbose}()},
\code{\link{stop_r5}()},
\code{\link{transit_network_to_sf}()}
}
\concept{support functions}
