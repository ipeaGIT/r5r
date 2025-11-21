# Set walk and bike speed

This function receives the walk and bike 'speed' inputs in Km/h from
routing functions above and converts them to meters per second, which is
then used to set these speed profiles in r5r JAR.

## Usage

``` r
set_speed(r5r_network, speed, mode)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- speed:

  A number representing the speed in km/h.

- mode:

  A string. Either `"bike"` or `"walk"`.

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
[`set_suboptimal_minutes()`](https://ipeagit.github.io/r5r/reference/set_suboptimal_minutes.md),
[`set_time_window()`](https://ipeagit.github.io/r5r/reference/set_time_window.md),
[`set_verbose()`](https://ipeagit.github.io/r5r/reference/set_verbose.md)
