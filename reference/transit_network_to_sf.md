# Extract transit network in sf format

Extracts the transit network in `sf` format from a routable transport
network built with
[`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md)).

## Usage

``` r
transit_network_to_sf(r5r_network, r5r_core = deprecated())
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

## Value

A list with two components of a transit network in `sf` format: route
shapes (`LINESTRING`) and transit stops (`POINT`). The same
`route_id`/`short_name` might appear with different geometries. This
occurs when the same route is associated to more than one `shape_id`s in
the GTFS feed used to create the transit network. Some transit stops
might be returned with geometry `POINT EMPTY` (i.e. missing spatial
coordinates). This may occur when a transit stop is not snapped to the
road network, possibly because the GTFS feed used to create the transit
network covers an area larger than the `.osm.pbf` input data.

## See also

Other network functions:
[`find_snap()`](https://ipeagit.github.io/r5r/reference/find_snap.md),
[`street_network_bbox()`](https://ipeagit.github.io/r5r/reference/street_network_bbox.md),
[`street_network_to_sf()`](https://ipeagit.github.io/r5r/reference/street_network_to_sf.md)

## Examples

``` r
library(r5r)

# build transport network
path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# extract transit network from r5r_network
transit_net <- transit_network_to_sf(r5r_network)

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
