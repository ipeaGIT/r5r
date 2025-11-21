# Reverse BACK Origins and Destinations for Direct Modes

Swaps BACK the `origins` and `destinations` data frames if they were
originally reversed by
[`reverse_if_direct_mode()`](https://ipeagit.github.io/r5r/reference/reverse_if_direct_mode.md).

## Usage

``` r
reverse_back_if_direct_mode(
  travel_times,
  origins,
  destinations,
  mode_list,
  data_path
)
```

## Arguments

- travel_times:

  A travel time matrix.

- origins:

  A data frame representing origin locations.

- destinations:

  A data frame representing destination locations.

- mode_list:

  A named list containing the routing modes.

- data_path:

  The data path used to build the network

## Value

A df travel time matrix with origins and destinations unchanged or in
swapped order

## See also

Other setting functions:
[`reverse_if_direct_mode()`](https://ipeagit.github.io/r5r/reference/reverse_if_direct_mode.md),
[`set_breakdown()`](https://ipeagit.github.io/r5r/reference/set_breakdown.md),
[`set_cutoffs()`](https://ipeagit.github.io/r5r/reference/set_cutoffs.md),
[`set_elevation()`](https://ipeagit.github.io/r5r/reference/set_elevation.md),
[`set_expanded_travel_times()`](https://ipeagit.github.io/r5r/reference/set_expanded_travel_times.md),
[`set_fare_cutoffs()`](https://ipeagit.github.io/r5r/reference/set_fare_cutoffs.md),
[`set_fare_structure()`](https://ipeagit.github.io/r5r/reference/set_fare_structure.md),
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
