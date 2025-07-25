% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/set.R
\name{set_fare_cutoffs}
\alias{set_fare_cutoffs}
\title{Set monetary cutoffs}
\usage{
set_fare_cutoffs(r5r_network, fare_cutoffs)
}
\arguments{
\item{r5r_network}{A routable transport network created with \code{\link[=build_network]{build_network()}}.}

\item{fare_cutoffs}{A path.}
}
\value{
Invisibly returns \code{TRUE}.
}
\description{
Sets the monetary cutoffs that should be considered when calculating the
Pareto frontier.
}
\seealso{
Other setting functions: 
\code{\link{reverse_if_direct_mode}()},
\code{\link{set_breakdown}()},
\code{\link{set_cutoffs}()},
\code{\link{set_elevation}()},
\code{\link{set_expanded_travel_times}()},
\code{\link{set_fare_structure}()},
\code{\link{set_max_fare}()},
\code{\link{set_max_lts}()},
\code{\link{set_max_rides}()},
\code{\link{set_monte_carlo_draws}()},
\code{\link{set_n_threads}()},
\code{\link{set_output_dir}()},
\code{\link{set_percentiles}()},
\code{\link{set_progress}()},
\code{\link{set_speed}()},
\code{\link{set_suboptimal_minutes}()},
\code{\link{set_time_window}()},
\code{\link{set_verbose}()}
}
\concept{setting functions}
\keyword{internal}
