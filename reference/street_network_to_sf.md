# Extract OpenStreetMap network in sf format

Extracts the OpenStreetMap network in `sf` format from a routable
transport network built with
[`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md)).

## Usage

``` r
street_network_to_sf(r5r_network, r5r_core = deprecated())
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

## Value

A list with two components of a street network in sf format: vertices
(POINT) and edges (LINESTRING).

## See also

Other network functions:
[`find_snap()`](https://ipeagit.github.io/r5r/reference/find_snap.md),
[`street_network_bbox()`](https://ipeagit.github.io/r5r/reference/street_network_bbox.md),
[`transit_network_to_sf()`](https://ipeagit.github.io/r5r/reference/transit_network_to_sf.md)

## Examples

``` r
library(r5r)

# build transport network
path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# extract street network from r5r_network
street_net <- street_network_to_sf(r5r_network)

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
