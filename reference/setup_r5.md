# Create a transport network used for routing in R5 (deprecated)

**\[deprecated\]**

`setup_r5()` was renamed to
[`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md)
to create a more consistent API. **`setup_r5()` is being deprecated**
after *r5r* v2.3.0 and will be **removed in a future release**. Please
switch to
[`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

## Usage

``` r
setup_r5(
  data_path,
  verbose = FALSE,
  temp_dir = FALSE,
  elevation = "TOBLER",
  overwrite = FALSE
)
```

## Arguments

- data_path:

  A string pointing to the directory where data inputs are stored and
  where the built `network.dat` will be saved.

- verbose:

  A logical. Whether to show `R5` informative messages when running the
  function. Defaults to `FALSE` (please note that in such case `R5`
  error messages are still shown). Setting `verbose` to `TRUE` shows
  detailed output, which can be useful for debugging issues not caught
  by `r5r`.

- temp_dir:

  A logical. Whether the `network.dat` file should be saved to a
  temporary directory. Defaults to `FALSE`.

- elevation:

  A string. The name of the impedance function to be used to calculate
  impedance for walking and cycling based on street slopes. Available
  options include `TOBLER` (Default) and `MINETTI`, or `NONE` to ignore
  elevation. R5 loads elevation data from `.tif` files saved inside the
  `data_path` directory. Elevation raster must be in WGS 84 (EPSG:4326)
  coordinate reference system. See more info in the Details section
  below.

- overwrite:

  A logical. Whether to overwrite an existing `network.dat` or to use a
  cached file. Defaults to `FALSE` (i.e. use a cached network).

## Value

A `r5r_network` object representing the built network to connect with
`R5` routing engine.

## Elevation

More information about the `TOBLER` and `MINETTI` options to calculate
the effects of elevation on travel times can be found in the references
below:

- Campbell, M. J., et al (2019). Using crowdsourced fitness tracker data
  to model the relationship between slope and travel rates. Applied
  geography, 106, 93-107.
  [doi:10.1016/j.apgeog.2019.03.008](https://doi.org/10.1016/j.apgeog.2019.03.008)
  .

- Minetti, A. E., et al (2002). Energy cost of walking and running at
  extreme uphill and downhill slopes. Journal of applied physiology.
  [doi:10.1152/japplphysiol.01177.2001](https://doi.org/10.1152/japplphysiol.01177.2001)
  .

- Tobler, W. (1993). Three presentations on geographical analysis and
  modeling: Non-isotropic geographic modeling speculations on the
  geometry of geography global spatial analysis. Technical Report.
  National center for geographic information and analysis. 93 (1).
  <https://escholarship.org/uc/item/05r820mz>.

## See also

Other Build network:
[`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md),
[`download_r5()`](https://ipeagit.github.io/r5r/reference/download_r5.md)

## Examples

``` r
library(r5r)

# directory with street network and gtfs files
data_path <- system.file("extdata/poa", package = "r5r")

# `setup_r5()` has been deprecated, please switch to `build_network()`
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.
```
