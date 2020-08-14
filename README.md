
# r5r


r5r is a package that aims to make it easy to use the [R<sup>5</sup> routing engine](https://github.com/conveyal/r5) from R.

This repository contains the R code (r-package folder) and the Java code (java-api folder) that provides the interface to R<sup>5</sup>.

## Installation R (soon on CRAN)

```R
  utils::remove.packages('geobr')
  devtools::install_github("ipeaGIT/r5r", subdir = "r-package")
  library(r5r)
```

