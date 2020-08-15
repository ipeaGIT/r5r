library(r5r)
library(sf)
library(data.table)
library(magrittr)
library(roxygen2)
library(devtools)
library(usethis)
library(testthat)
library(profvis)
library(dplyr)
library(mapview)
library(covr)



# Update documentation
devtools::document(pkg = ".")


##### INPUT  ------------------------


# build transport network
path <- system.file("extdata", package = "r5r")
r5_core <- setup_r5(data_path = path)

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))


# input
fromLat <- points[1,]$lat
fromLon <- points[1,]$lon
toLat <- points[100,]$lat
toLon <- points[100,]$lon
trip_date <- "2019-05-20"
departure_time <- "14:00:00"
street_time = 15L
direct_modes <- c("WALK", "BICYCLE", "CAR")
transit_modes <-"BUS"
max_street_time = 30L




##### TESTS detailed_itineraries ------------------------



trip <- detailed_itineraries( fromLat = fromLat,
                              fromLon = fromLon,
                              toLat = toLat,
                              toLon = toLon,
                              r5_core = r5_core,
                              trip_date = trip_date,
                              departure_time = departure_time,
                              direct_modes = direct_modes,
                              transit_modes = transit_modes,
                              max_street_time = max_street_time,
                              filter_paths = F)




##### TESTS travel_time_matrix ------------------------

 # input
origins <- destinations <- points

 trip_date <- "2019-05-20"
 departure_time <- "14:00:00"
 street_time = 15L
 direct_modes <- c("WALK", "BICYCLE", "CAR")
 transit_modes <-"BUS"
 max_street_time = 30L
 max_trip_duration = 300L


 system.time(
 tt <- travel_time_matrix( r5_core,
                     origins,
                     destinations,
                     direct_modes,
                     transit_modes,
                     trip_date,
                     departure_time,
                     max_street_time,
                     max_trip_duration)
 )


 head(tt)
 nrow(tt)

 1474469/ 143.64


##### Coverage ------------------------

# each function separately
function_coverage(fun=r5r::download_r5, test_file("tests/testthat/test-download_r5.R"))
function_coverage(fun=r5r::setup_r5, test_file("tests/testthat/test-setup_r5.R"))

# the whole package
covr::package_coverage(path = ".", type = "tests")




##### Profiling function ------------------------
# p <-   profvis( update_newstoptimes("T2-1@1#2146") )
#
# p <-   profvis( b <- corefun("T2-1") )





### update package documentation ----------------
# http://r-pkgs.had.co.nz/release.html#release-check


rm(list = ls())

library(roxygen2)
library(devtools)
library(usethis)




setwd("R:/Dropbox/git/gtfs2gps")

# update `NEWS.md` file
# update `DESCRIPTION` file
# update ``cran-comments.md` file


# checks spelling
library(spelling)
devtools::spell_check(pkg = ".", vignettes = TRUE, use_wordlist = TRUE)

# Update documentation
devtools::document(pkg = ".")


# Write package manual.pdf
system("R CMD Rd2pdf --title=Package gtfs2gps --output=./gtfs2gps/manual.pdf")
# system("R CMD Rd2pdf gtfs2gps")




# Ignore these files/folders when building the package (but keep them on github)
setwd("R:/Dropbox/git_projects/gtfs2gps")


usethis::use_build_ignore("test")
usethis::use_build_ignore("prep_data")
usethis::use_build_ignore("manual.pdf")

# script da base de dados e a propria base armazenada localmente, mas que eh muito grande para o CRAN
usethis::use_build_ignore("brazil_2010.R")
usethis::use_build_ignore("brazil_2010.RData")
usethis::use_build_ignore("brazil_2010.Rd")

# Vignette que ainda nao esta pronta
usethis::use_build_ignore("  Georeferencing-gain.R")
usethis::use_build_ignore("  Georeferencing-gain.Rmd")

# temp files
usethis::use_build_ignore("crosswalk_pre.R")



### CMD Check ----------------
# Check package errors
Sys.setenv(NOT_CRAN = "false")
devtools::check(pkg = ".",  cran = TRUE)
beepr::beep()


# build binary
system("R CMD build gtfs2gps --resave-data") # build tar.gz
# devtools::build(pkg = "gtfs2gps", path=".", binary = TRUE, manual=TRUE)

# Check package errors
# devtools::check("gtfs2gps")
system("R CMD check gtfs2gps_1.0.tar.gz")
system("R CMD check --as-cran gtfs2gps_1.0-0.tar.gz")





