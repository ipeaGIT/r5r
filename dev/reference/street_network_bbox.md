# Extract the geographic bounding box of the transport network

Extracts the geographic bounding box of the street network layer from a
routable transport network built with
[`build_network()`](https://ipeagit.github.io/r5r/dev/reference/build_network.md)).
It is a fast and memory-efficient alternative to
`sf::st_bbox(street_network_to_sf(r5r_net))`.

## Usage

``` r
street_network_bbox(
  r5r_network,
  output = c("polygon", "bbox", "vector"),
  r5r_core = deprecated()
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/dev/reference/build_network.md).

- output:

  A character string specifying the desired output format. One of
  `"polygon"` (the default), `"bbox"`, or `"vector"`.

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Please use the
  `r5r_network` argument instead.

## Value

By default (`output = "polygon"`), an `sf` object with a single
`POLYGON` geometry. If `output = "bbox"`, an `sf` `bbox` object. If
`output = "vector"`, a named numeric vector with `xmin`, `ymin`, `xmax`,
`ymax` coordinates. All outputs use the WGS84 coordinate reference
system (EPSG: 4326).

## See also

Other network functions:
[`find_snap()`](https://ipeagit.github.io/r5r/dev/reference/find_snap.md),
[`street_network_to_sf()`](https://ipeagit.github.io/r5r/dev/reference/street_network_to_sf.md),
[`transit_network_to_sf()`](https://ipeagit.github.io/r5r/dev/reference/transit_network_to_sf.md)

## Examples

``` r
library(r5r)
library(sf)
#> Linking to GEOS 3.10.2, GDAL 3.4.1, PROJ 8.2.1; sf_use_s2() is TRUE

data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# Get the network's bounding box as an sf polygon (default)
poly <- street_network_bbox(r5r_network, output = "polygon")
plot(poly)


# Get an sf bbox object (order is xmin, ymin, xmax, ymax)
box <- street_network_bbox(r5r_network , output = "bbox")
box
#>      xmin      ymin      xmax      ymax 
#> -51.26635 -30.11333 -51.13216 -29.99047 

# Get a simple named vector (order now also xmin, ymin, xmax, ymax)
vec <- street_network_bbox(r5r_network , output = "vector")
vec
#>      xmin      ymin      xmax      ymax 
#> -51.26635 -30.11333 -51.13216 -29.99047 

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
