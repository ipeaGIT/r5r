
# r5r




### Package functions

- [ ] `download_r5`
  - input: version
  - output: R5 JAR saved in the package directory

- [ ] `setup_r5`
  - input: local directory with input data (.pbf, GTFS.zip) OR network.dat object
  - output: a network.dat object is saved in the same directory and loaded to memory
  - output: returns the r5rcore object


- [ ] `detailed_itineraries` (alternative names: `trips`, `plan_multiple_trip`)

  - output: a `data.frames sf` with detailed itinariries
  - input: date
  - input: departure_time
  - input: mode
  - input: speed
  - input: origins
  - input: destinations


- [ ] `travel_times`  (alternative names: `travel_time_matrix`)
  - output: a `data.table` with travel times between pairs of Origin-destination
  - input: date
  - input: departure_time
  - input: mode
  - input: speed
  - input: origins
  - input: destinations

