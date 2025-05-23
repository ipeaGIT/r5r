% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/assign.R
\name{assign_max_trip_duration}
\alias{assign_max_trip_duration}
\title{Assign max trip duration}
\usage{
assign_max_trip_duration(
  max_trip_duration,
  modes,
  max_walk_time,
  max_bike_time
)
}
\arguments{
\item{max_trip_duration}{A number.}
}
\value{
An \code{integer} representing the maximum trip duration in minutes.
}
\description{
Check and convert the max trip duration input.
}
\seealso{
Other assigning functions: 
\code{\link{assign_decay_function}()},
\code{\link{assign_departure}()},
\code{\link{assign_drop_geometry}()},
\code{\link{assign_max_street_time}()},
\code{\link{assign_mode}()},
\code{\link{assign_opportunities}()},
\code{\link{assign_osm_link_ids}()},
\code{\link{assign_points_input}()},
\code{\link{assign_shortest_path}()}
}
\concept{assigning functions}
\keyword{internal}
