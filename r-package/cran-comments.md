## R CMD check results

── R CMD check results ────────────────────────────────────────────── r5r 2.1.0 ────
Duration: 9m 25s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔

**Minor changes**

- The `isochrone()` function has a new boolean parameter `polygon_output` that allows users to choose whether the output should be a polygon- or line-based isochrone. Closed [#382](https://github.com/ipeaGIT/r5r/issues/382)
- When using public transit modes, the package now automatically detects whether there are any transit services operation on the seleced departure date. If there are no services, the package will return an error message. Closed [#326](https://github.com/ipeaGIT/r5r/issues/326)
