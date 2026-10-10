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
  [`build_network()`](https://ipea.github.io/r5r/dev/reference/build_network.md).

- speed:

  A number representing the speed in km/h.

- mode:

  A string. Either `"bike"` or `"walk"`.

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
[`set_suboptimal_minutes()`](https://ipea.github.io/r5r/dev/reference/set_suboptimal_minutes.md),
[`set_time_window()`](https://ipea.github.io/r5r/dev/reference/set_time_window.md),
[`set_verbose()`](https://ipea.github.io/r5r/dev/reference/set_verbose.md)
