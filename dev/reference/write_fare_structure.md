# Write a fare structure object to disk

Writes a fare structure object do disk. Fare structure is saved as a
collection of `.csv` files inside a `.zip` file.

## Usage

``` r
write_fare_structure(fare_structure, file_path)
```

## Arguments

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. Please
  see the fare structure vignette to understand how this object is
  structured:
  [`vignette("fare_structure", package = "r5r")`](https://ipeagit.github.io/r5r/dev/articles/fare_structure.md).

- file_path:

  A path to a `.zip` file. Where the fare structure should be written
  to.

## Value

The path passed to `file_path`, invisibly.

## See also

Other fare structure:
[`read_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/read_fare_structure.md),
[`setup_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/setup_fare_structure.md)

## Examples

``` r
library(r5r)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

fare_structure <- setup_fare_structure(r5r_network, base_fare = 5)

tmpfile <- tempfile("sample_fare_structure", fileext = ".zip")
write_fare_structure(fare_structure, tmpfile)
```
