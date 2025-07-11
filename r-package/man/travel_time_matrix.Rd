% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/travel_time_matrix.R
\name{travel_time_matrix}
\alias{travel_time_matrix}
\title{Calculate travel time matrix between origin destination pairs considering a
departure time}
\usage{
travel_time_matrix(
  r5r_network,
  r5r_core = deprecated(),
  origins,
  destinations,
  mode = "WALK",
  mode_egress = "WALK",
  departure_datetime = Sys.time(),
  time_window = 10L,
  percentiles = 50L,
  fare_structure = NULL,
  max_fare = Inf,
  max_walk_time = Inf,
  max_bike_time = Inf,
  max_car_time = Inf,
  max_trip_duration = 120L,
  walk_speed = 3.6,
  bike_speed = 12,
  max_rides = 3,
  max_lts = 2,
  draws_per_minute = 5L,
  n_threads = Inf,
  verbose = FALSE,
  progress = FALSE,
  output_dir = NULL
)
}
\arguments{
\item{r5r_network}{A routable transport network created with \code{\link[=build_network]{build_network()}}.}

\item{r5r_core}{The \code{r5r_core} argument is deprecated as of r5r v2.3.0.
Please use the \code{r5r_network} argument instead.}

\item{origins, destinations}{Either a \verb{POINT sf} object with WGS84 CRS, or a
\code{data.frame} containing the columns \code{id}, \code{lon} and \code{lat}.}

\item{mode}{A character vector. The transport modes allowed for access,
transfer and vehicle legs of the trips. Defaults to \code{WALK}. Please see
details for other options.}

\item{mode_egress}{A character vector. The transport mode used after egress
from the last public transport. It can be either \code{WALK}, \code{BICYCLE} or
\code{CAR}. Defaults to \code{WALK}. Ignored when public transport is not used.}

\item{departure_datetime}{A POSIXct object. Please note that the departure
time only influences public transport legs. When working with public
transport networks, please check the \code{calendar.txt} within your GTFS feeds
for valid dates. Please see details for further information on how
datetimes are parsed.}

\item{time_window}{An integer. The time window in minutes for which \code{r5r}
will calculate multiple travel time matrices departing each minute.
Defaults to 10 minutes. By default, the function returns the result based
on median travel times, but the user can set the \code{percentiles} parameter to
extract more results. Please read the time window vignette for more details
on its usage \code{vignette("time_window", package = "r5r")}}

\item{percentiles}{An integer vector (max length of 5). Specifies the
percentile to use when returning travel time estimates within the given
time window. For example, if the 25th travel time percentile between A and
B is 15 minutes, 25\% of all trips taken between these points within the
specified time window are shorter than 15 minutes. Defaults to 50,
returning the median travel time. If a vector with length bigger than 1 is
passed, the output contains an additional column for each percentile
specifying the percentile travel time estimate. each estimate. Due to
upstream restrictions, only 5 percentiles can be specified at a time. For
more details, please see R5 documentation at
\url{https://docs.conveyal.com/analysis/methodology#accounting-for-variability}.}

\item{fare_structure}{A fare structure object, following the convention
set in \code{\link[=setup_fare_structure]{setup_fare_structure()}}. This object describes how transit fares
should be calculated. Please see the fare structure vignette to
understand how this object is structured:
\code{vignette("fare_structure", package = "r5r")}.}

\item{max_fare}{A number. The maximum value that trips can cost when
calculating the fastest journey between each origin and destination pair.}

\item{max_walk_time}{An integer. The maximum walking time (in minutes) to
access and egress the transit network, to make transfers within the network
or to complete walk-only trips. Defaults to no restrictions (numeric value
of \code{Inf}), as long as \code{max_trip_duration} is respected. When routing
transit trips, the max time is considered separately for each leg (e.g. if
you set \code{max_walk_time} to 15, you could get trips with an up to 15 minutes
walk leg to reach transit and another up to 15 minutes walk leg to reach
the destination after leaving transit. In walk-only trips, whenever
\code{max_walk_time} differs from \code{max_trip_duration}, the lowest value is
considered.}

\item{max_bike_time}{An integer. The maximum cycling time (in minutes) to
access and egress the transit network, to make transfers within the network
or to complete bicycle-only trips. Defaults to no restrictions (numeric
value of \code{Inf}), as long as \code{max_trip_duration} is respected. When routing
transit trips, the max time is considered separately for each leg (e.g. if
you set \code{max_bike_time} to 15, you could get trips with an up to 15 minutes
cycle leg to reach transit and another up to 15 minutes cycle leg to reach
the destination after leaving transit. In bicycle-only trips, whenever
\code{max_bike_time} differs from \code{max_trip_duration}, the lowest value is
considered.}

\item{max_car_time}{An integer. The maximum driving time (in minutes) to
access and egress the transit network. Defaults to no restrictions, as long
as \code{max_trip_duration} is respected. The max time is considered separately
for each leg (e.g. if you set \code{max_car_time} to 15 minutes, you could
potentially drive up to 15 minutes to reach transit, and up to \emph{another} 15
minutes to reach the destination after leaving transit). Defaults to \code{Inf},
no limit.}

\item{max_trip_duration}{An integer. The maximum trip duration in minutes.
Defaults to 120 minutes (2 hours).}

\item{walk_speed}{A numeric. Average walk speed in km/h. Defaults to 3.6
km/h.}

\item{bike_speed}{A numeric. Average cycling speed in km/h. Defaults to 12
km/h.}

\item{max_rides}{An integer. The maximum number of public transport rides
allowed in the same trip. Defaults to 3.}

\item{max_lts}{An integer between 1 and 4. The maximum level of traffic
stress that cyclists will tolerate. A value of 1 means cyclists will only
travel through the quietest streets, while a value of 4 indicates cyclists
can travel through any road. Defaults to 2. Please see details for more
information.}

\item{draws_per_minute}{An integer. The number of Monte Carlo draws to
perform per time window minute when calculating travel time matrices and
when estimating accessibility. Defaults to 5. This would mean 300 draws in
a 60-minute time window, for example. This parameter only affects the
results when the GTFS feeds contain a \code{frequencies.txt} table. If the GTFS
feed does not have a frequency table, r5r still allows for multiple runs
over the set \code{time_window} but in a deterministic way.}

\item{n_threads}{An integer. The number of threads to use when running the
router in parallel. Defaults to use all available threads (Inf).}

\item{verbose}{A logical. Whether to show \code{R5} informative messages when
running the function. Defaults to \code{FALSE} (please note that in such case
\code{R5} error messages are still shown). Setting \code{verbose} to \code{TRUE} shows
detailed output, which can be useful for debugging issues not caught by
\code{r5r}.}

\item{progress}{A logical. Whether to show a progress counter when running
the router. Defaults to \code{FALSE}. Only works when \code{verbose} is set to
\code{FALSE}, so the progress counter does not interfere with \code{R5}'s output
messages. Setting \code{progress} to \code{TRUE} may impose a small penalty for
computation efficiency, because the progress counter must be synchronized
among all active threads.}

\item{output_dir}{Either \code{NULL} or a path to an existing directory. When not
\code{NULL} (the default), the function will write one \code{.csv} file with the
results for each origin in the specified directory. In such case, the
function returns the path specified in this parameter. This parameter is
particularly useful when running on memory-constrained settings because
writing the results directly to disk prevents \code{r5r} from loading them to
RAM memory.}
}
\value{
A \code{data.table} with travel time estimates (in minutes) between
origin and destination pairs. Pairs whose trips couldn't be completed
within the maximum travel time and/or whose origin is too far from the
street network are not returned in the \code{data.table}. If \code{output_dir} is
not \code{NULL}, the function returns the path specified in that parameter, in
which the \code{.csv} files containing the results are saved.
}
\description{
Fast computation of travel time estimates between one or multiple origin
destination pairs. This function considers a departure time set by the user.
If you want to calculate travel times considering a time of arrival, have a
look at the \code{\link[=arrival_travel_time_matrix]{arrival_travel_time_matrix()}} function.
}
\section{Transport modes}{


\code{R5} allows for multiple combinations of transport modes. The options
include:
\itemize{
\item \strong{Transit modes:} \code{TRAM}, \code{SUBWAY}, \code{RAIL}, \code{BUS}, \code{FERRY}, \code{CABLE_CAR},
\code{GONDOLA}, \code{FUNICULAR}. The option \code{TRANSIT} automatically considers all
public transport modes available.
\item \strong{Non transit modes:} \code{WALK}, \code{BICYCLE}, \code{CAR}, \code{BICYCLE_RENT},
\code{CAR_PARK}.
}
}

\section{Level of Traffic Stress (LTS)}{


When cycling is enabled in \code{R5} (by passing the value \code{BIKE} to either
\code{mode} or \code{mode_egress}), setting \code{max_lts} will allow cycling only on
streets with a given level of danger/stress. Setting \code{max_lts} to 1, for
example, will allow cycling only on separated bicycle infrastructure or
low-traffic streets and routing will revert to walking when traversing any
links with LTS exceeding 1. Setting \code{max_lts} to 3 will allow cycling on
links with LTS 1, 2 or 3. Routing also reverts to walking if the street
segment is tagged as non-bikable in OSM (e.g. a staircase), independently of
the specified max LTS.

The default methodology for assigning LTS values to network edges is based
on commonly tagged attributes of OSM ways. See more info about LTS in the
original documentation of R5 from Conveyal at
\url{https://docs.conveyal.com/learn-more/traffic-stress}. In summary:
\itemize{
\item \strong{LTS 1}: Tolerable for children. This includes low-speed, low-volume
streets, as well as those with separated bicycle facilities (such as
parking-protected lanes or cycle tracks).
\item \strong{LTS 2}: Tolerable for the mainstream adult population. This includes
streets where cyclists have dedicated lanes and only have to interact with
traffic at formal crossing.
\item \strong{LTS 3}: Tolerable for "enthused and confident" cyclists. This includes
streets which may involve close proximity to moderate- or high-speed
vehicular traffic.
\item \strong{LTS 4}: Tolerable only for "strong and fearless" cyclists. This
includes streets where cyclists are required to mix with moderate- to
high-speed vehicular traffic.
}

For advanced users, you can provide custom LTS values by adding a tag \verb{<key = "lts">} to the \code{osm.pbf} file.
}

\section{Datetime parsing}{


\code{r5r} ignores the timezone attribute of datetime objects when parsing dates
and times, using the study area's timezone instead. For example, let's say
you are running some calculations using Rio de Janeiro, Brazil, as your study
area. The datetime \code{as.POSIXct("13-05-2019 14:00:00", format = "\%d-\%m-\%Y \%H:\%M:\%S")} will be parsed as May 13th, 2019, 14:00h in
Rio's local time, as expected. But \code{as.POSIXct("13-05-2019 14:00:00", format = "\%d-\%m-\%Y \%H:\%M:\%S", tz = "Europe/Paris")} will also be parsed as
the exact same date and time in Rio's local time, perhaps surprisingly,
ignoring the timezone attribute.
}

\section{Routing algorithm}{


The \code{\link[=travel_time_matrix]{travel_time_matrix()}}, \code{\link[=expanded_travel_time_matrix]{expanded_travel_time_matrix()}},
\code{\link[=arrival_travel_time_matrix]{arrival_travel_time_matrix()}}  and \code{\link[=accessibility]{accessibility()}} functions use an
\code{R5}-specific extension to the RAPTOR routing algorithm (see Conway et al.,
2017). This RAPTOR extension uses a systematic sample of one departure per
minute over the time window set by the user in the 'time_window' parameter.
A detailed description of base RAPTOR can be found in Delling et al (2015).
However, whenever the user includes transit fares inputs to these functions,
they automatically switch to use an \code{R5}-specific extension to the McRAPTOR
routing algorithm.
\itemize{
\item Conway, M. W., Byrd, A., & van der Linden, M. (2017). Evidence-based
transit and land use sketch planning using interactive accessibility methods
on combined schedule and headway-based networks. Transportation Research
Record, 2653(1), 45-53. \doi{10.3141/2653-06}
\item Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public
transit routing. Transportation Science, 49(3), 591-604.
\doi{10.1287/trsc.2014.0534}
}
}

\examples{
\dontshow{if (identical(tolower(Sys.getenv("NOT_CRAN")), "true")) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "\%d-\%m-\%Y \%H:\%M:\%S"
)

ttm <- travel_time_matrix(
  r5r_network,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60
)
head(ttm)

# using a larger time window
ttm <- travel_time_matrix(
  r5r_network,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  time_window = 30,
  max_trip_duration = 60
)
head(ttm)

# selecting different percentiles
ttm <- travel_time_matrix(
  r5r_network,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  time_window = 30,
  percentiles = c(25, 50, 75),
  max_trip_duration = 60
)
head(ttm)

# use a fare structure and set a max fare to take monetary constraints into
# account
fare_structure <- read_fare_structure(
  file.path(data_path, "fares/fares_poa.zip")
)
ttm <- travel_time_matrix(
  r5r_network,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  fare_structure = fare_structure,
  max_fare = 5,
  max_trip_duration = 60,
)
head(ttm)

stop_r5(r5r_network)
\dontshow{\}) # examplesIf}
}
\seealso{
Other routing: 
\code{\link{arrival_travel_time_matrix}()},
\code{\link{detailed_itineraries}()},
\code{\link{expanded_travel_time_matrix}()},
\code{\link{pareto_frontier}()}
}
\concept{routing}
