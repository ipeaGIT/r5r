# Get GTFS errors encountered in network building

Returns a data frame of the GTFS errors R5 encountered when building the
network. If the build failed and there is no network object, pass the
path where the network is stored as `r5r_network` instead.

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
[`exists_tiff()`](https://ipea.github.io/r5r/dev/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipea.github.io/r5r/dev/reference/fileurl_from_metadata.md),
[`start_r5r_java()`](https://ipea.github.io/r5r/dev/reference/start_r5r_java.md),
[`stop_r5()`](https://ipea.github.io/r5r/dev/reference/stop_r5.md),
[`tempdir_unique()`](https://ipea.github.io/r5r/dev/reference/tempdir_unique.md),
[`travel_time_surface()`](https://ipea.github.io/r5r/dev/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipea.github.io/r5r/dev/reference/validate_bad_osm_ids.md)

## Examples

``` r
library(r5r)

# directory with street network and gtfs files
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> Using cached R5 version from /home/runner/.cache/R/r5r/r5_jar_v7.5.1/r5-v7.5-1-gf3631e9-all.jar
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

get_gtfs_errors(r5r_network)
#> Empty data.table (0 rows and 6 cols): file,line,type,field,id,priority
```
