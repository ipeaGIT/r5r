FROM rocker/geospatial

COPY r-package r5r

RUN install2.r checkmate data.table jdx rJava sf sfheaders akima covr knitr mapview rmarkdown testthat

RUN R CMD INSTALL r5r

RUN rm -rf r5r