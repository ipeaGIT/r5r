# Set max fare

Sets the max fare allowed when calculating transit fares.

## Usage

``` r
set_max_fare(r5r_network, max_fare, fare_structure)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipea.github.io/r5r/dev/reference/build_network.md).

- max_fare:

  A number.

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipea.github.io/r5r/dev/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. See
  [`vignette("fare_structure", package = "r5r")`](https://ipea.github.io/r5r/dev/articles/fare_structure.md)
  for its structure.

## Value

Invisibly returns `TRUE`.

## See also

Other setting functions:
[`reverse_back_if_direct_mode()`](https://ipea.github.io/r5r/dev/reference/reverse_back_if_direct_mode.md),
[`reverse_if_direct_mode()`](https://ipea.github.io/r5r/dev/reference/reverse_if_direct_mode.md),
[`set_breakdown()`](https://ipea.github.io/r5r/dev/reference/set_breakdown.md),
[`set_cutoffs()`](https://ipea.github.io/r5r/dev/reference/set_cutoffs.md),
[`set_elevation()`](https://ipea.github.io/r5r/dev/reference/set_elevation.md),
[`set_expanded_travel_times()`](https://ipea.github.io/r5r/dev/reference/set_expanded_travel_times.md),
[`set_fare_cutoffs()`](https://ipea.github.io/r5r/dev/reference/set_fare_cutoffs.md),
[`set_fare_structure()`](https://ipea.github.io/r5r/dev/reference/set_fare_structure.md),
[`set_max_lts()`](https://ipea.github.io/r5r/dev/reference/set_max_lts.md),
[`set_max_rides()`](https://ipea.github.io/r5r/dev/reference/set_max_rides.md),
[`set_monte_carlo_draws()`](https://ipea.github.io/r5r/dev/reference/set_monte_carlo_draws.md),
[`set_n_threads()`](https://ipea.github.io/r5r/dev/reference/set_n_threads.md),
[`set_new_congestion()`](https://ipea.github.io/r5r/dev/reference/set_new_congestion.md),
[`set_new_lts()`](https://ipea.github.io/r5r/dev/reference/set_new_lts.md),
[`set_output_dir()`](https://ipea.github.io/r5r/dev/reference/set_output_dir.md),
[`set_percentiles()`](https://ipea.github.io/r5r/dev/reference/set_percentiles.md),
[`set_progress()`](https://ipea.github.io/r5r/dev/reference/set_progress.md),
[`set_speed()`](https://ipea.github.io/r5r/dev/reference/set_speed.md),
[`set_suboptimal_minutes()`](https://ipea.github.io/r5r/dev/reference/set_suboptimal_minutes.md),
[`set_time_window()`](https://ipea.github.io/r5r/dev/reference/set_time_window.md),
[`set_verbose()`](https://ipea.github.io/r5r/dev/reference/set_verbose.md)
