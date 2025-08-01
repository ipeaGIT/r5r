## R CMD check results

── R CMD check results ────────────────────────────────────────────────── r5r 2.3.0 ────
Duration: 10m 54.2s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

**Major changes**

- New function `build_network()` to replace `setup_r5()`, which is being deprecated. Idiomatically `r5r_core` is now `r5r_network`.
- New function `build_custom_network()` to build a routable network. At the moment, the functions allows using modified OSM car speeds to account for different scenarios of traffic congestion and road closure. Closes [#289](https://github.com/ipeaGIT/r5r/issues/289)
- New function `arrival_travel_time_matrix()` to calculate travel time matrix between origin destination pairs considering the time of arrival, instead of a depature time. Closes [#291](https://github.com/ipeaGIT/r5r/issues/291)
- We have now implemented a reverse search optimization for direct transport modes (walking and cycling) in the functions `travel_time_matrix()`, `expanded_travel_time_matrix()` and `arrival_travel_time_matrix()`. In practice, this means that these functions are now much faster when there are multiple origins to few destinations but only when there is no elevation `.tif` file in the data path. Closes [#450](https://github.com/ipeaGIT/r5r/issues/450)

**Minor changes**

- The routable transport network build with `build_network()` and `setup_r5()` and `build_modified_network` now have a their own class `"r5r_network"`, making the package more consistent and safer from errors [#472](https://github.com/ipeaGIT/r5r/pull/472).
- Routing properties within r5r jar (aka little jar) are reset to default after a routing execution [#453](https://github.com/ipeaGIT/r5r/pull/453)
- Less cluttering messages in R5R dialogue. Removed logback startup messages. `Verbose=F` now completly silences java output. `Verbose=T` only reports messages up to INFO level as opposed to up to DEBUG [#456](https://github.com/ipeaGIT/r5r/pull/456).
- Removed date from r5r-log. You no longer have to delete the previous day's log! [#456](https://github.com/ipeaGIT/r5r/pull/456)
- Improved warning and error messages.

**Bug fixes**

- Fixed a bug where `network_settings.json` wasn't showing the right version numbers [#459](https://github.com/ipeaGIT/r5r/pull/459). Version number now dynamically updated [#456](https://github.com/ipeaGIT/r5r/pull/456).

**New co-authors**

- Alex Magnus
