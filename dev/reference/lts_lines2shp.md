# Save LTS lines to shapefile temporary file

Support function that checks the input of LTS lines passed to and saves
it to a `.shp` temporary file.

## Usage

``` r
lts_lines2shp(new_lts_lines)
```

## Arguments

- new_lts_lines:

  An sf LINESTRING or MULTILINESTRING

## Value

The path to a `.shp` saved as a temporary file.

## See also

Other Support functions:
[`congestion_poly2geojson()`](https://ipeagit.github.io/r5r/dev/reference/congestion_poly2geojson.md)

## Examples

``` r
# read lines with new speeds
new_lts_lines <- readRDS(
  system.file("extdata/poa/poa_ls_lts.rds", package = "r5r")
  )

shp_path <- r5r:::lts_lines2shp(
  new_lts_lines = new_lts_lines
  )
```
