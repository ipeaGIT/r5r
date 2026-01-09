# Stop running r5r network

Stops running r5r network

## Usage

``` r
stop_r5(...)
```

## Arguments

- ...:

  `r5r_network` objects currently running. By default, if no r5r network
  is supplied all running networks are stopped.

## Value

No return value, called for side effects.

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/dev/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipeagit.github.io/r5r/dev/reference/fileurl_from_metadata.md),
[`get_gtfs_errors()`](https://ipeagit.github.io/r5r/dev/reference/get_gtfs_errors.md),
[`start_r5r_java()`](https://ipeagit.github.io/r5r/dev/reference/start_r5r_java.md),
[`tempdir_unique()`](https://ipeagit.github.io/r5r/dev/reference/tempdir_unique.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/dev/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipeagit.github.io/r5r/dev/reference/validate_bad_osm_ids.md)

## Examples

``` r
library(r5r)

path <- system.file("extdata/poa", package = "r5r")

r5r_network <- build_network(path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
