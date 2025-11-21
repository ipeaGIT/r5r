# Check and convert origin and destination inputs

Check and convert origin and destination inputs

## Usage

``` r
assign_points_input(df, name)
```

## Arguments

- df:

  Either a `data.frame` or a `POINT sf`.

- name:

  Object name.

## Value

A `data.frame` with columns `id`, `lon` and `lat`.

## See also

Other assigning functions:
[`assign_decay_function()`](https://ipeagit.github.io/r5r/reference/assign_decay_function.md),
[`assign_departure()`](https://ipeagit.github.io/r5r/reference/assign_departure.md),
[`assign_drop_geometry()`](https://ipeagit.github.io/r5r/reference/assign_drop_geometry.md),
[`assign_max_street_time()`](https://ipeagit.github.io/r5r/reference/assign_max_street_time.md),
[`assign_max_trip_duration()`](https://ipeagit.github.io/r5r/reference/assign_max_trip_duration.md),
[`assign_mode()`](https://ipeagit.github.io/r5r/reference/assign_mode.md),
[`assign_opportunities()`](https://ipeagit.github.io/r5r/reference/assign_opportunities.md),
[`assign_osm_link_ids()`](https://ipeagit.github.io/r5r/reference/assign_osm_link_ids.md),
[`assign_shortest_path()`](https://ipeagit.github.io/r5r/reference/assign_shortest_path.md)
