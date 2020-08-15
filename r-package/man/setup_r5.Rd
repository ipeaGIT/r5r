% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/setup_r5.R
\name{setup_r5}
\alias{setup_r5}
\title{Creates transport network used for routing in R5}
\usage{
setup_r5(data_path, version = "4.9.0")
}
\arguments{
\item{data_path}{character string, the directory where data inputs are stored
and where the built network.dat will be saved.}

\item{version}{character string, the version of R5 to be used. Defaults to
latest version '4.9.0'.}
}
\value{
Returns an rJava object to connect with R5 routing engine
}
\description{
Combines data inputs in a directory to build a multimodal
transport networked used for routing in R5. The directory must contain at
least one street network file (in .pbf format) OR a public transport data
set (in GTFS format). If there is more than one GTFS file in the directory
R5 will merge both files to build the transport network.
}
\examples{
\donttest{

library(r5r)

# directory with street network and gtfs files
path <- system.file("extdata", package = "r5r")

r5r_core <- setup_r5(data_path = path)
}
}
\seealso{
Other setup: 
\code{\link{download_r5}()}
}
\concept{setup}