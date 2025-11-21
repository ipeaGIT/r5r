# Find snapped locations of input points on street network

Finds the snapped location of points on `R5` network. Snapping is an
important step of the routing process, which is when the origins and
destinations specified by the user are actually positioned on the
network created by `R5`. The snapping process in `R5` is composed of two
rounds. First, it tries to snap the points within a radius of 300 meters
from themselves. If the first round is unsuccessful, then `R5` expands
the search to the radius specified (by default 1.6km). If yet again it
is unsuccessful, then the unsnapped points won't be used during the
routing process. The snapped location of each point depends on the
transport mode set by the user, because some network edges are not
available to specific modes (e.g. a pedestrian-only street cannot be
used to snap car trips).

## Usage

``` r
find_snap(
  r5r_network,
  r5r_core = deprecated(),
  points,
  radius = 1600,
  mode = "WALK"
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

- points:

  Either a `POINT sf` object with WGS84 CRS, or a `data.frame`
  containing the columns `id`, `lon` and `lat`.

- radius:

  Numeric. The maximum radius in meters within which to snap. Defaults
  to 1600m.

- mode:

  A string. Which mode to consider when trying to snap the points to the
  network. Defaults to `WALK`, also allows `BICYCLE` and `CAR`.

## Value

A `data.table` with the original points, their respective snapped
coordinates on the street network and the Euclidean distance (in meters)
between the original points and their snapped location. Points that
could not be snapped show `NA` coordinates and `found = FALSE`.

## See also

Other network functions:
[`street_network_bbox()`](https://ipeagit.github.io/r5r/reference/street_network_bbox.md),
[`street_network_to_sf()`](https://ipeagit.github.io/r5r/reference/street_network_to_sf.md),
[`transit_network_to_sf()`](https://ipeagit.github.io/r5r/reference/transit_network_to_sf.md)

## Examples

``` r
library(r5r)

path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path = path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.
points <- read.csv(file.path(path, "poa_hexgrid.csv"))

snap_df <- find_snap(
  r5r_network,
  points = points,
  radius = 2000,
  mode = "WALK"
  )

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
