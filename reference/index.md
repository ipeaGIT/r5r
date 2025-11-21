# Package index

## Building routable transport network

- [`build_network()`](https://ipeagit.github.io/r5r/reference/build_network.md)
  : Build a transport network used for routing in R5
- [`setup_r5()`](https://ipeagit.github.io/r5r/reference/setup_r5.md)
  **\[deprecated\]** : Create a transport network used for routing in R5
  (deprecated)

## Accessibility

- [`accessibility()`](https://ipeagit.github.io/r5r/reference/accessibility.md)
  : Calculate access to opportunities

## Routing

- [`travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/travel_time_matrix.md)
  : Calculate travel time matrix between origin destination pairs
  considering a departure time
- [`arrival_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/arrival_travel_time_matrix.md)
  : Calculate travel time matrix between origin destination pairs
  considering a time of arrival
- [`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/reference/expanded_travel_time_matrix.md)
  : Calculate minute-by-minute travel times between origin destination
  pairs
- [`detailed_itineraries()`](https://ipeagit.github.io/r5r/reference/detailed_itineraries.md)
  : Detailed itineraries between origin-destination pairs
- [`pareto_frontier()`](https://ipeagit.github.io/r5r/reference/pareto_frontier.md)
  : Calculate travel time and monetary cost Pareto frontier

## Isochrone

- [`isochrone()`](https://ipeagit.github.io/r5r/reference/isochrone.md)
  : Estimate isochrones from a given location

## Extracting transport network spatial data

- [`street_network_to_sf()`](https://ipeagit.github.io/r5r/reference/street_network_to_sf.md)
  : Extract OpenStreetMap network in sf format
- [`transit_network_to_sf()`](https://ipeagit.github.io/r5r/reference/transit_network_to_sf.md)
  : Extract transit network in sf format
- [`street_network_bbox()`](https://ipeagit.github.io/r5r/reference/street_network_bbox.md)
  : Extract the geographic bounding box of the transport network

## Fare structure

- [`setup_fare_structure()`](https://ipeagit.github.io/r5r/reference/setup_fare_structure.md)
  : Setup a fare structure to calculate the monetary costs of trips
- [`read_fare_structure()`](https://ipeagit.github.io/r5r/reference/read_fare_structure.md)
  : Read a fare structure object from a file
- [`write_fare_structure()`](https://ipeagit.github.io/r5r/reference/write_fare_structure.md)
  : Write a fare structure object to disk

## Support functions

- [`check_transit_availability()`](https://ipeagit.github.io/r5r/reference/check_transit_availability.md)
  : Check transit service availability by date

- [`find_snap()`](https://ipeagit.github.io/r5r/reference/find_snap.md)
  : Find snapped locations of input points on street network

- [`r5r_sitrep()`](https://ipeagit.github.io/r5r/reference/r5r_sitrep.md)
  : Generate an r5r situation report to help debug errors

- [`r5r_cache()`](https://ipeagit.github.io/r5r/reference/r5r_cache.md)
  : Manage cached files from the r5r package

- [`download_r5()`](https://ipeagit.github.io/r5r/reference/download_r5.md)
  :

  Download `R5.jar`

- [`stop_r5()`](https://ipeagit.github.io/r5r/reference/stop_r5.md) :
  Stop running r5r network
