## R CMD check results

── R CMD check results ─────────────────────────────────────────── r5r 2.2.0 ────
Duration: 20m 44.1s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

**Major changes**

- r5r now uses the latest version of R5 V7.4. Closed [#436](https://github.com/ipeaGIT/r5r/issues/436)
- The `detailed_itineraries()` now has a new parameter `osm_link_ids`. A logical. Whether the output should include the additional columns with the OSM ids of the road segments used along the trip geometry Defaults to `FALSE`. Closes issues [#298](https://github.com/ipeaGIT/r5r/issues/298)

**Minor changes**

- r5r now throws an informative error message when the geographic extent of input data exceeds limit of 975000 km2. Closes issues #389, #405, #406, #407, #412 and #421. Thanks to PR #426 by Alex Magnus.
- removed JRI dependency in r5r little jar. This helps debugging issues in Java without the need of using R. The side effect is that r5r now creates an `r5rlog` file in the data path.

**Bug fixes**

- Fixed error caused by phantom 0-minute isochrone. Closed issues #433 and #434
- Fixed a bug that prevented the package to check the availability of transit services in specific days when there is no service at all.
- Fixed a bug in the isochrone function that was throwing false error message regarding cutoff being too short. Closed [#434](https://github.com/ipeaGIT/r5r/issues/434) and [#433](https://github.com/ipeaGIT/r5r/issues/433)

**New contributors**

- Alex Magnus
- Luyu Liu
- Daniel Snow
- Funding from the Department of Geography & Planning, University of Toronto via the Bousfield Visitorship.

