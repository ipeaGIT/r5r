# Set the fare structure used when calculating transit fares

Sets the fare structure used by our "generic" fare calculator. A value
of `NULL` is passed to `fare_structure` by the upstream routing and
accessibility functions when fares are not to be calculated.

## Usage

``` r
set_fare_structure(r5r_network, fare_structure)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipeagit.github.io/r5r/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. Please
  see the fare structure vignette to understand how this object is
  structured:
  [`vignette("fare_structure", package = "r5r")`](https://ipeagit.github.io/r5r/articles/fare_structure.md).

## Value

Invisibly returns `TRUE`.

## See also

Other setting functions:
[`reverse_back_if_direct_mode()`](https://ipeagit.github.io/r5r/reference/reverse_back_if_direct_mode.md),
[`reverse_if_direct_mode()`](https://ipeagit.github.io/r5r/reference/reverse_if_direct_mode.md),
[`set_breakdown()`](https://ipeagit.github.io/r5r/reference/set_breakdown.md),
[`set_cutoffs()`](https://ipeagit.github.io/r5r/reference/set_cutoffs.md),
[`set_elevation()`](https://ipeagit.github.io/r5r/reference/set_elevation.md),
[`set_expanded_travel_times()`](https://ipeagit.github.io/r5r/reference/set_expanded_travel_times.md),
[`set_fare_cutoffs()`](https://ipeagit.github.io/r5r/reference/set_fare_cutoffs.md),
[`set_max_fare()`](https://ipeagit.github.io/r5r/reference/set_max_fare.md),
[`set_max_lts()`](https://ipeagit.github.io/r5r/reference/set_max_lts.md),
[`set_max_rides()`](https://ipeagit.github.io/r5r/reference/set_max_rides.md),
[`set_monte_carlo_draws()`](https://ipeagit.github.io/r5r/reference/set_monte_carlo_draws.md),
[`set_n_threads()`](https://ipeagit.github.io/r5r/reference/set_n_threads.md),
[`set_new_congestion()`](https://ipeagit.github.io/r5r/reference/set_new_congestion.md),
[`set_new_lts()`](https://ipeagit.github.io/r5r/reference/set_new_lts.md),
[`set_output_dir()`](https://ipeagit.github.io/r5r/reference/set_output_dir.md),
[`set_percentiles()`](https://ipeagit.github.io/r5r/reference/set_percentiles.md),
[`set_progress()`](https://ipeagit.github.io/r5r/reference/set_progress.md),
[`set_speed()`](https://ipeagit.github.io/r5r/reference/set_speed.md),
[`set_suboptimal_minutes()`](https://ipeagit.github.io/r5r/reference/set_suboptimal_minutes.md),
[`set_time_window()`](https://ipeagit.github.io/r5r/reference/set_time_window.md),
[`set_verbose()`](https://ipeagit.github.io/r5r/reference/set_verbose.md)
