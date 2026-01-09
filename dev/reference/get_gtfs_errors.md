# Get GTFS eventual errors encountered in network building

This returns a data frame of GTFS errors R5 encountered when building
the network. You can call this with the network itself as the main
parameter. If network build fails, you won't have a network object, so
you can also call this with the `data_path` to where the network is
stored.

## Usage

``` r
get_gtfs_errors(r5r_network)
```

## Arguments

- r5r_network:

  the R5R network object, or a path to the location where the network is
  stored (useful if network build failed).

## Value

A `data.frame`

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/dev/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipeagit.github.io/r5r/dev/reference/fileurl_from_metadata.md),
[`start_r5r_java()`](https://ipeagit.github.io/r5r/dev/reference/start_r5r_java.md),
[`stop_r5()`](https://ipeagit.github.io/r5r/dev/reference/stop_r5.md),
[`tempdir_unique()`](https://ipeagit.github.io/r5r/dev/reference/tempdir_unique.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/dev/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipeagit.github.io/r5r/dev/reference/validate_bad_osm_ids.md)

## Examples

``` r
library(r5r)

# directory with street network and gtfs files
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

get_gtfs_errors(r5r_network)
#> Empty data.table (0 rows and 7 cols): V1,file,line,type,field,id...
```
