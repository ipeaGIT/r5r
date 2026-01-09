# Set monetary cutoffs

Sets the monetary cutoffs that should be considered when calculating the
Pareto frontier.

## Usage

``` r
set_fare_cutoffs(r5r_network, fare_cutoffs)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/dev/reference/build_network.md).

- fare_cutoffs:

  A path.

## Value

Invisibly returns `TRUE`.

## See also

Other setting functions:
[`reverse_back_if_direct_mode()`](https://ipeagit.github.io/r5r/dev/reference/reverse_back_if_direct_mode.md),
[`reverse_if_direct_mode()`](https://ipeagit.github.io/r5r/dev/reference/reverse_if_direct_mode.md),
[`set_breakdown()`](https://ipeagit.github.io/r5r/dev/reference/set_breakdown.md),
[`set_cutoffs()`](https://ipeagit.github.io/r5r/dev/reference/set_cutoffs.md),
[`set_elevation()`](https://ipeagit.github.io/r5r/dev/reference/set_elevation.md),
[`set_expanded_travel_times()`](https://ipeagit.github.io/r5r/dev/reference/set_expanded_travel_times.md),
[`set_fare_structure()`](https://ipeagit.github.io/r5r/dev/reference/set_fare_structure.md),
[`set_max_fare()`](https://ipeagit.github.io/r5r/dev/reference/set_max_fare.md),
[`set_max_lts()`](https://ipeagit.github.io/r5r/dev/reference/set_max_lts.md),
[`set_max_rides()`](https://ipeagit.github.io/r5r/dev/reference/set_max_rides.md),
[`set_monte_carlo_draws()`](https://ipeagit.github.io/r5r/dev/reference/set_monte_carlo_draws.md),
[`set_n_threads()`](https://ipeagit.github.io/r5r/dev/reference/set_n_threads.md),
[`set_new_congestion()`](https://ipeagit.github.io/r5r/dev/reference/set_new_congestion.md),
[`set_new_lts()`](https://ipeagit.github.io/r5r/dev/reference/set_new_lts.md),
[`set_output_dir()`](https://ipeagit.github.io/r5r/dev/reference/set_output_dir.md),
[`set_percentiles()`](https://ipeagit.github.io/r5r/dev/reference/set_percentiles.md),
[`set_progress()`](https://ipeagit.github.io/r5r/dev/reference/set_progress.md),
[`set_speed()`](https://ipeagit.github.io/r5r/dev/reference/set_speed.md),
[`set_suboptimal_minutes()`](https://ipeagit.github.io/r5r/dev/reference/set_suboptimal_minutes.md),
[`set_time_window()`](https://ipeagit.github.io/r5r/dev/reference/set_time_window.md),
[`set_verbose()`](https://ipeagit.github.io/r5r/dev/reference/set_verbose.md)
