
# r5r: Rapid Realistic Routing with R5 in R

**r5r** is an `R` package for rapid realistic routing on multimodal transport 
networks (walk, bike, public transport and car). It provides a simple and 
friendly interface to R<sup>5</sup>, the [Rapid Realistic Routing on Real-world and Reimagined networks](https://github.com/conveyal/r5).


**r5r** is a simple way to run R<sup>5</sup> locally, what allows users to
generate detailed routing analysis or calculate travel time matrices using 
seamless parallel computing. See a detailed demonstration of `r5r` in this
intro Vignette (*soon*). Over time, `r5r` migth be expanded to incorporate
other functionalities from R<sup>5</sup>


This repository contains the `R` code (r-package folder) and the Java code 
(java-api folder) that provides the interface to R<sup>5</sup>. Soon, this
could also become a `python` library. 


## Installation

To use `r5r`, you need to have [Java SE Development Kit 11.0.8](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html) 
installed on your computer. No worries, you don't have to pay for it.


```R
# soon on CRAN

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
See a detailed demonstration of `r5r` in this intro Vignette (*soon*). To illustrate
functionality, the package includes a small sample data set of the public transport
and Open Street Map networks of Porto Alegre (Brazil). Three steps are required to 
use `r5r`, as follows.

```R
# 1) build transport network, pointing to the path where OSM and GTFS data are stored
path <- system.file("extdata", package = "r5r")
r5_core <- setup_r5(data_path = path)

# 2) load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))

# 3) run R5 to calculate a travel time matrix
df <- travel_time_matrix( r5_core = r5_core,
                          origins = points,
                          destinations = points,
                          trip_date = "2019-05-20",
                          departure_time = "14:00:00",
                          direct_modes = c("WALK", "BICYCLE", "CAR"),
                          transit_modes = "BUS",
                          max_street_time = 300L,
                          max_trip_duration = 3600L
                         )
```



#### **Related R packages**

There is a growing number of `R` packages with functionalities for transport
routing, analysis and planning more broadly. Here are few of theses packages.

- [dodgr](https://github.com/ATFutures/dodgr): Distances on Directed Graphs in R
- [gtfs-router](https://github.com/ATFutures/gtfs-router): R package for routing with GTFS data
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

* Saraiva et al., (2020) **r5r: Rapid realistic routing on multimodal transport networks with R5**. GitHub repository - https://github.com/ipeaGIT/r5r
