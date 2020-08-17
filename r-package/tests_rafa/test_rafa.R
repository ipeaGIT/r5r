# devtools::install_github("ipeaGIT/r5r", subdir = "r-package", force=T)

library(r5r)
library(sf)
library(data.table)
library(magrittr)
library(roxygen2)
library(devtools)
library(usethis)
library(profvis)
library(dplyr)
library(mapview)
library(covr)
library(testthat)



# Update documentation
devtools::document(pkg = ".")


##### INPUT  ------------------------


# build transport network
path <- system.file("extdata", package = "r5r")
list.files(path)
list.files(file.path(.libPaths()[1], "r5r", "jar"))


# remove files
# file.remove( file.path(path, "network.dat") )
# file.remove( file.path(.libPaths()[1], "r5r", "jar", "r5r_v4.9.0.jar") )

# r5r::download_r5()

r5_core <- setup_r5(data_path = path)

create core


# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

jdx::convertToR(travel_times)
a <- read.table("C:/Users/user/Documents/R/win-library/4.0/r5r/extdata/network.dat")

a <- jdx::convertToR(a$V1)





##### TESTS detailed_itineraries ------------------------

# input
fromLat <- points[1,]$lat
fromLon <- points[1,]$lon
toLat <- points[5,]$lat
toLon <- points[5,]$lon
trip_date <- "2019-05-20"
departure_time <- "14:00:00"
street_time = 15L
direct_modes <- c("WALK", "BICYCLE", "CAR")
transit_modes <-"BUS"
max_street_time = 30L

system.time(
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
                              shortest_path = F) )








##### TESTS multiple detailed_itineraries ------------------------

trip_date <- "2019-03-17"
departure_time <- "14:00:00"
street_time = 15L
direct_modes <- c("WALK", "BICYCLE", "CAR")
transit_modes <-"BUS"
max_street_time = 30

trip_requests <- data.frame(id = 1:5,
                            fromLat = points[1:5,]$lat,
                            fromLon = points[1:5,]$lon,
                            toLat = points[1:5,]$lat,
                            toLon = points[1:5,]$lon )

trip_requests2 <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

system.time(
trips <- multiple_detailed_itineraries( r5_core,
                                        trip_requests,
                                        trip_date = trip_date,
                                        departure_time = departure_time,
                                        direct_modes = direct_modes,
                                        transit_modes = transit_modes,
                                        max_street_time = max_street_time
))






##### TESTS travel_time_matrix ------------------------
options(java.parameters = "-Xmx16G")

# input
origins <- destinations <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

 # input
 direct_modes <- c("WALK", "BICYCLE", "CAR")
 transit_modes <-"BUS"
 departure_time <- "14:00:00"
 trip_date <- "2019-05-20"
 street_time = 15L
 max_street_time = 30L
 max_trip_duration = 300L

 df <- travel_time_matrix( r5_core = r5_core,
                           origins = points,
                           destinations = points,
                           trip_date = trip_date,
                           departure_time = departure_time,
                           direct_modes = direct_modes,
                           transit_modes = transit_modes,
                           max_street_time = max_street_time,
                           max_trip_duration = max_trip_duration
                           )


 head(tt)
 nrow(tt)

 1474469/ 143.64
 245480 /32.74
 523074 / 46.96

##### Coverage ------------------------

# each function separately
covr::function_coverage(fun=r5r::download_r5, test_file("tests/testthat/test-download_r5.R"))
covr::function_coverage(fun=r5r::setup_r5, test_file("tests/testthat/test-setup_r5.R"))
covr::function_coverage(fun=r5r::travel_time_matrix, test_file("tests/testthat/test-travel_time_matrix.R"))

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




# setwd("R:/Dropbox/git/r5r/r-package")

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





