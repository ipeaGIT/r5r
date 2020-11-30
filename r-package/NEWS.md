# log history of r5r package development


-------------------------------------------------------
# r5r v0.2-1 dev


**Minor changes**
* expanded number of routes in the sample GTFS for Porto Alegre, allowing for more
complex/realistic examples.
* Fixes format of columns of the output of `travel_matrix_function` when the user 
sets `time_window` parameter. Closes #127.
* remove repeated bus route alternatives from the output from `detailed_itineraries`

-------------------------------------------------------
# r5r v0.2-0

**Major changes**

* Function `travel_time_matrix` now has new parameters `time_window` and
`percentiles` it now calculates travel times for multiple departure times each 
minute within a given time window. For now, the function automatically set the
number of Monte Carlo Draws to 5 times the size of `time_window`. Closes #104 
and #118

**Minor changes**
* added a sample of frequency-based GTFS for Sao Paulo. Closed #116
* improved documentation of routing functions adding more info on the routing 
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
