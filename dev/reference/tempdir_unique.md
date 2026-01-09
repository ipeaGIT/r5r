# Return a temporary directory path that is unique with every call

This is different from the built in tempdir() in that it does not return
the same directory within a given runtime. Always returns a unique
directory

## Usage

``` r
tempdir_unique()
```

## Value

Path. Returns the path of the created temporary directory

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/dev/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipeagit.github.io/r5r/dev/reference/fileurl_from_metadata.md),
[`start_r5r_java()`](https://ipeagit.github.io/r5r/dev/reference/start_r5r_java.md),
[`stop_r5()`](https://ipeagit.github.io/r5r/dev/reference/stop_r5.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/dev/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipeagit.github.io/r5r/dev/reference/validate_bad_osm_ids.md)
