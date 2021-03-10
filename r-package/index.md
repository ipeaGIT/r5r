# r5r: Rapid Realistic Routing with R5 in R <img align="right" src="https://github.com/ipeaGIT/r5r/blob/master/r-package/man/figures/r5r_blue.png?raw=true" alt="logo" width="180">
<!-- badges: start -->

[![CRAN/METACRAN Version](https://www.r-pkg.org/badges/version/r5r)](https://CRAN.R-project.org/package=r5r)
[![CRAN/METACRAN Total downloads](http://cranlogs.r-pkg.org/badges/grand-total/r5r?color=blue)](https://CRAN.R-project.org/package=r5r)
[![R build status](https://github.com/ipeaGIT/r5r/workflows/R-CMD-check/badge.svg)](https://github.com/ipeaGIT/r5r/actions)
![Codecov test coverage](https://codecov.io/gh/ipeaGIT/r5r/branch/master/graph/badge.svg) [![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Publication](https://img.shields.io/badge/DOI-10.32866/001c.21262-9cf)](https://doi.org/10.32866/001c.21262)

<!-- badges: end -->

**r5r** is an `R` package for rapid realistic routing on multimodal transport 
networks (walk, bike, public transport and car). It provides a simple and 
friendly interface to R<sup>5</sup>, the [Rapid Realistic Routing on Real-world and Reimagined networks](https://github.com/conveyal/r5).


**r5r** is a simple way to run R<sup>5</sup> locally, what allows users to
generate detailed routing analysis or calculate travel time matrices using 
seamless parallel computing. See a detailed demonstration of `r5r` in this
[intro Vignette](https://ipeagit.github.io/r5r/articles/intro_to_r5r.html). Over time, `r5r` migth be expanded to incorporate
other functionalities from R<sup>5</sup>


This repository contains the `R` code (r-package folder) and the Java code 
(java-api folder) that provides the interface to R<sup>5</sup>. Soon, this
could also become a `python` library. 


## Installation

To use `r5r`, you need to have *Java SE Development Kit 11* installed on your computer. No worries, you don't have to pay for it. The jdk 11 is freely available from the options below:
- [OpenJDK](http://jdk.java.net/java-se-ri/11)
- [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

```R
# From CRAN
  install.packages("r5r")
  library(r5r)

# or use the development version with latest features
  utils::remove.packages('r5r')
  devtools::install_github("ipeaGIT/r5r", subdir = "r-package")
  library(r5r)

```

## Usage

The package has three fundamental functions.

1. `setup_r5`
   * Downloads and stores locally an R5 Jar file (Jar file is downloaded only once)
   * Builds a multimodal transport network given a street network in `.pbf` format
   (mandatory) and one or more public transport networks in `GTFS.zip` format 
   (optional).

2. `detailed_itineraries`
   * Returns a `data.frame sf LINESTRINGs` with one or multiple alternative routes
   between one or multiple origin destination pairs. The data output brings 
   detailed information on transport mode, travel time, walk distance etc for 
   each trip section
 
3. `travel_time_matrix`
   * Fast function that returns a simple 'data.frame' with travel time 
   estimates between one or multiple origin destination pairs.

### Demonstration on sample data
See a detailed demonstration of `r5r` in this [intro Vignette](https://ipeagit.github.io/r5r/articles/intro_to_r5r.html). To illustrate
functionality, the package includes a small sample data set of the public transport
and Open Street Map networks of Porto Alegre (Brazil). Three steps are required to 
use `r5r`, as follows.

```R
# allocate RAM memory to Java
options(java.parameters = "-Xmx2G")

# 1) build transport network, pointing to the path where OSM and GTFS data are stored
library(r5r)
path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path, verbose = FALSE)

# 2) load origin/destination points and set arguments
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
mode <- c("WALK", "BUS")
max_walk_dist <- 3000   # meters
max_trip_duration <- 60 # minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# 3.1) calculate a travel time matrix
ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = points,
                          destinations = points,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_dist = max_walk_dist,
                          max_trip_duration = max_trip_duration)

# 3.2) or get detailed info on multiple alternative routes
det <- detailed_itineraries(r5r_core = r5r_core,
                            origins = points[370, ],
                            destinations = points[200, ],
                            mode = mode,
                            departure_datetime = departure_datetime,
                            max_walk_dist = max_walk_dist,
                            max_trip_duration = max_trip_duration,
                            shortest_path = FALSE)
```



#### **Related R packages**

There is a growing number of `R` packages with functionalities for transport
routing, analysis and planning more broadly. Here are few of theses packages.

- [dodgr](https://github.com/ATFutures/dodgr): Distances on Directed Graphs in R
- [gtfsrouter](https://github.com/ATFutures/gtfs-router): R package for routing with GTFS data
- [hereR](https://github.com/munterfinger/hereR): an R interface to the HERE REST APIs 
- [opentripplanner](https://github.com/ropensci/opentripplanner): OpenTripPlanner for R
- [stplanr](https://github.com/ropensci/stplanr): sustainable transport planning with R

The **r5r** package is particularly focused on fast multimodal transport routing.
A key advantage of `r5r` is that is provides a simple and friendly R interface
to R<sup>5</sup>, one of the fastest and most robust routing engines availabe.

-----

# Acknowledgement
The [R<sup>5</sup> routing engine](https://github.com/conveyal/r5) is developed 
at [Conveyal](https://www.conveyal.com/) with contributions from several people.


# Citation <img align="right" src="r-package/man/figures/ipea_logo.png" alt="ipea" width="300">

 The R package **r5r** is developed by a team at the Institute for Applied Economic Research (Ipea), Brazil. If you use this package in research publications, we please cite it as:

* Pereira, R. H. M., Saraiva, M., Herszenhut, D., Braga, C. K. V., & Conway, M. W. (2021). **r5r: Rapid Realistic Routing on Multimodal Transport Networks with R5 in R**. *Findings*, 21262. [https://doi.org/10.32866/001c.21262](https://doi.org/10.32866/001c.21262)

BibTeX:
```
@article{pereira_r5r_2021,
	title = {r5r: Rapid Realistic Routing on Multimodal Transport Networks with {R}$^{\textrm{5}}$ in R},
	shorttitle = {r5r},
	url = {https://findingspress.org/article/21262-r5r-rapid-realistic-routing-on-multimodal-transport-networks-with-r-5-in-r},
	doi = {10.32866/001c.21262},
	abstract = {Routing is a key step in transport planning and research. Nonetheless, researchers and practitioners often face challenges when performing this task due to long computation times and the cost of licensed software. R{\textasciicircum}5{\textasciicircum} is a multimodal transport network router that offers multiple routing features, such as calculating travel times over a time window and returning multiple itineraries for origin/destination pairs. This paper describes r5r, an open-source R package that leverages R{\textasciicircum}5{\textasciicircum} to efficiently compute travel time matrices and generate detailed itineraries between sets of origins and destinations at no expense using seamless parallel computing.},
	language = {en},
	urldate = {2021-03-04},
	journal = {Findings},
	author = {Pereira, Rafael H. M. and Saraiva, Marcus and Herszenhut, Daniel and Braga, Carlos Kaue Vieira and Conway, Matthew Wigginton},
	month = mar,
	year = {2021},
	note = {Publisher: Network Design Lab}
}

```
