# Set suboptimal minutes

Sets the number of suboptimal minutes considered in
[`detailed_itineraries()`](https://ipeagit.github.io/r5r/reference/detailed_itineraries.md)
routing. From R5 documentation: "This parameter compensates for the fact
that GTFS does not contain information about schedule deviation
(lateness). The min-max travel time range for some trains is zero, since
the trips are reported to always have the same timings in the schedule.
Such an option does not overlap (temporally) its alternatives, and is
too easily eliminated by an alternative that is only marginally better.
We want to effectively push the max travel time of alternatives out a
bit to account for the fact that they don't always run on schedule".

## Usage

``` r
set_suboptimal_minutes(
  r5r_network,
  suboptimal_minutes,
  fare_structure,
  shortest_path
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md).

- suboptimal_minutes:

  A number.

- fare_structure:

  A fare structure object, following the convention set in
  [`setup_fare_structure()`](https://ipeagit.github.io/r5r/reference/setup_fare_structure.md).
  This object describes how transit fares should be calculated. Please
  see the fare structure vignette to understand how this object is
  structured:
  [`vignette("fare_structure", package = "r5r")`](https://ipeagit.github.io/r5r/articles/fare_structure.md).

- shortest_path:

  A logical.

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
[`set_speed()`](https://ipeagit.github.io/r5r/reference/set_speed.md),
[`set_time_window()`](https://ipeagit.github.io/r5r/reference/set_time_window.md),
[`set_verbose()`](https://ipeagit.github.io/r5r/reference/set_verbose.md)
