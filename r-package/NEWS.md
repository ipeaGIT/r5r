# r5r 2.3.0 dev

**Major changes**

- New function `build_network()` to replace `setup_r5()`, which is being deprecated.
- New function `build_custom_network()` to build a routable network with modified OSM car speeds to account for different scenarios of traffic congestion and road closure. Closes [#289](https://github.com/ipeaGIT/r5r/issues/289)
- New function `arrival_travel_time_matrix()` to calculate travel time matrix between origin destination pairs considering the time of arrival, instead of a depature time. Closes [#291](https://github.com/ipeaGIT/r5r/issues/291)
- We have now implemented a reverse search optimization for direct transport modes (walking and cycling) in the functions `travel_time_matrix()`, `expanded_travel_time_matrix()` and `arrival_travel_time_matrix()`. In pactice, this means that these functions are now much faster when there are multiple origins to few destinations. Closes [#450](https://github.com/ipeaGIT/r5r/issues/450)

**Minor changes**

- The routable transport network build with `build_network()` and `setup_r5()` now have a their own class `"r5r_network"`, making the package more consistent and safer from errors. 
- Routing properties within r5r jar (aka little jar) are reset to default after a routing execution [#453](https://github.com/ipeaGIT/r5r/pull/453)



# r5r 2.2.0

**Major changes**

- r5r now uses the latest version of R5 V7.4. Closed [#436](https://github.com/ipeaGIT/r5r/issues/436)
- The `detailed_itineraries()` now has a new parameter `osm_link_ids`. A logical. Whether the output should include the additional columns with the OSM ids of the road segments used along the trip geometry Defaults to `FALSE`. Closes issues [#298](https://github.com/ipeaGIT/r5r/issues/298)

**Minor changes**

- r5r now throws an informative error message when the geographic extent of input data exceeds limit of 975000 km2. Closes issues #389, #405, #406, #407, #412 and #421. Thanks to PR #426 by Alex Magnus.
- removed JRI dependency in r5r little jar. This helps debugging issues in Java without the need of using R. The side effect is that r5r now creates an `r5rlog` file in the data path.

**Bug fixes**

- Fixed a bug that prevented the package to check the availability of transit services in specific days when there is no service at all.
- Fixed a bug in the isochrone function that was throwing false error message regarding cutoff being too short. Closed [#434](https://github.com/ipeaGIT/r5r/issues/434) and [#433](https://github.com/ipeaGIT/r5r/issues/433)

**New contributors**

- Alex Magnus
- Luyu Liu
- Daniel Snow
- Funding from the Department of Geography & Planning, University of Toronto via the Bousfield Visitorship.

# r5r 2.1.0

**Minor changes**

- The `isochrone()` function has a new boolean parameter `polygon_output` that allows users to choose whether the output should be a polygon- or line-based isochrone. Closed [#382](https://github.com/ipeaGIT/r5r/issues/382)
- When using public transit modes, the package now automatically detects whether there are any transit services operation on the seleced departure date. If there are no services, the package will return an error message. Closed [#326](https://github.com/ipeaGIT/r5r/issues/326)


# r5r 2.0

**Breaking changes**

- r5r uses now JDK 21 or higher (Breaking changes). Closed [#350](https://github.com/ipeaGIT/r5r/issues/350).
- r5r now uses the latest version of R5 V7.1. Closed [#350](https://github.com/ipeaGIT/r5r/issues/350)

**Major changes**

- r5r now stores R5 Jar file at user dir using `tools::R_user_dir()`
- New function `r5r_cache()` to manage the cache of the R5 Jar file.
- By using the JDK 21, this version of r5r also fixed an incompatibility with MAC ARM processors. Closed [#315](https://github.com/ipeaGIT/r5r/issues/315)

**Minor changes**

- In the `accessibility()` function, the value of `max_trip_duration` is now capped by the max value passed to the `cutoffs` parameter. Closes [#342](https://github.com/ipeaGIT/r5r/issues/348).
- Updated documentation of parameter `max_walk_time` to make it clear that in walk-only trips, whenever `max_walk_time` differs from `max_trip_duration`, the lowest value is considered. Closes [#353](https://github.com/ipeaGIT/r5r/issues/353)
- Updated documentation of parameter `max_bike_time` to make it clear that in bicycle-only trips, whenever `max_bike_time` differs from `max_trip_duration`, the lowest value is considered. Closes [#353](https://github.com/ipeaGIT/r5r/issues/353)
- Improved documentation of parameter `suboptimal_minutes` in the `detailed_itineraries()` function.
- Updated the vignette on time window to explain how this parameter behaves when used in the `detailed_itineraries()` function.

**Bug Fixes**
- Fixed bug that prevented the use the `output_dir` parameter in the `detailed_itineraries(all_to_all = TRUE)` function. Closes [#327](https://github.com/ipeaGIT/r5r/issues/327) with a contribution ([PR #354](https://github.com/ipeaGIT/r5r/pull/354)) from Luyu Liu.
- Fixed bug that prevented  `detailed_itineraries` from working with frequency-based GTFS feeds. It should ONLY work with frequency-based GTFS feeds.

**New contributors to r5r**
- [Luyu Liu](https://github.com/luyuliu)


# r5r 1.1.0

**Major changes**

- New `isochrone()`function. Closes [#123](https://github.com/ipeaGIT/r5r/issues/123), and addresses requrests in issues [#164](https://github.com/ipeaGIT/r5r/issues/164) and [#328](https://github.com/ipeaGIT/r5r/issues/328).
- New vignette about calculating / visualizing isochrones with `r5r`.
- New vignette with responses to frequently asked questions (FAQ) from `r5r` users.

**Minor changes**

- The default value of `time_window` is not set to `10` minutes in all functions to avoid weird results reported upstream in R5. Closes [#342](https://github.com/ipeaGIT/r5r/issues/342).
- Removed any mention to `percentiles` parameter in the `expanded_travel_time_matrix()` because this function does not expose this parameter to users. Closes [#343](https://github.com/ipeaGIT/r5r/issues/343).
- Updated vignette on calculating / visualizing accessibility with `r5r`.


# r5r 1.0.1

**Bug fixes**

* Updated to R5 version 6.9. This fixed a few bugs upstream, one of which often prevented users to build a network using cropped OSM data. Closes [#325](https://github.com/ipeaGIT/r5r/issues/325).



# r5r 1.0.0

**Breaking changes**

- Replaced `max_walk_dist` and `max_bike_dist` parameters with `max_walk_time` and `max_bike_time` to better align with R5 inputs. Closes [#273](https://github.com/ipeaGIT/r5r/issues/273).
- `r5r` now uses `R5`'s native elevation weighting for walking and cycling impedance functions. As a result `r5r` does not have raster or rgdal package dependencies anymore. Closes [#243](https://github.com/ipeaGIT/r5r/issues/243) and [#233](https://github.com/ipeaGIT/r5r/issues/233).
- Parameters `breakdown` and `breakdown_stat` in `travel_time_matrix()` were removed. New function `expanded_travel_time_matrix()` should be used to retrieve detailed information of travel time matrices.
- `r5r`now throws an error if users simultaneously pass more than one of the following modes `c('WALK','CAR','BICYCLE')` to the `transport_mode` parameter. This is because these modes are understood as mutually exclusive.
- Function `setup_r5()` no longer has a `version` parameter.

**New functions**

- New function `expanded_travel_time_matrix()` to calculate minute-by-minute travel times between origin destination pairs and get additional information on public transport routes, number of transfers, and total access, waiting, in-vehicle and transfer times.
- New function `pareto_frontier()` to compute of travel time and monetary cost Pareto frontier.
- New function `r5r_sitrep()` to generate an `r5r` situation report to help debug code errors
- New functions to account for monetary costs:
  - `setup_fare_structure()` to setup a fare structure to calculate the monetary costs of trips
  - `read_fare_structure()` to read a fare structure object from a file
  - `write_fare_structure()` to write a fare structure object to disk

**Major changes**

- Now using R5 latest version `6.8`.
- The `detailed_itineraries()` has been substantially improved. The new vesion is faster than  previous ones. It also includes new parameters listed below. Closes [#265](https://github.com/ipeaGIT/r5r/issues/265).
  - New `time_window` parameter
  - New `suboptimal_minutes` parameter, which extends the search space and returns a larger number of trips beyond the fastest ones;
  - Support for fare calculator and new `max_fare` parameter;
  - Routing in frequencies GFTS, including support for Monte Carlo draws
- New parameter `draws_per_minute` to `travel_time_matrix()`, `accessibility()` and `pareto_frontier()` functions. Closes [#230](https://github.com/ipeaGIT/r5r/issues/230).
- New parameter `output_dir` to all routing functions, which can be used to specify a directory in which the results should be saved as `.csv` files (one file for each origin). This parameter is particularly useful when running estimates on memory-constrained settings, because writing the results to disk prevents `R5` from storing them in memory.
- The accessibility estimates from `accessibility()` are now of returned as doubles / class `numeric`, except when using a `step` decay function. Closes [#235](https://github.com/ipeaGIT/r5r/issues/235).
- The `detailed_itineraries()` function has a new parameter `all_to_all`, which allows users to set whether they want to query routes between all origins to all destinations (`all_to_all = TRUE`) or to query routes between the 1st origin to the 1st destination, then the 2nd origin to the 2nd destination, and so on (`all_to_all = FALSE`, the default). Closes [#224](https://github.com/ipeaGIT/r5r/issues/224).



**Minor changes**

- Package documentation has been extensively updated and expanded.
- Improved documentation of the `cutoffs` parameter in `accessibility()`, clarifying the function only accepts up to 12 cutoff values. Closes [#216](https://github.com/ipeaGIT/r5r/issues/216).
- Improved documentation of the `percentiles` parameter in `accessibility()` and `travel_time_matrix()`, clarifying these function only accepts up to 5 values. Closes [#246](https://github.com/ipeaGIT/r5r/issues/246).
- r5r now downloads R5 Jar directly from Conveyal's github, making the package more stable. Closes [#226](https://github.com/ipeaGIT/r5r/issues/226).
- All functions now use `verbose = FALSE` and `progress = FALSE` by default.
- Routing functions now require users to be non-ambiguous when specifying the modes, raising errors when it cannot disambiguate them. This new behaviour replaces the old one, in which the functions could end up trying to "guess" which mode was to be used in some edge cases.
- Information on bicycle 'level of traffic stress' is now added to the output of `street_network_to_sf()`. Closes [#251](https://github.com/ipeaGIT/r5r/issues/251).
- New columns with info on population, schools and jobs in the example data sets for Sao Paulo and Porto Alegre

**Bug fixes**

- Fixed bug that `transit_network_to_sf()` generated some routes with invalid geometries. Closes [#256](https://github.com/ipeaGIT/r5r/issues/256).
- Fixed bug that prevented `setup_r5(path, overwrite = TRUE)` to work.



# r5r 0.7.1

**Minor change**

* Replaced the akima package with interp package in r5r Suggests, as requested by CRAN.

# r5r 0.7.0

**Major changes**

* From this version onwards, r5r downloads R5 JAR from github, which provides more stable connection than Ipea server. 
* The number of Monte Carlo draws to perform per time window minute when calculating travel time matrices and when estimating accessibility is now set via the `r5r.montecarlo_draws` option. Defaults to 5. This would mean 300 draws in a 60 minutes time window, for example. The user may also set a custom value using `options(r5r.montecarlo_draws = 10L)` (in which you substitute 10L by the value you want to set).

**Minor changes**

* Changed `total_time` column name to `combined_time` in `travel_time_matrix()` 
output, to avoid confusion with `travel_time` column.

# r5r 0.6.0 

**Major changes**

* Updated R5 to version 6.4. Closes [#182](https://github.com/ipeaGIT/r5r/issues/182).

* Significant performance improvements in all functions, due to a faster method
for consolidating outputs. Closes [#180](https://github.com/ipeaGIT/r5r/issues/180)

* New function `transit_network_to_sf()`, to extract the public transport network 
from R5 as simple features. Closes [#179](https://github.com/ipeaGIT/r5r/issues/179)

* New `progress` parameter in the `accessibility()`, `travel_time_matrix`, and
`detailed_itineraries()` functions, to show or hide the progress counter 
indicator. Closes [#186](https://github.com/ipeaGIT/r5r/issues/186)

* Created new support function `java_to_dt()` and removed dependency on the `jdx` package. Closes [#206](https://github.com/ipeaGIT/r5r/issues/206)

* Reduced r5r's internet dependency quite considerably. Internet is now only required to download the latest R5 jar if it hasn't been downloaded before. Closes [#197](https://github.com/ipeaGIT/r5r/issues/197).

* Added two new parameters `breakdown` and `breakdown_stat` to the `travel_time_matrix()`. This allows users to breakdown the travel time information by trip subcomponents (access time, waiting time, traveling time etc). It allows one to extract more information but it makes computation time slower. Closes [#194](https://github.com/ipeaGIT/r5r/issues/194)

**Minor changes**

* New `setup_r5()` parameter, `overwrite`, that forces the building of a new `network.dat`, even if one already exists.
* Improved documentation of parameter `departure_datetime` to clarify the parameter must be set to local time. Closes [#188](https://github.com/ipeaGIT/r5r/issues/188)
* Improved documentation regarding personalized LTS values. [Closes #190](https://github.com/ipeaGIT/r5r/issues/190).
* Improved documentation of `transit_network_to_sf()` regarding stops that are not snapped to road network. [Closes #192](https://github.com/ipeaGIT/r5r/issues/192).
* Improved documentation of `max_walking_dist` and `max_cycling_dist` parameters. [Closes #193]( https://github.com/ipeaGIT/r5r/issues/193).
* Started raising an error if the CRS of origins/destinations is not WGS 84. Closes [#201](https://github.com/ipeaGIT/r5r/issues/201).

# r5r 0.5.0

**Major changes**

* New function `accessibility()` to calculate access to opportunities. Closes [#169](https://github.com/ipeaGIT/r5r/issues/169)

* New function `find_snap()` to help users identify where in the street network the input of origin and destination points are snapped to. Closes [168](https://github.com/ipeaGIT/r5r/issues/168).

* New parameter `max_bike_dist` added to routing and accessibility functions. Closes [#174](https://github.com/ipeaGIT/r5r/issues/174)

* Implemented temporary solution for elevation. Closes [#171](https://github.com/ipeaGIT/r5r/issues/171). Now r5r can read Digital Elevation Model (DEM) data from raster files in `.tif` format to weight the
street network for walking and cycling according to the terrain's slopes. Ideally, we would like to see a solution that accounts for elevation implemented upstream in R5. For now, this is a temporary solution implemented within r5r.

**Minor changes**

* The `street_network_to_sf()` now has a more clean output when the provided GTFS covers a larger area than the street network pbf. Closes [#173](https://github.com/ipeaGIT/r5r/issues/173)

* The size of poa.zip sample GTFS data has been reduced due to CRAN policies. Closes [#172](https://github.com/ipeaGIT/r5r/issues/172).

* Progress counter Implemented. Closes [150](https://github.com/ipeaGIT/r5r/issues/150). When the `verbose` parameter is set to `FALSE`, r5r prints a progress counter and eventual `ERROR` messages. This comes with a minor penalty for computation performance. Hence we have kept `verbose` defautls to `TRUE`.

**Bug fixes**

* Fixed bug that prevented r5r from running without internet connection. Closes [#163](https://github.com/ipeaGIT/r5r/issues/163).

# r5r 0.4-0

**Major changes** 

* Updated R5 to version 6.2. Closes [#158](https://github.com/ipeaGIT/r5r/issues/158).
* Added `max_lts` parameter to `detailed_itineraries()` and `travel_time_matrix()` functions. LTS stands for Level of Traffic Stress, and allows modeling of bicycle comfort in routing analysis. Additional information can be found in [Conveyal's documentation](https://docs.conveyal.com/learn-more/traffic-stress) as well as blog posts [1](https://blog.conveyal.com/bike-lts-with-single-point-analysis-in-conveyal-55eecff8c0c7) and [2](https://blog.conveyal.com/modeling-bicycle-comfort-with-conveyal-analysis-part-2-6c0a3d004c6a). Closes [#160](https://github.com/ipeaGIT/r5r/issues/160)

**Minor changes**

* New support function `check_connection()` to check internect connection before
download files from Ipea server.

# r5r 0.3-3

**Major changes**

* New vignette to [calculate and visualize isochrones](https://ipeagit.github.io/r5r/articles/isochrones.html).
* New vignette to [calculate and visualize accessibility](https://ipeagit.github.io/r5r/articles/accessibility.html).
* Significant performance increase in `detailed_itineraries()` when 
`shortest_path = TRUE`. Closes [#153](https://github.com/ipeaGIT/r5r/issues/153).
* [Paper on the r5r package published on **Findings**](https://doi.org/10.32866/001c.21262). Closes [#108](https://github.com/ipeaGIT/r5r/issues/108).

**Minor changes**

* `travel_time_matrix()` and `detailed_itineraries()` now output more detailed
messages in the console, when `verbose = TRUE`. This shall make debugging the
package much easier.
* Improved documentation of `travel_time_matrix()`. Closes [#149](https://github.com/ipeaGIT/r5r/issues/149).
* Checks origins/destinations inputs to make sure they have and `id` column. Closes [#154](https://github.com/ipeaGIT/r5r/issues/154).

**Bug fixes**

- Fixed [introductory vignette](https://ipeagit.github.io/r5r/articles/r5r.html) to list only files that are included in the package installation. Closes [#111](https://github.com/ipeaGIT/r5r/issues/111).
* Fixed conflict with `{geobr}` package when downloading metadata. Closed [#137](https://github.com/ipeaGIT/r5r/issues/137).
* Fixed a bug when when parsing date and time from `departure_datetime` in `detailed_itineraries()` and `travel_time_matrix()`. Closes [#147](https://github.com/ipeaGIT/r5r/issues/147).
* Fixed a bug in `detailed_itineraries()` that caused a crash when the shape of a route in the input GTFS is broken. Closes [#145](https://github.com/ipeaGIT/r5r/issues/145)

# r5r 0.3-2

**Minor changes**

* r5r does not save the medatada file in the package directory anymore, following CRAN's policies. Closed #136.

# r5r 0.3-1

**Minor changes** 

* Allow for combination of bicycle and public transport. Closed #135.
* Added new parameter `mode_egress` to routing functions, so that users can 
explicitly set the transport mode used after egress from public transport (walk,
car or bicycle). Closed #63.
* Allow for using the r5r package off-line, provided the user has successfully ran
`setup_r5()` before.

# r5r 0.3-0

**Major changes**

* Added Conveyal's R5 repo as a git submodule. This will help improve the long term integration between r5r and R5. Closed #105.
* Internal changes to make r5r compatible with R5 latest version 6.0.1.

**Minor changes**

* Added columns with population and number of schools in sample data set of Porto Alegre to allow for accessibility examples. Closed #128.
* The `percentiles` parameter in the `travel_time_matrix` function now only accepts up to 5 cut points due to changes in R5.

# r5r 0.2-1

**Minor changes** 

* Expanded number of routes in the sample GTFS for Porto Alegre, allowing for more
complex/realistic examples.
* Fixes format of columns of the output of `travel_matrix_function` when the user 
sets `time_window` parameter. Closes #127.
* Remove repeated bus route alternatives from the output from `detailed_itineraries`
* Explicitly link destination points to street network before starting. Closes #121

# r5r 0.2-0

**Major changes** 

* Function `travel_time_matrix` now has new parameters `time_window` and
`percentiles` it now calculates travel times for multiple departure times each 
minute within a given time window. For now, the function automatically set the
number of Monte Carlo Draws to 5 times the size of `time_window`. Closes #104 
and #118

**Minor changes**

* Added a sample of frequency-based GTFS for Sao Paulo. Closed #116
* Improved documentation of routing functions adding more info on the routing 
algorithms used in R5. Closes #114

# r5r v0.1-1

**Minor changes**

* Fixed issues with time zone when setting departure times
* Fixed issues to address CRAN checks
  * Now r5r can be installed on R (>= 3.6)
  * Appropriate hyperlinks indocumentation
  * Metadata is now downloaded from https:// server

# r5r 0.1-0

* Launch of **r5r** v0.1.0 on [CRAN](https://CRAN.R-project.org/package=r5r).
* Package website https://ipeagit.github.io/r5r/
