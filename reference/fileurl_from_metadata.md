# Get most recent JAR file url from metadata

Returns the most recent JAR file url from metadata, depending on the
version.

## Usage

``` r
fileurl_from_metadata(version = NULL)
```

## Arguments

- version:

  A string. The version of R5 to be downloaded. When `NULL`, it defaults
  to the latest version.

## Value

A url a string.

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/reference/exists_tiff.md),
[`start_r5r_java()`](https://ipeagit.github.io/r5r/reference/start_r5r_java.md),
[`stop_r5()`](https://ipeagit.github.io/r5r/reference/stop_r5.md),
[`tempdir_unique()`](https://ipeagit.github.io/r5r/reference/tempdir_unique.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipeagit.github.io/r5r/reference/validate_bad_osm_ids.md)
