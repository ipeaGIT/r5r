## R CMD check results

── R CMD check results ──────────────────────────────────────── r5r 2.0 ────
Duration: 29m 21.6s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


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
