# Assign max street time from walk/bike distance and speed

Checks the time duration and speed inputs and converts them to distance.

## Usage

``` r
assign_max_street_time(max_time, speed, max_trip_duration, mode)
```

## Arguments

- max_time:

  A numeric of length 1. Maximum walking distance (in meters) for the
  whole trip. Passed from routing functions.

- speed:

  A numeric of length 1. Average walk speed in km/h. Defaults to 3.6
  Km/h. Passed from routing functions.

- max_trip_duration:

  A numeric of length 1. Maximum trip duration in seconds. Defaults to
  120 minutes (2 hours). Passed from routing functions.

- mode:

  A string. Either `"bike"` or `"walk"`.

## Value

An `integer` representing the maximum number of minutes walking.

## See also

Other assigning functions:
[`assign_decay_function()`](https://ipeagit.github.io/r5r/dev/reference/assign_decay_function.md),
[`assign_departure()`](https://ipeagit.github.io/r5r/dev/reference/assign_departure.md),
[`assign_drop_geometry()`](https://ipeagit.github.io/r5r/dev/reference/assign_drop_geometry.md),
[`assign_max_trip_duration()`](https://ipeagit.github.io/r5r/dev/reference/assign_max_trip_duration.md),
[`assign_mode()`](https://ipeagit.github.io/r5r/dev/reference/assign_mode.md),
[`assign_opportunities()`](https://ipeagit.github.io/r5r/dev/reference/assign_opportunities.md),
[`assign_osm_link_ids()`](https://ipeagit.github.io/r5r/dev/reference/assign_osm_link_ids.md),
[`assign_points_input()`](https://ipeagit.github.io/r5r/dev/reference/assign_points_input.md),
[`assign_shortest_path()`](https://ipeagit.github.io/r5r/dev/reference/assign_shortest_path.md)
