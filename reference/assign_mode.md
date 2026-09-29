# Check and select transport modes from user input

Selects the transport modes used in the routing functions. Only one
direct and access/egress modes are allowed at a time.

## Usage

``` r
assign_mode(mode, mode_egress, style)
```

## Arguments

- mode:

  A character vector, passed from routing functions.

- mode_egress:

  A character vector, passed from routing functions.

## Value

A list with the transport modes to be used in the routing.

## See also

Other assigning functions:
[`assign_decay_function()`](https://ipeagit.github.io/r5r/reference/assign_decay_function.md),
[`assign_departure()`](https://ipeagit.github.io/r5r/reference/assign_departure.md),
[`assign_drop_geometry()`](https://ipeagit.github.io/r5r/reference/assign_drop_geometry.md),
[`assign_max_street_time()`](https://ipeagit.github.io/r5r/reference/assign_max_street_time.md),
[`assign_max_trip_duration()`](https://ipeagit.github.io/r5r/reference/assign_max_trip_duration.md),
[`assign_opportunities()`](https://ipeagit.github.io/r5r/reference/assign_opportunities.md),
[`assign_osm_link_ids()`](https://ipeagit.github.io/r5r/reference/assign_osm_link_ids.md),
[`assign_points_input()`](https://ipeagit.github.io/r5r/reference/assign_points_input.md),
[`assign_shortest_path()`](https://ipeagit.github.io/r5r/reference/assign_shortest_path.md)
