# Setup a fare structure to calculate the monetary costs of trips

Creates a basic fare structure that describes how transit fares should
be calculated in
[`travel_time_matrix()`](https://ipea.github.io/r5r/dev/reference/travel_time_matrix.md),
[`expanded_travel_time_matrix()`](https://ipea.github.io/r5r/dev/reference/expanded_travel_time_matrix.md),
[`accessibility()`](https://ipea.github.io/r5r/dev/reference/accessibility.md)
and
[`pareto_frontier()`](https://ipea.github.io/r5r/dev/reference/pareto_frontier.md).
This fare structure can be manually edited and adjusted to the existing
rules in your study area, as long as they stick to some basic premises.
See the [fare-structure
vignette](https://ipea.github.io/r5r/dev/doc/fare_structure.md).

## Usage

``` r
setup_fare_structure(
  r5r_network,
  base_fare,
  by = "MODE",
  debug_path = NULL,
  debug_info = NULL,
  r5r_core = deprecated()
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipea.github.io/r5r/dev/reference/build_network.md).

- base_fare:

  A numeric. A base value used to populate the fare structure.

- by:

  A string. Describes how `fare_type`s (a classification we created to
  assign fares to different routes) are distributed among routes.
  Possible values are `MODE`, `AGENCY` and `GENERIC`. `MODE` is used
  when the mode is what determines the price of a route (e.g. if all the
  buses of a given city cost \$5). `AGENCY` is used when the agency that
  operates each route is what determines its price (i.e. when two
  different routes/modes operated by a single agency cost the same; note
  that you can also use `AGENCY_NAME`, if the agency_ids listed in your
  GTFS cannot be easily interpreted). `GENERIC` is used when all the
  routes cost the same. This classification can later be edited to
  better suit your needs (when, for example, two types of buses cost the
  same, but one offers discounts after riding the subway and the other
  one doesn't), but this parameter may save you some work.

- debug_path:

  Either a path to a `.csv` file or `NULL`. When `NULL` (the default),
  fare debugging capabilities are disabled - i.e. there's no way to
  check if the fare calculation is correct. When a path is provided,
  `r5r` saves different itineraries and their respective fares to the
  specified file. How each itinerary is described is controlled by
  `debug_info`.

- debug_info:

  Either a string (when `debug_path` is a path) or `NULL` (the default).
  Ignored if `debug_path` is `NULL`. One of `MODE`, `ROUTE` or
  `MODE_ROUTE`, setting how each itinerary is written. E.g. a subway leg
  on route 001 followed by a bus leg on route 007 is written as
  `SUBWAY|BUS`, `001|007` or `SUBWAY 001|BUS 007`, respectively. The
  debug output lists all itineraries `R5` checked when calculating
  routes, not only those returned by
  [`travel_time_matrix()`](https://ipea.github.io/r5r/dev/reference/travel_time_matrix.md),
  [`accessibility()`](https://ipea.github.io/r5r/dev/reference/accessibility.md)
  and
  [`pareto_frontier()`](https://ipea.github.io/r5r/dev/reference/pareto_frontier.md).
  This slows computation, but the larger sample of itineraries helps
  find issues in the fare structure.

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Use the
  `r5r_network` argument instead.

## Value

A fare structure object.

## See also

Other fare structure:
[`read_fare_structure()`](https://ipea.github.io/r5r/dev/reference/read_fare_structure.md),
[`write_fare_structure()`](https://ipea.github.io/r5r/dev/reference/write_fare_structure.md)

## Examples

``` r
library(r5r)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> Using cached R5 version from /home/runner/.cache/R/r5r/r5_jar_v7.5.1/r5-v7.5-1-gf3631e9-all.jar
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

fare_structure <- setup_fare_structure(r5r_network, base_fare = 5)

# to debug fare calculation
fare_structure <- setup_fare_structure(
  r5r_network,
  base_fare = 5,
  debug_path = "fare_debug.csv",
  debug_info = "MODE"
)

fare_structure$debug_settings
#> $output_file
#> [1] "fare_debug.csv"
#> 
#> $trip_info
#> [1] "MODE"
#> 

# debugging can be manually turned off by setting output_file to ""
fare_structure$debug_settings <- ""
```
