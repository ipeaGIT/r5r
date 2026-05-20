## R CMD check results

── R CMD check results ────────────────────────────────────────────────────────── r5r 2.4.0 ────
Duration: 9m 28.6s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

# r5r 2.4.0 dev 

- Fixed broken link to vignette
- the following link works fine: https://escholarship.org/uc/item/05r820mz

**Major changes**

- Using new version of R5 v7.5.1. Closed [#373](https://github.com/ipeaGIT/r5r/issues/373) 
and [#970](https://github.com/conveyal/r5/issues/970)
- The `isochrone()` function has gone through major changes which substantially
improved polygon-based isochrones. The function now builds on top of a travel 
time surface that uses a regular grid of points across the network (specifically 
a grid of Web Mercator pixels) and then uses the marching squares algorithm to 
generate the isochrone polygons. See detailed in the updated vignette. Closed 
[#455](https://github.com/ipeaGIT/r5r/issues/455) and Closed [#495](https://github.com/ipeaGIT/r5r/issues/495).
- New support function `get_gtfs_errors()` to help diagnose eventual errors in
the GTFS data that prevent building the network. Closed [#431](https://github.com/ipeaGIT/r5r/issues/431) and [#541](https://github.com/ipeaGIT/r5r/issues/541).

**Minor changes**

- New support function `check_transit_availability()` that checks the number and 
proportion of public transport services from the GTFS feeds that are active on 
specified dates.
- New support function `street_network_bbox()` that efficiently extracts the 
geographic bounding box of the transport network.
- More informative messages in case of Java error in R5. Closed [#515](https://github.com/ipeaGIT/r5r/issues/515).
- When direct routing fails the log now mentions the name of the origin and 
destination points to help the user debug. Closed [#519](https://github.com/ipeaGIT/r5r/issues/519).

**Bug fixes**

- Revert back the order of origins destinations for Direct Modes. Fix implemented 
`in travel_time_matrix()`, `arrival_travel_time_matrix()` and `expanded_travel_time_matrix()`. 
Closes [#501](https://github.com/ipeaGIT/r5r/issues/501).
- Reverse search optimization is now only applicable to walking. Closes [#517](https://github.com/ipeaGIT/r5r/issues/517).
- r5r now uses walking speed from request location to snapped point on the road 
network. This was a fix upstream in R5. Closed [#373](https://github.com/ipeaGIT/r5r/issues/373) 
- Elevation data does not affect carspeeds anymore. This was a fix upstream in 
R5. Closed [#970](https://github.com/conveyal/r5/issues/970)
- Fixed a bug that was introduced in r5r {2.3.0} and which led to ignore elevation 
when building the network. Closed [#555](https://github.com/conveyal/r5/issues/555).
Elevation data is still ignored when creating scenarios of LTS, but this is a know
bug that will throw warning messages while we work a way to fix it in a future 
update.

