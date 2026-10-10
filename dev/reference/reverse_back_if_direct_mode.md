# Reverse BACK Origins and Destinations for Direct Modes

Swaps BACK the `origins` and `destinations` data frames if they were
originally reversed by
[`reverse_if_direct_mode()`](https://ipea.github.io/r5r/dev/reference/reverse_if_direct_mode.md).

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
[`reverse_if_direct_mode()`](https://ipea.github.io/r5r/dev/reference/reverse_if_direct_mode.md),
[`set_breakdown()`](https://ipea.github.io/r5r/dev/reference/set_breakdown.md),
[`set_cutoffs()`](https://ipea.github.io/r5r/dev/reference/set_cutoffs.md),
[`set_elevation()`](https://ipea.github.io/r5r/dev/reference/set_elevation.md),
[`set_expanded_travel_times()`](https://ipea.github.io/r5r/dev/reference/set_expanded_travel_times.md),
[`set_fare_cutoffs()`](https://ipea.github.io/r5r/dev/reference/set_fare_cutoffs.md),
[`set_fare_structure()`](https://ipea.github.io/r5r/dev/reference/set_fare_structure.md),
[`set_max_fare()`](https://ipea.github.io/r5r/dev/reference/set_max_fare.md),
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
