# Read a fare structure object from a file

Read a fare structure object from a file

## Usage

``` r
read_fare_structure(file_path, encoding = "UTF-8")
```

## Arguments

- file_path:

  A path pointing to a fare structure with a `.zip` extension.

- encoding:

  A string. Passed to
  [`data.table::fread()`](https://rdatatable.gitlab.io/data.table/reference/fread.html),
  defaults to `"UTF-8"`. Other possible options are `"unknown"` and
  `"Latin-1"`. Please note that this is not used to re-encode the input,
  but to enable handling encoded strings in their native encoding.

## Value

A fare structure object.

## See also

Other fare structure:
[`setup_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/setup_fare_structure.md),
[`write_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/write_fare_structure.md)

## Examples

``` r
path <- system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
fare_structure <- read_fare_structure(path)
```
