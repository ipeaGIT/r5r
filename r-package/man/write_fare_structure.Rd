% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fare_structure.R
\name{write_fare_structure}
\alias{write_fare_structure}
\title{Write a fare structure object to disk}
\usage{
write_fare_structure(fare_structure, file_path)
}
\arguments{
\item{fare_structure}{A fare structure object, following the convention
set in \code{\link[=setup_fare_structure]{setup_fare_structure()}}. This object describes how transit fares
should be calculated. Please see the fare structure vignette to
understand how this object is structured:
\code{vignette("fare_structure", package = "r5r")}.}

\item{file_path}{A path to a \code{.zip} file. Where the fare structure should be
written to.}
}
\value{
The path passed to \code{file_path}, invisibly.
}
\description{
Writes a fare structure object do disk. Fare structure is saved as a
collection of \code{.csv} files inside a \code{.zip} file.
}
\examples{
\dontshow{if (identical(tolower(Sys.getenv("NOT_CRAN")), "true")) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
library(r5r)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)

fare_structure <- setup_fare_structure(r5r_network, base_fare = 5)

tmpfile <- tempfile("sample_fare_structure", fileext = ".zip")
write_fare_structure(fare_structure, tmpfile)
\dontshow{\}) # examplesIf}
}
\seealso{
Other fare structure: 
\code{\link{read_fare_structure}()},
\code{\link{setup_fare_structure}()}
}
\concept{fare structure}
