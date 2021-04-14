# log history of r5r package development

-------------------------------------------------------
# r5r v0.4.0

**Major changes**
- Updated R5 to version 6.2. Closes [#158](https://github.com/ipeaGIT/r5r/issues/158).
- Added `max_lts` parameter to `detailed_itineraries()` and `travel_time_matrix()` functions. LTS stands for Level of Traffic Stress, and allows modeling of bicycle comfort in routing analysis. Additional information can be found in [Conveyal's documentation](https://docs.conveyal.com/learn-more/traffic-stress) as well as blog posts [1](https://blog.conveyal.com/bike-lts-with-single-point-analysis-in-conveyal-55eecff8c0c7) and [2](https://blog.conveyal.com/modeling-bicycle-comfort-with-conveyal-analysis-part-2-6c0a3d004c6a). Closes [#160](https://github.com/ipeaGIT/r5r/issues/160)

**Minor changes**
- new support function `check_connection()` to check internect connection before
download files from Ipea server.



-------------------------------------------------------
# r5r v0.3-3

**Major changes**
- New vignette to [calculate and visualize isochrones](https://ipeagit.github.io/r5r/articles/calculating_isochrones.html).
- New vignette to [calculate and visualize accessibility](https://ipeagit.github.io/r5r/articles/calculating_accessibility.html).
- Significant performance increase in `detailed_itineraries()` when 
`shortest_path = TRUE`. Closes [#153](https://github.com/ipeaGIT/r5r/issues/153).
- [Paper on the r5r package published on **Findings**](https://doi.org/10.32866/001c.21262). Closes [#108](https://github.com/ipeaGIT/r5r/issues/108).

**Minor changes**
- `travel_time_matrix()` and `detailed_itineraries()` now output more detailed
messages in the console, when `verbose = TRUE`. This shall make debugging the
package much easier.
- Improved documentation of `travel_time_matrix()`. Closes [#149](https://github.com/ipeaGIT/r5r/issues/149).
- Checks origins/destinations inputs to make sure they have and `id` column. Closes [#154](https://github.com/ipeaGIT/r5r/issues/154).

**Bug fixes**
- Fixed [introductory vignette](https://ipeagit.github.io/r5r/articles/intro_to_r5r.html) to list only files that are included in the package installation. Closes [#111](https://github.com/ipeaGIT/r5r/issues/111).
- Fixed conflict with `{geobr}` package when downloading metadata. Closed [#137](https://github.com/ipeaGIT/r5r/issues/137).
- Fixed a bug when when parsing date and time from `departure_datetime` in `detailed_itineraries()` and `travel_time_matrix()`. Closes [#147](https://github.com/ipeaGIT/r5r/issues/147).
**Bug fixes**
- Fixed a bug in `detailed_itineraries()` that caused a crash when the shape of a route in the input GTFS is broken. Closes [#145](https://github.com/ipeaGIT/r5r/issues/145)

-------------------------------------------------------

# r5r v0.3-2

**Minor changes**
- r5r does not save the medatada file in the package directory anymore, following CRAN's policies. Closed #136.

-------------------------------------------------------

# r5r v0.3-1

**Minor changes**
- Allow for combination of bicycle and public transport. Closed #135.
- Added new parameter `mode_egress` to routing functions, so that users can 
explicitly set the transport mode used after egress from public transport (walk,
car or bicycle). Closed #63.
- Allow for using the r5r package off-line, provided the user has successfully ran
`setup_r5()` before.

-------------------------------------------------------

# r5r v0.3-0

**Major changes**
- Added Conveyal's R5 repo as a git submodule. This will help improve the long term integration between r5r and R5. Closed #105.
- Internal changes to make r5r compatible with R5 latest version 6.0.1.

**Minor changes**
- Added columns with population and number of schools in sample data set of Porto Alegre to allow for accessibility examples. Closed #128.
- The `percentiles` parameter in the `travel_time_matrix` function now only accepts up to 5 cut points due to changes in R5.

-------------------------------------------------------

# r5r v0.2-1

**Minor changes**
* Expanded number of routes in the sample GTFS for Porto Alegre, allowing for more
complex/realistic examples.
* Fixes format of columns of the output of `travel_matrix_function` when the user 
sets `time_window` parameter. Closes #127.
* Remove repeated bus route alternatives from the output from `detailed_itineraries`
* Explicitly link destination points to street network before starting. Closes #121

-------------------------------------------------------

# r5r v0.2-0

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

-------------------------------------------------------

# r5r v0.1-1

**Minor changes**
* Fixed issues with time zone when setting departure times
* Fixed issues to address CRAN checks
  * Now r5r can be installed on R (>= 3.6)
  * Appropriate hyperlinks indocumentation
  * Metadata is now downloaded from https:// server

-------------------------------------------------------

# r5r v0.1.0

* Launch of **r5r** v0.1.0 on [CRAN](https://CRAN.R-project.org/package=r5r).
* Package website https://ipeagit.github.io/r5r/
