library(sf)
library(data.table)
library(magrittr)
library(future.apply)
library(roxygen2)
library(devtools)
library(usethis)
library(testthat)
library(profvis)
library(mapview)
library(Rcpp)
library(gtfs2gps)

# Update documentation
devtools::document(pkg = ".")


# calculate Distance between successive points
new_stoptimes[ , dist := geosphere::distGeo(matrix(c(shape_pt_lon, shape_pt_lat), ncol = 2),
                                            matrix(c(data.table::shift(shape_pt_lon, type="lead"), data.table::shift(shape_pt_lat, type="lead")), ncol = 2))/1000]


poa <- read_gtfs(system.file("extdata/poa.zip", package="gtfs2gps"))


poa1 <- filter_day_period(poa, period_start = "10:00", period_end = "18:00")

poa2 <- gtfs2gps(poa1, cores=1)



##### INPUT  ------------------------
  # normal
  gtfsn <- './inst/extdata/poa.zip'
  # freq based
  gtfsf <- './inst/extdata/saopaulo.zip'

emtu <- "R:/Dropbox/bases_de_dados/GTFS/SP GTFS/GTFS EMTU_20190815.zip"
  
  
##### TESTS normal fun ------------------------
  # normal data
  system.time(  normal <- gtfs2gps_dt_parallel2(emtu) ) # 61.55  secs

  # freq data
  system.time(  normfreq <- gtfs2gps_dt_parallel(gtfsf) ) # 130.50 secs
  
  
##### Coverage ------------------------

    
  
#  ERROR in shapeid 52936
  
  library(gtfs2gps)
  library(covr)
  library(testthat)
  
  function_coverage(fun=gtfs2gps::filter_day_period, test_file("tests/testthat/test_filter_day_period.R"))
  function_coverage(fun=gtfs2gps::test_gtfs_freq, test_file("./tests/testthat/test_test_gtfs_freq.R"))
  function_coverage(fun=gtfs2gps::gps_as_sflinestring, test_file("./tests/testthat/test_gps_as_sflinestring.R"))
  function_coverage(fun=gtfs2gps::gps_as_sfpoints, test_file("./tests/testthat/test_gps_as_sfpoints.R"))
  
  covr::package_coverage(path = ".", type = "tests")
  
##### Profiling function ------------------------
p <-   profvis( update_newstoptimes("T2-1@1#2146") )

p <-   profvis( b <- corefun("T2-1") )

















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





