# Estimate isochrones from a given location

Fast computation of isochrones from a given location. The function can
return either polygon-based or line-based isochrones. Polygon-based
isochrones are generated as concave polygons based on the travel times
from the trip origin to all nodes in the transport network. Meanwhile,
line-based isochronesare based on travel times from each origin to the
centroids of all segments in the transport network.

## Usage

``` r
isochrone(
  r5r_network,
  r5r_core = deprecated(),
  origins,
  mode = "transit",
  mode_egress = "walk",
  cutoffs = c(0, 15, 30),
  zoom = 10,
  departure_datetime = Sys.time(),
  polygon_output = TRUE,
  time_window = 10L,
  max_walk_time = Inf,
  max_bike_time = Inf,
  max_car_time = Inf,
  max_trip_duration = 120L,
  walk_speed = 3.6,
  bike_speed = 12,
  max_rides = 3,
  max_lts = 2,
  draws_per_minute = 5L,
  percentiles = NULL,
  n_threads = Inf,
  verbose = FALSE,
  progress = TRUE,
  sample_size = deprecated()
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

- origins:

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

- cutoffs:

  numeric vector. Number of minutes to define the time span of each
  Isochrone. Defaults to `c(0, 15, 30)`.

- zoom:

  Resolution of the travel time surface used to create isochrones, can
  be between `9` and `12.` The default is `10` (which uses cells of 153
  meters at the Equator). More detailed isochrones will result from
  larger numbers, at the expense of compute time. Specifically, a raster
  grid of travel times in the Web Mercator projection at this zoom level
  is created, and the isochrones are interpolated from this grid. For
  more information on how the grid cells are defined, see [the R5
  documentation.](https://docs.conveyal.com/analysis/methodology#zoom-levels)

- departure_datetime:

  A POSIXct object. Please note that the departure time only influences
  public transport legs. When working with public transport networks,
  please check the `calendar.txt` within your GTFS feeds for valid
  dates. Please see details for further information on how datetimes are
  parsed.

- polygon_output:

  A Logical. If `TRUE`, the function outputs polygon-based isochrones
  (the default) based on travel times from each origin to a sample of a
  random sample nodes in the transport network (see parameter
  `sample_size`). If `FALSE`, the function outputs line-based isochrones
  based on travel times from each origin to the centroids of all
  segments in the transport network.

- time_window:

  An integer. The time window in minutes for which `r5r` will calculate
  multiple travel time matrices departing each minute. Defaults to 10
  minutes. The function returns the result based on median travel times.
  Please read the time window vignette for more details on its usage
  [`vignette("time_window", package = "r5r")`](https://ipeagit.github.io/r5r/articles/time_window.md)

- max_walk_time:

  An integer. The maximum walking time (in minutes) to access and egress
  the transit network, or to make transfers within the network. Defaults
  to no restrictions, as long as `max_trip_duration` is respected. The
  max time is considered separately for each leg (e.g. if you set
  `max_walk_time` to 15, you could potentially walk up to 15 minutes to
  reach transit, and up to *another* 15 minutes to reach the destination
  after leaving transit). Defaults to `Inf`, no limit.

- max_bike_time:

  An integer. The maximum cycling time (in minutes) to access and egress
  the transit network. Defaults to no restrictions, as long as
  `max_trip_duration` is respected. The max time is considered
  separately for each leg (e.g. if you set `max_bike_time` to 15
  minutes, you could potentially cycle up to 15 minutes to reach
  transit, and up to *another* 15 minutes to reach the destination after
  leaving transit). Defaults to `Inf`, no limit.

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

- draws_per_minute:

  An integer. The number of Monte Carlo draws to perform per time window
  minute when calculating travel time matrices and when estimating
  accessibility. Defaults to 5. This would mean 300 draws in a 60-minute
  time window, for example. This parameter only affects the results when
  the GTFS feeds contain a `frequencies.txt` table. If the GTFS feed
  does not have a frequency table, r5r still allows for multiple runs
  over the set `time_window` but in a deterministic way.

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

- n_threads:

  An integer. The number of threads to use when running the router in
  parallel. Defaults to use all available threads (`Inf`).

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

- sample_size:

  deprecated, no longer has any effect.

## Value

A `"sf" "data.frame"` for each isochrone of each origin.

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
and
[`accessibility()`](https://ipeagit.github.io/r5r/reference/accessibility.md)
functions use an `R5`-specific extension to the RAPTOR routing algorithm
(see Conway et al., 2017). This RAPTOR extension uses a systematic
sample of one departure per minute over the time window set by the user
in the 'time_window' parameter. A detailed description of base RAPTOR
can be found in Delling et al (2015). However, whenever the user
includes transit fares inputs to these functions, they automatically
switch to use an `R5`-specific extension to the McRAPTOR routing
algorithm.

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
options(java.parameters = "-Xmx2G")
library(r5r)
library(ggplot2)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path = data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# load origin/point of interest
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
origin <- points[2,]

departure_datetime <- as.POSIXct(
 "13-05-2019 14:00:00",
 format = "%d-%m-%Y %H:%M:%S"
)

# estimate polygon-based isochrone from origin
iso_poly <- isochrone(
  r5r_network,
  origins = origin,
  mode = "walk",
  polygon_output = TRUE,
  departure_datetime = departure_datetime,
  cutoffs = seq(0, 120, 30)
  )

head(iso_poly)
#> Simple feature collection with 4 features and 3 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -51.25671 ymin: -30.08098 xmax: -51.15646 ymax: -29.98943
#> Geodetic CRS:  WGS 84
#>                    id isochrone percentile                       polygons
#> 1 bus_central_station       120        p50 POLYGON ((-51.21277 -30.080...
#> 2 bus_central_station        90        p50 POLYGON ((-51.21071 -30.065...
#> 3 bus_central_station        60        p50 POLYGON ((-51.21414 -30.051...
#> 4 bus_central_station        30        p50 POLYGON ((-51.21552 -30.037...


# estimate line-based isochrone from origin
iso_lines <- isochrone(
  r5r_network,
  origins = origin,
  mode = "walk",
  polygon_output = FALSE,
  departure_datetime = departure_datetime,
  cutoffs = seq(0, 100, 25)
  )
#> Warning: st_centroid assumes attributes are constant over geometries

head(iso_lines)
#> Simple feature collection with 6 features and 13 fields
#> Geometry type: LINESTRING
#> Dimension:     XY
#> Bounding box:  xmin: -51.17223 ymin: -30.03979 xmax: -51.16588 ymax: -30.02889
#> Geodetic CRS:  WGS 84
#>   edge_index   osm_id isochrone travel_time_p50 from_vertex to_vertex
#> 1        594 27234386       100             100         414       415
#> 2        595 27234386       100             100         415       414
#> 3        598 27234513       100             100         417       411
#> 4        599 27234513       100             100         411       417
#> 5       2072 28069055       100             100        1397      1398
#> 6       2073 28069055       100             100        1398      1397
#>   street_class  length walk   car car_speed bicycle bicycle_lts
#> 1     TERTIARY 276.717 TRUE  TRUE    39.996    TRUE           2
#> 2     TERTIARY 276.717 TRUE  TRUE    39.996    TRUE           2
#> 3        OTHER 162.110 TRUE  TRUE    29.988    TRUE           2
#> 4        OTHER 162.110 TRUE  TRUE    29.988    TRUE           2
#> 5        OTHER 224.482 TRUE  TRUE    40.248    TRUE           4
#> 6        OTHER 224.482 TRUE FALSE    40.248   FALSE           4
#>                         geometry
#> 1 LINESTRING (-51.16588 -30.0...
#> 2 LINESTRING (-51.16876 -30.0...
#> 3 LINESTRING (-51.1687 -30.03...
#> 4 LINESTRING (-51.17039 -30.0...
#> 5 LINESTRING (-51.17223 -30.0...
#> 6 LINESTRING (-51.17027 -30.0...


# plot colors
colors <- c('#ffe0a5','#ffcb69','#ffa600','#ff7c43','#f95d6a',
            '#d45087','#a05195','#665191','#2f4b7c','#003f5c')

# polygons
ggplot() +
  geom_sf(data=iso_poly, aes(fill=factor(isochrone))) +
  scale_fill_manual(values = colors) +
  theme_minimal()


# lines
ggplot() +
  geom_sf(data=iso_lines, aes(color=factor(isochrone))) +
  scale_color_manual(values = colors) +
  theme_minimal()


stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
