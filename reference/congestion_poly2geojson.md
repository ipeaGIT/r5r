# Save speeds polygon to .geojson temporary file

Support function that checks the input of speeds polygon passed to
`build_custom_network()` and saves it to a `.geojson` temporary file.

## Usage

``` r
congestion_poly2geojson(new_speeds_poly)
```

## Arguments

- new_speeds_poly:

  An sf polygon

## Value

The path to a `.geojson` saved as a temporary file.

## See also

Other Support functions:
[`lts_lines2shp()`](https://ipeagit.github.io/r5r/reference/lts_lines2shp.md)

## Examples

``` r
# read polygons with new speeds
congestion_poly <- readRDS(
  system.file("extdata/poa/poa_poly_congestion.rds", package = "r5r")
  )

geojson_path <- r5r:::congestion_poly2geojson(
  new_speeds_poly = congestion_poly
  )
```
