# Validate OSM IDs returned from Java backend and print warnings

Parses a Java-style array string (e.g., `"[id1, id2]"`), extracts OSM
IDs, and prints a pretty warning if any invalid IDs are found.

## Usage

``` r
validate_bad_osm_ids(bad_ids_string)
```

## Arguments

- bad_ids_string:

  Character. A string formatted as a Java array (e.g., `"[id1, id2]"`).

## Value

Warning if necessary.

## Details

If no invalid IDs are found (i.e., input is `"[]"`), prints nothing.

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/dev/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipeagit.github.io/r5r/dev/reference/fileurl_from_metadata.md),
[`start_r5r_java()`](https://ipeagit.github.io/r5r/dev/reference/start_r5r_java.md),
[`stop_r5()`](https://ipeagit.github.io/r5r/dev/reference/stop_r5.md),
[`tempdir_unique()`](https://ipeagit.github.io/r5r/dev/reference/tempdir_unique.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/dev/reference/travel_time_surface.md)
