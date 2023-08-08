## R CMD check results

── R CMD check results ───────────────────────────────────────────── r5r 1.1.0 ────
Duration: 24m 8.8s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

* This is a minor update with bug fixes


**Major changes**

- New `isochrone()`function. Closes [#123](https://github.com/ipeaGIT/r5r/issues/123), and addresses requrests in issues [#164](https://github.com/ipeaGIT/r5r/issues/164) and [#328](https://github.com/ipeaGIT/r5r/issues/328).
- New vignette about calculating / visualizing isochrones with `r5r`.
- New vignette with responses to frequently asked questions (FAQ) from `r5r` users.

**Minor changes**

- The default value of `time_window` is not set to `10` minutes in all functions to avoid weird results reported upstream in R5. Closes [#342](https://github.com/ipeaGIT/r5r/issues/342).
- Removed any mention to `percentiles` parameter in the `expanded_travel_time_matrix()` because this function does not expose this parameter to users. Closes [#343](https://github.com/ipeaGIT/r5r/issues/343).
- Updated vignette on calculating / visualizing accessibility with `r5r`.

