
# r5r

**r5r** is an R package for rapid realistic routing on multimodal transport 
networks. **r5r** is an R wrapper of R<sup>5</sup>, the [Rapid Realistic Routing on Real-world and Reimagined networks](https://github.com/conveyal/r5).

This repository contains the R code (r-package folder) and the Java code (java-api folder) that provides the interface to R<sup>5</sup>.


## Installation R

```R
# soon on CRAN

devtools::install_github("ipeaGIT/r5r", subdir = "r-package")
library(r5r)
```






#### **Related R packages**

There is a growing number of `R` packages with functionalities for transport
routing, analysis and planning more broadly. Here are few of theses packages.

- [dodgr](https://github.com/ATFutures/dodgr): Distances on Directed Graphs in R
- [gtfs-router](https://github.com/ATFutures/gtfs-router): R package for routing with GTFS data
- [hereR](https://github.com/munterfinger/hereR): an R interface to the HERE REST APIs 
- [opentripplanner](https://github.com/ropensci/opentripplanner): OpenTripPlanner for R
- [stplanr](https://github.com/ropensci/stplanr): sustainable transport planning with R

The **r5r** package is particularly focused on fast multimodal transport routing 
and computations of of travel time matrices.


has a few advantages when compared to these  other packages, including for example:
- A same syntax structure across all functions, making the package very easy and intuitive to use
- Access to a wider range of official spatial data sets, such as states and municipalities, but also macro-, meso- and micro-regions, weighting areas, census tracts, urbanized areas, etc
- Access to shapefiles with updated geometries for various years
- Harmonized attributes and geographic projections across geographies and years



-----

# Credits <img align="right" src="r-package/man/figures/ipea_logo.png" alt="ipea" width="300">

The [R<sup>5</sup> routing engine](https://github.com/conveyal/r5) is developed at [Conveyal](https://www.conveyal.com/) with contributions from several people. TheR package **r5r** is developed by a team at the Institute for Applied Economic Research (Ipea), Brazil. If you use this package in research publications, we please cite it as:

