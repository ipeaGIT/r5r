# Detailed itineraries between origin-destination pairs

Returns detailed trip information between origin-destination pairs. The
output includes the waiting and moving time in each trip leg, as well as
some info such as the distance traveled, the routes used and the
geometry of each leg. Please note that this function was originally
conceptualized as a trip planning functionality, similar to other
commercial and non-commercial APIs and apps (e.g. Moovit, Google's
Directions API, OpenTripPlanning's PlannerResource API). Thus, it
consumes much more time and memory than the other (more analytical)
routing functions included in the package.

## Usage

``` r
detailed_itineraries(
  r5r_network,
  r5r_core = deprecated(),
  origins,
  destinations,
  mode = "WALK",
  mode_egress = "WALK",
  departure_datetime = Sys.time(),
  time_window = 10L,
  suboptimal_minutes = 0L,
  max_walk_time = Inf,
  max_bike_time = Inf,
  max_car_time = Inf,
  max_trip_duration = 120L,
  walk_speed = 3.6,
  bike_speed = 12,
  max_rides = 3,
  max_lts = 2,
  shortest_path = TRUE,
  all_to_all = FALSE,
  fare_structure = NULL,
  max_fare = Inf,
  new_carspeeds = NULL,
  carspeed_scale = 1,
  new_lts = NULL,
  n_threads = Inf,
  verbose = FALSE,
  progress = FALSE,
  drop_geometry = FALSE,
  osm_link_ids = FALSE,
  output_dir = NULL
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

- origins, destinations:

  Either a `POINT sf` object with WGS84 CRS, or a `data.frame`
  containing the columns `id`, `lon` and `lat`.

- mode:

  A character vector. The transport modes allowed for access, transfer
  and vehicle legs of the trips. Defaults to `WALK`. Please see details
  for other options.

- mode_egress:

  A character vector. The transport mode used after egress from the last
  public transport. It can be either `WALK`, `BICYCLE` or `CAR`.
  Defaults to `WALK`. Ignored when public transport is not used.

- departure_datetime:

  A POSIXct object. Please note that the departure time only influences
  public transport legs. When working with public transport networks,
  please check the `calendar.txt` within your GTFS feeds for valid
  dates. Please see details for further information on how datetimes are
  parsed.

- time_window:

  An integer. The time window in minutes for which `r5r` will calculate
  multiple itineraries departing each minute. Defaults to 10 minutes. If
  the same sequence of routes appear in different minutes of the time
  window, only the fastest of them will be kept in the output. This
  happens because the result is not aggregated by percentile, as opposed
  to other routing functions in the package. Because of that, the output
  may contain trips departing after the specified `departure_datetime`,
  but still within the time window. Please read the time window vignette
  for more details on how this argument affects the results of each
  routing function:
  [`vignette("time_window", package = "r5r")`](https://ipeagit.github.io/r5r/articles/time_window.md).

- suboptimal_minutes:

  A number. The difference in minutes that each non-optimal RAPTOR
  branch can have from the optimal branch without being disregarded by
  the routing algorithm. If, for example, users set
  `suboptimal_minutes = 10`, the routing algorithm will consider
  sub-optimal routes that arrive up to 10 minutes after the arrival of
  the optimal one. This argument emulates the real-life behaviour that
  makes people want to take a path that is technically not optimal in
  terms of travel time, for example, for some practical reasons (e.g.
  mode preference, safety, etc). In practice, the higher this value, the
  more itineraries will be returned in the final result.

- max_walk_time:

  An integer. The maximum walking time (in minutes) to access and egress
  the transit network, to make transfers within the network or to
  complete walk-only trips. Defaults to no restrictions (numeric value
  of `Inf`), as long as `max_trip_duration` is respected. When routing
  transit trips, the max time is considered separately for each leg
  (e.g. if you set `max_walk_time` to 15, you could get trips with an up
  to 15 minutes walk leg to reach transit and another up to 15 minutes
  walk leg to reach the destination after leaving transit. In walk-only
  trips, whenever `max_walk_time` differs from `max_trip_duration`, the
  lowest value is considered.

- max_bike_time:

  An integer. The maximum cycling time (in minutes) to access and egress
  the transit network, to make transfers within the network or to
  complete bicycle-only trips. Defaults to no restrictions (numeric
  value of `Inf`), as long as `max_trip_duration` is respected. When
  routing transit trips, the max time is considered separately for each
  leg (e.g. if you set `max_bike_time` to 15, you could get trips with
  an up to 15 minutes cycle leg to reach transit and another up to 15
  minutes cycle leg to reach the destination after leaving transit. In
  bicycle-only trips, whenever `max_bike_time` differs from
  `max_trip_duration`, the lowest value is considered.

- max_car_time:

  An integer. The maximum driving time (in minutes) to access and egress
  the transit network. Defaults to no restrictions, as long as
  `max_trip_duration` is respected. The max time is considered
  separately for each leg (e.g. if you set `max_car_time` to 15 minutes,
  you could potentially drive up to 15 minutes to reach transit, and up
  to *another* 15 minutes to reach the destination after leaving
  transit). Defaults to `Inf`, no limit.

- max_trip_duration:

  An integer. The maximum trip duration in minutes. Defaults to 120
  minutes (2 hours).

- walk_speed:

  A numeric. Average walk speed in km/h. Defaults to 3.6 km/h.

- bike_speed:

  A numeric. Average cycling speed in km/h. Defaults to 12 km/h.

- max_rides:

  An integer. The maximum number of public transport rides allowed in
  the same trip. Defaults to 3.

- max_lts:

  An integer between 1 and 4. The maximum level of traffic stress that
  cyclists will tolerate. A value of 1 means cyclists will only travel
  through the quietest streets, while a value of 4 indicates cyclists
  can travel through any road. Defaults to 2. Please see details for
  more information.

- shortest_path:

  A logical. Whether the function should only return the fastest
  itinerary between each origin and destination pair (the default) or
  multiple alternatives.

- all_to_all:

  A logical. Whether to query routes between the 1st origin to the 1st
  destination, then the 2nd origin to the 2nd destination, and so on
  (`FALSE`, the default) or to query routes between all origins to all
  destinations (`TRUE`).

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipeagit.github.io/r5r/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. Please
  see the fare structure vignette to understand how this object is
  structured:
  [`vignette("fare_structure", package = "r5r")`](https://ipeagit.github.io/r5r/articles/fare_structure.md).

- max_fare:

  A number. The maximum value that trips can cost when calculating the
  fastest journey between each origin and destination pair.

- new_carspeeds:

  A `data.frame` specifying the new car speed for each OSM edge id. This
  table must contain columns `osm_id`, `max_speed` and `speed_type`. The
  `"speed_type"` column is of class character and it indicates whether
  the values in `"max_speed"` should be interpreted as percentages of
  original speeds (`"scale"`) or as absolute speeds (`"km/h"`).
  Alternatively, the `new_carspeeds` parameter can receive an
  `sf data.frame` with POLYGON geometry that indicates the new car speed
  for all the roads that fall within each polygon. In this case, the
  table must contain the columns `poly_id` with a unique id for each
  polygon, `scale` with the new speed scaling factors and `priority`,
  which is a number ranking which polygon should be considered in case
  of overlapping polygons. See more into in the
  `link to congestion vignette`.

- carspeed_scale:

  Numeric. The default car speed to use for road segments not specified
  in `new_carspeeds`. By default, it is `NULL` and the speeds of the
  unlisted roads are kept unchanged.

- new_lts:

  A `data.frame` specifying the new LTS levels for each OSM edge id. The
  table must contain columns `osm_id` and `lts`. Alternatively, the
  `new_lts` parameter can receive an `sf data.frame` with LINESTRING
  geometry. R5 will then find the nearest road for each LINESTRING and
  update its LTS value accordingly.

- n_threads:

  An integer. The number of threads to use when running the router in
  parallel. Defaults to use all available threads (Inf).

- verbose:

  A logical. Whether to show `R5` informative messages when running the
  function. Defaults to `FALSE` (please note that in such case `R5`
  error messages are still shown). Setting `verbose` to `TRUE` shows
  detailed output, which can be useful for debugging issues not caught
  by `r5r`.

- progress:

  A logical. Whether to show a progress counter when running the router.
  Defaults to `FALSE`. Only works when `verbose` is set to `FALSE`, so
  the progress counter does not interfere with `R5`'s output messages.
  Setting `progress` to `TRUE` may impose a small penalty for
  computation efficiency, because the progress counter must be
  synchronized among all active threads.

- drop_geometry:

  A logical. Whether the output should include the geometry of each trip
  leg or not. The default value of `FALSE` keeps the geometry column in
  the result.

- osm_link_ids:

  A logical. Whether the output should include additional columns with
  the OSM ids of the road segments used along the trip geometry.
  Defaults to `FALSE`. Keep in mind that the `osm_id` for a road will be
  returned even if the route uses a small stretch of the road (e.g. 5m
  of a 600m street segment). If you want more precision you should use
  the column `edge_id` which returns segments of the exact length used
  in the trip, and you can later tie that back to the `osm_id`.

- output_dir:

  Either `NULL` or a path to an existing directory. When not `NULL` (the
  default), the function will write one `.csv` file with the results for
  each origin in the specified directory. In such case, the function
  returns the path specified in this parameter. This parameter is
  particularly useful when running on memory-constrained settings
  because writing the results directly to disk prevents `r5r` from
  loading them to RAM memory.

## Value

When `drop_geometry` is `FALSE`, the function outputs a `LINESTRING sf`
with detailed information on the itineraries between the specified
origins and destinations. When `TRUE`, the output is a `data.table`. All
distances are in meters and travel times are in minutes. If `output_dir`
is not `NULL`, the function returns the path specified in that
parameter, in which the `.csv` files containing the results are saved.

## Transport modes

`R5` allows for multiple combinations of transport modes. The options
include:

- **Transit modes:** `TRAM`, `SUBWAY`, `RAIL`, `BUS`, `FERRY`,
  `CABLE_CAR`, `GONDOLA`, `FUNICULAR`. The option `TRANSIT`
  automatically considers all public transport modes available.

- **Non transit modes:** `WALK`, `BICYCLE`, `CAR`, `BICYCLE_RENT`,
  `CAR_PARK`.

## Level of Traffic Stress (LTS)

When cycling is enabled in `R5` (by passing the value `BIKE` to either
`mode` or `mode_egress`), setting `max_lts` will allow cycling only on
streets with a given level of danger/stress. Setting `max_lts` to 1, for
example, will allow cycling only on separated bicycle infrastructure or
low-traffic streets and routing will revert to walking when traversing
any links with LTS exceeding 1. Setting `max_lts` to 3 will allow
cycling on links with LTS 1, 2 or 3. Routing also reverts to walking if
the street segment is tagged as non-bikable in OSM (e.g. a staircase),
independently of the specified max LTS.

The default methodology for assigning LTS values to network edges is
based on commonly tagged attributes of OSM ways. See more info about LTS
in the original documentation of R5 from Conveyal at
<https://docs.conveyal.com/learn-more/traffic-stress>. In summary:

- **LTS 1**: Tolerable for children. This includes low-speed, low-volume
  streets, as well as those with separated bicycle facilities (such as
  parking-protected lanes or cycle tracks).

- **LTS 2**: Tolerable for the mainstream adult population. This
  includes streets where cyclists have dedicated lanes and only have to
  interact with traffic at formal crossing.

- **LTS 3**: Tolerable for "enthused and confident" cyclists. This
  includes streets which may involve close proximity to moderate- or
  high-speed vehicular traffic.

- **LTS 4**: Tolerable only for "strong and fearless" cyclists. This
  includes streets where cyclists are required to mix with moderate- to
  high-speed vehicular traffic.

For advanced users, you can provide custom LTS values by adding a tag
`<key = "lts">` to the `osm.pbf` file.

## Datetime parsing

`r5r` ignores the timezone attribute of datetime objects when parsing
dates and times, using the study area's timezone instead. For example,
let's say you are running some calculations using Rio de Janeiro,
Brazil, as your study area. The datetime
`as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")` will
be parsed as May 13th, 2019, 14:00h in Rio's local time, as expected.
But
`as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S", tz = "Europe/Paris")`
will also be parsed as the exact same date and time in Rio's local time,
perhaps surprisingly, ignoring the timezone attribute.

## Routing algorithm

The `detailed_itineraries()` and
[`pareto_frontier()`](https://ipeagit.github.io/r5r/reference/pareto_frontier.md)
functions use an `R5`-specific extension to the McRAPTOR routing
algorithm. The implementation used in `detailed_itineraries()` allows
the router to find paths that are optimal and less than optimal in terms
of travel time, with some heuristics around multiple access modes,
riding the same patterns, etc. The specific extension to McRAPTOR to do
suboptimal path routing is not documented yet, but a detailed
description of base McRAPTOR can be found in Delling et al (2015). The
implementation used in
[`pareto_frontier()`](https://ipeagit.github.io/r5r/reference/pareto_frontier.md),
on the other hand, returns only the fastest trip within a given monetary
cutoff, ignoring slower trips that cost the same. A detailed discussion
on the algorithm can be found in Conway and Stewart (2019).

- Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public
  transit routing. Transportation Science, 49(3), 591-604.
  [doi:10.1287/trsc.2014.0534](https://doi.org/10.1287/trsc.2014.0534)

- Conway, M. W., & Stewart, A. F. (2019). Getting Charlie off the MTA: a
  multiobjective optimization method to account for cost constraints in
  public transit accessibility metrics. International Journal of
  Geographical Information Science, 33(9), 1759-1787.
  [doi:10.1080/13658816.2019.1605075](https://doi.org/10.1080/13658816.2019.1605075)

## See also

Other routing:
[`arrival_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/arrival_travel_time_matrix.md),
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/expanded_travel_time_matrix.md),
[`pareto_frontier()`](https://ipeagit.github.io/r5r/reference/pareto_frontier.md),
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/travel_time_matrix.md)

## Examples

``` r
library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# inputs
departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

det <- detailed_itineraries(
  r5r_network,
  origins = points[10,],
  destinations = points[12,],
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60
)
head(det)
#> Simple feature collection with 5 features and 16 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -51.24094 ymin: -30.05 xmax: -51.19762 ymax: -29.99729
#> Geodetic CRS:  WGS 84
#>            from_id  from_lat  from_lon                          to_id    to_lat
#> 1 farrapos_station -29.99772 -51.19762 praia_de_belas_shopping_center -30.04995
#> 2 farrapos_station -29.99772 -51.19762 praia_de_belas_shopping_center -30.04995
#> 3 farrapos_station -29.99772 -51.19762 praia_de_belas_shopping_center -30.04995
#> 4 farrapos_station -29.99772 -51.19762 praia_de_belas_shopping_center -30.04995
#> 5 farrapos_station -29.99772 -51.19762 praia_de_belas_shopping_center -30.04995
#>      to_lon option departure_time total_duration total_distance segment mode
#> 1 -51.22875      1       14:09:10           33.9           9460       1 WALK
#> 2 -51.22875      1       14:09:10           33.9           9460       2 RAIL
#> 3 -51.22875      1       14:09:10           33.9           9460       3 WALK
#> 4 -51.22875      1       14:09:10           33.9           9460       4  BUS
#> 5 -51.22875      1       14:09:10           33.9           9460       5 WALK
#>   segment_duration wait distance  route                       geometry
#> 1              4.5  0.0      174        LINESTRING (-51.1981 -29.99...
#> 2              6.6  1.4     4796 LINHA1 LINESTRING (-51.19763 -29.9...
#> 3              4.1  0.0      256        LINESTRING (-51.22827 -30.0...
#> 4             10.4  4.4     4083    188 LINESTRING (-51.22926 -30.0...
#> 5              2.6  0.0      151        LINESTRING (-51.22949 -30.0...

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
