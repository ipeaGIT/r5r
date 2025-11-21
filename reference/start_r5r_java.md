# Initialize Java and Check Version

Sets up Java logging for r5r and ensures Java SE Development Kit 21 is
installed.

## Usage

``` r
start_r5r_java(data_path, temp_dir = FALSE, verbose = FALSE)
```

## Arguments

- data_path:

  A character string. The directory where the log file should be saved.

- temp_dir:

  A logical. Whether the jar file should be saved in a temporary
  directory. Defaults to `FALSE`.

- verbose:

  A logical. Whether to show informative messages. Defaults to `FALSE`.

## Value

No return value. The function will stop execution with an error if Java
21 is not found.

## Details

This function initializes the Java Virtual Machine (JVM) with a log path
for r5r, and checks that the installed Java version is 21. If not, it
stops with an informative error message and download links.

## See also

Other support functions:
[`exists_tiff()`](https://ipeagit.github.io/r5r/reference/exists_tiff.md),
[`fileurl_from_metadata()`](https://ipeagit.github.io/r5r/reference/fileurl_from_metadata.md),
[`stop_r5()`](https://ipeagit.github.io/r5r/reference/stop_r5.md),
[`tempdir_unique()`](https://ipeagit.github.io/r5r/reference/tempdir_unique.md),
[`travel_time_surface`](https://ipeagit.github.io/r5r/reference/travel_time_surface.md),
[`validate_bad_osm_ids()`](https://ipeagit.github.io/r5r/reference/validate_bad_osm_ids.md)
