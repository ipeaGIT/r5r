# Assign opportunities data

Check and create an opportunities dataset.

## Usage

``` r
assign_opportunities(destinations, opportunities_colnames)
```

## Arguments

- destinations:

  Either a `data.frame` or a `POINT sf`.

- opportunities_colnames:

  A character vector with the names of the opportunities columns in
  `destinations`.

## Value

A list of `Java-Array` objects.

## See also

Other assigning functions:
[`assign_decay_function()`](https://ipeagit.github.io/r5r/reference/assign_decay_function.md),
[`assign_departure()`](https://ipeagit.github.io/r5r/reference/assign_departure.md),
[`assign_drop_geometry()`](https://ipeagit.github.io/r5r/reference/assign_drop_geometry.md),
[`assign_max_street_time()`](https://ipeagit.github.io/r5r/reference/assign_max_street_time.md),
[`assign_max_trip_duration()`](https://ipeagit.github.io/r5r/reference/assign_max_trip_duration.md),
[`assign_mode()`](https://ipeagit.github.io/r5r/reference/assign_mode.md),
[`assign_osm_link_ids()`](https://ipeagit.github.io/r5r/reference/assign_osm_link_ids.md),
[`assign_points_input()`](https://ipeagit.github.io/r5r/reference/assign_points_input.md),
[`assign_shortest_path()`](https://ipeagit.github.io/r5r/reference/assign_shortest_path.md)
