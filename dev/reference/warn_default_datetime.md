# Warn about the deprecated `Sys.time()` default of the departure/arrival time

Relying on the default
[`Sys.time()`](https://rdrr.io/r/base/Sys.time.html) with public
transport gives results that depend on when the code is run (#549). The
default will be removed in a future release.

## Usage

``` r
warn_default_datetime(mode, arg = "departure_datetime")
```

## Arguments

- mode:

  The `mode` passed to the routing function.

- arg:

  The name of the date-time argument.

## Value

Invisibly returns `NULL`.
