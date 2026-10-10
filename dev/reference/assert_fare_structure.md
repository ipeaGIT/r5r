# Assert fare structure

Asserts whether the specified fare structure object complies with the
structure set in
[`setup_fare_structure()`](https://ipea.github.io/r5r/dev/reference/setup_fare_structure.md).

## Usage

``` r
assert_fare_structure(fare_structure)
```

## Arguments

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipea.github.io/r5r/dev/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. See
  [`vignette("fare_structure", package = "r5r")`](https://ipea.github.io/r5r/dev/articles/fare_structure.md)
  for its structure.

## Value

Throws and error upon failure and invisibly returns `TRUE` on success.
