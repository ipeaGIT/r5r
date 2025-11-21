# Calculate access to opportunities

Fast computation of access to opportunities given a selected decay
function.

## Usage

``` r
accessibility(
  r5r_network,
  r5r_core = deprecated(),
  origins,
  destinations,
  opportunities_colnames = "opportunities",
  mode = "WALK",
  mode_egress = "WALK",
  departure_datetime = Sys.time(),
  time_window = 10L,
  percentiles = 50L,
  decay_function = "step",
  cutoffs = NULL,
  decay_value = NULL,
  max_walk_time = Inf,
  max_bike_time = Inf,
  max_car_time = Inf,
  max_trip_duration = 120L,
  walk_speed = 3.6,
  bike_speed = 12,
  max_rides = 3,
  max_lts = 2,
  fare_structure = NULL,
  max_fare = Inf,
  new_carspeeds = NULL,
  carspeed_scale = 1,
  new_lts = NULL,
  draws_per_minute = 5L,
  n_threads = Inf,
  verbose = FALSE,
  progress = FALSE,
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

- opportunities_colnames:

  A character vector. The names of the columns in the `destinations`
  input that tells the number of opportunities in each location. Several
  different column names can be passed, in which case the accessibility
  to each kind of opportunity will be calculated.

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
  multiple travel time matrices departing each minute. Defaults to 10
  minutes. By default, the function returns the result based on median
  travel times, but the user can set the `percentiles` parameter to
  extract more results. Please read the time window vignette for more
  details on its usage
  [`vignette("time_window", package = "r5r")`](https://ipeagit.github.io/r5r/articles/time_window.md)

- percentiles:

  An integer vector (max length of 5). Specifies the percentile to use
  when returning accessibility estimates within the given time window.
  Please note that this parameter is applied to the travel time
  estimates that generate the accessibility results, and not to the
  accessibility distribution itself (i.e. if the 25th percentile is
  specified, the accessibility is calculated from the 25th percentile
  travel time, which may or may not be equal to the 25th percentile of
  the accessibility distribution itself). Defaults to 50, returning the
  accessibility calculated from the median travel time. If a vector with
  length bigger than 1 is passed, the output contains an additional
  column that specifies the percentile of each accessibility estimate.
  Due to upstream restrictions, only 5 percentiles can be specified at a
  time. For more details, please see `R5` documentation at
  <https://docs.conveyal.com/analysis/methodology#accounting-for-variability>.

- decay_function:

  A string. Which decay function to use when calculating accessibility.
  One of `step`, `exponential`, `fixed_exponential`, `linear` or
  `logistic`. Defaults to `step`, which is equivalent to a cumulative
  opportunities measure. Please see the details to understand how each
  alternative works and how they relate to the `cutoffs` and
  `decay_value` parameters.

- cutoffs:

  A numeric vector (maximum length of 12). This parameter has different
  effects for each decay function: it indicates the cutoff times in
  minutes when calculating cumulative opportunities accessibility with
  the `step` function, the median (or inflection point) of the decay
  curves in the `logistic` and `linear` functions, and the half-life in
  the `exponential` function. It has no effect when using the
  `fixed_exponential` function.

- decay_value:

  A number. Extra parameter to be passed to the selected
  `decay_function`. Has no effects when `decay_function` is either
  `step` or `exponential`.

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

- draws_per_minute:

  An integer. The number of Monte Carlo draws to perform per time window
  minute when calculating travel time matrices and when estimating
  accessibility. Defaults to 5. This would mean 300 draws in a 60-minute
  time window, for example. This parameter only affects the results when
  the GTFS feeds contain a `frequencies.txt` table. If the GTFS feed
  does not have a frequency table, r5r still allows for multiple runs
  over the set `time_window` but in a deterministic way.

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

- output_dir:

  Either `NULL` or a path to an existing directory. When not `NULL` (the
  default), the function will write one `.csv` file with the results for
  each origin in the specified directory. In such case, the function
  returns the path specified in this parameter. This parameter is
  particularly useful when running on memory-constrained settings
  because writing the results directly to disk prevents `r5r` from
  loading them to RAM memory.

## Value

A `data.table` with accessibility estimates for all origin points. This
`data.table` contain columns listing the origin id, the type of
opportunities to which accessibility was calculated, the travel time
percentile considered in the accessibility estimate and the specified
cutoff values (except in when `decay_function` is `fixed_exponential`,
in which case the `cutoff` parameter is not used). If `output_dir` is
not `NULL`, the function returns the path specified in that parameter,
in which the `.csv` files containing the results are saved.

## Decay functions

`R5` allows one to use different decay functions when calculating
accessibility. Please see the original `R5` documentation from Conveyal
for more information on each one one
(<https://docs.conveyal.com/learn-more/decay-functions>). A summary of
each available option, as well as the value passed to `decay_function`
to use it (inside parentheses) are listed below:

- **Step**, also known as cumulative opportunities (`"step"`):  
  a binary decay function used to find the sum of available
  opportunities within a specific travel time cutoff.

- **Logistic CDF** (`"logistic"`):  
  This is the logistic function, i.e. the cumulative distribution
  function of the logistic distribution, expressed such that its
  parameters are the median (inflection point) and standard deviation.
  This function applies a sigmoid rolloff that has a convenient
  relationship to discrete choice theory. Its parameters can be set to
  reflect a whole population's tolerance for making trips with different
  travel times. The function's value represents the probability that a
  randomly chosen member of the population would accept making a trip,
  given its duration. Opportunities are then weighted by how likely it
  is that a person would consider them "reachable".

  - Calibration: The median parameter is controlled by the `cutoff`
    parameter, leaving only the standard deviation to configure through
    the `decay_value` parameter.

- **Fixed Exponential** (`"fixed_exponential"`):  
  This function is of the form `exp(-Lt)` where L is a single fixed
  decay constant in the range (0, 1). It is constrained to be positive
  to ensure weights decrease (rather than grow) with increasing travel
  time.

  - Calibration: This function is controlled exclusively by the `L`
    constant, given by the `decay_value` parameter. Values provided in
    `cutoffs` are ignored.

- **Half-life Exponential Decay** (`"exponential"`):  
  This is similar to the fixed-exponential option above, but in this
  case the decay parameter is inferred from the `cutoffs` parameter
  values, which is treated as the half-life of the decay.

- **Linear** (`"linear"`):  
  This is a simple, vaguely sigmoid option, which may be useful when you
  have a sense of a maximum travel time that would be tolerated by any
  traveler, and a minimum time below which all travel is perceived to be
  equally easy.

  - Calibration: The transition region is transposable and symmetric
    around the `cutoffs` parameter values, taking `decay_value` minutes
    to taper down from one to zero.

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

The
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/travel_time_matrix.md),
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/expanded_travel_time_matrix.md),
[`arrival_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/arrival_travel_time_matrix.md)
and `accessibility()` functions use an `R5`-specific extension to the
RAPTOR routing algorithm (see Conway et al., 2017). This RAPTOR
extension uses a systematic sample of one departure per minute over the
time window set by the user in the 'time_window' parameter. A detailed
description of base RAPTOR can be found in Delling et al (2015).
However, whenever the user includes transit fares inputs to these
functions, they automatically switch to use an `R5`-specific extension
to the McRAPTOR routing algorithm.

- Conway, M. W., Byrd, A., & van der Linden, M. (2017). Evidence-based
  transit and land use sketch planning using interactive accessibility
  methods on combined schedule and headway-based networks.
  Transportation Research Record, 2653(1), 45-53.
  [doi:10.3141/2653-06](https://doi.org/10.3141/2653-06)

- Delling, D., Pajor, T., & Werneck, R. F. (2015). Round-based public
  transit routing. Transportation Science, 49(3), 591-604.
  [doi:10.1287/trsc.2014.0534](https://doi.org/10.1287/trsc.2014.0534)

## Examples

``` r
library(r5r)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> Downloading R5 jar file to /home/runner/.cache/R/r5r/r5_jar_v7.4.0/r5-v7.4-all.jar
#> ✔ Finished building network at /home/runner/work/_temp/Library/r5r/extdata/poa
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[1:5, ]

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

access <- accessibility(
  r5r_network ,
  origins = points,
  destinations = points,
  opportunities_colnames = "schools",
  mode = "WALK",
  departure_datetime = departure_datetime,
  decay_function = "step",
  cutoffs = 30,
  max_trip_duration = 30
)
head(access)
#>                 id opportunity percentile cutoff accessibility
#>             <char>      <char>      <int>  <int>         <num>
#> 1: 89a901291abffff     schools         50     30             0
#> 2: 89a9012a3cfffff     schools         50     30             0
#> 3: 89a901295b7ffff     schools         50     30             0
#> 4: 89a901284a3ffff     schools         50     30             0
#> 5: 89a9012809bffff     schools         50     30             0

# using a different decay function
access <- accessibility(
  r5r_network ,
  origins = points,
  destinations = points,
  opportunities_colnames = "schools",
  mode = "WALK",
  departure_datetime = departure_datetime,
  decay_function = "logistic",
  cutoffs = 30,
  decay_value = 1,
  max_trip_duration = 30
)
head(access)
#>                 id opportunity percentile cutoff accessibility
#>             <char>      <char>      <int>  <int>         <num>
#> 1: 89a901291abffff     schools         50     30             0
#> 2: 89a9012a3cfffff     schools         50     30             0
#> 3: 89a901295b7ffff     schools         50     30             0
#> 4: 89a901284a3ffff     schools         50     30             0
#> 5: 89a9012809bffff     schools         50     30             0

# using several cutoff values
access <- accessibility(
  r5r_network ,
  origins = points,
  destinations = points,
  opportunities_colnames = "schools",
  mode = "WALK",
  departure_datetime = departure_datetime,
  decay_function = "step",
  cutoffs = c(15, 30),
  max_trip_duration = 30
)
head(access)
#>                 id opportunity percentile cutoff accessibility
#>             <char>      <char>      <int>  <int>         <num>
#> 1: 89a901291abffff     schools         50     15             0
#> 2: 89a901291abffff     schools         50     30             0
#> 3: 89a9012a3cfffff     schools         50     15             0
#> 4: 89a9012a3cfffff     schools         50     30             0
#> 5: 89a901295b7ffff     schools         50     15             0
#> 6: 89a901295b7ffff     schools         50     30             0

# calculating access to different types of opportunities
access <- accessibility(
  r5r_network ,
  origins = points,
  destinations = points,
  opportunities_colnames = c("schools", "healthcare"),
  mode = "WALK",
  departure_datetime = departure_datetime,
  decay_function = "step",
  cutoffs = 30,
  max_trip_duration = 30
)
head(access)
#>                 id opportunity percentile cutoff accessibility
#>             <char>      <char>      <int>  <int>         <num>
#> 1: 89a901291abffff     schools         50     30             0
#> 2: 89a901291abffff  healthcare         50     30             0
#> 3: 89a9012a3cfffff     schools         50     30             0
#> 4: 89a9012a3cfffff  healthcare         50     30             0
#> 5: 89a901295b7ffff     schools         50     30             0
#> 6: 89a901295b7ffff  healthcare         50     30             1

stop_r5(r5r_network )
#> r5r_network has been successfully stopped.
```
