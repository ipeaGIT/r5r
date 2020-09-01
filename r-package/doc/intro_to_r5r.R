## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ---- eval = FALSE------------------------------------------------------------
#  devtools::install_github("ipeaGIT/r5r", subdir = "r-package")
#

## ---- message = FALSE---------------------------------------------------------
library(r5r)
library(sf)
library(data.table)
library(ggplot2)
library(mapview)


## -----------------------------------------------------------------------------
data_path <- system.file("extdata", package = "r5r")
list.files(data_path)


## -----------------------------------------------------------------------------
points <- fread(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
points <- points[ c(sample(1:nrow(points), 10, replace=TRUE)), ]
head(points)


## ---- message = FALSE, eval = FALSE-------------------------------------------
#  options(java.parameters = "-Xmx2G")

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # Indicate the path where OSM and GTFS data are stored
#  r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)
#

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # calculate a travel time matrix
#  ttm <- travel_time_matrix(r5r_core = r5r_core,
#                            origins = points,
#                            destinations = points,
#                            departure_datetime = lubridate::as_datetime("2019-03-20 14:00:00",
#                                                                         tz = "America/Sao_Paulo"),
#                            mode = c("WALK", "TRANSIT"),
#                            max_walk_dist = 5000,
#                            max_trip_duration = 120,
#                            verbose = FALSE)
#
#  head(ttm)

## ----ttm head, echo = FALSE, message = FALSE----------------------------------
knitr::include_graphics(system.file("img", "vig_output_ttm.png", package="r5r"))

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # inputs
#  points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
#  origins <- points[10,]
#  destinations <- points[12,]
#  mode = c("WALK", "TRANSIT")
#  max_walk_dist <- 10000
#  departure_datetime <- lubridate::as_datetime("2019-03-20 14:00:00",
#                                               tz = "America/Sao_Paulo")
#
#  df <- detailed_itineraries(r5r_core = r5r_core,
#                             origins,
#                             destinations,
#                             mode,
#                             departure_datetime,
#                             max_walk_dist,
#                             shortest_path = FALSE,
#                             verbose = FALSE)
#
#  head(df)

## ----detailed head, echo = FALSE, message = FALSE-----------------------------
knitr::include_graphics(system.file("img", "vig_output_detailed.png", package="r5r"))

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  # extract OSM network
#  street_net <- street_network_to_sf(r5r_core)
#
#  # plot
#  ggplot() +
#    geom_sf(data = street_net$edges, color='gray85') +
#    geom_sf(data = df, aes(color=mode)) +
#    facet_wrap(.~option) +
#    theme_void()
#

## ----ggplot2 output, echo = FALSE, message = FALSE----------------------------
knitr::include_graphics(system.file("img", "vig_detailed_ggplot.png", package="r5r"))

## ---- message = FALSE, eval = FALSE-------------------------------------------
#  mapviewOptions(platform = 'leafgl')
#  mapview(df, zcol = 'option')
#

## ----mapview output, echo = FALSE, message = FALSE----------------------------
knitr::include_graphics(system.file("img", "vig_detailed_mapview.png", package="r5r"))

