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
library(ggplot2)
library(checkmate)
library(geobr)
library(gtfs2gps)
library(mapview)
mapviewOptions(platform = 'leafgl')




##### INPUT  ------------------------




# build transport network
poa <- system.file("extdata/poa", package = "r5r")
spo <- system.file("extdata/spo", package = "r5r")

# r5r::download_r5(force_update = T)
r5r_core <- setup_r5(data_path = path, verbose = F)

# load origin/destination points
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

# remove files
# file.remove( file.path(path, "network.dat") )
# file.remove( file.path(.libPaths()[1], "r5r", "jar", "r5r_v4.9.0.jar") )
# list.files(path)
# list.files(file.path(.libPaths()[1], "r5r", "jar"))



library(r5r)
library(data.table)


# function
get_all_od_combinations <- function(origins, destinations){

        # all possible id combinations
        base <- expand.grid(origins$id, destinations$id)

        # rename df
        setDT(base)
        setnames(base, 'Var1', 'idorig')
        setnames(base, 'Var2', 'iddest')

        # bring spatial coordinates from origin and destination
        base[origins, on=c('idorig'='id'), c('lon_orig', 'lat_orig') := list(i.lon, i.lat)]
        base[destinations, on=c('iddest'='id'), c('lon_dest', 'lat_dest') := list(i.lon, i.lat)]

        return(base)
        }

# example
origins <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[1:800,]
destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[400:1200,]

df <- get_all_od_combinations(origins, destinations)

##### TESTS street_network_to_sf ------------------------

gtfs_shapes <- gtfs2gps::read_gtfs( system.file("extdata/spo/spo.zip", package = "r5r") ) %>%
        gtfs2gps::gtfs_shapes_as_sf()



spo <- system.file("extdata/spo", package = "r5r")

r5r_core <- setup_r5(data_path = spo, verbose = F)

street_net <- street_network_to_sf(r5r_core)


mapview(street_net$edges ) + street_net$vertices + gtfs_shapes

head(street_net$edges)





##### TESTS detailed_itineraries ------------------------

origins <- points
destinations <- points

 mode = c("WALK", "BUS")
 max_walk_dist <- 10000
 departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                  format = "%d-%m-%Y %H:%M:%S")


system.time(
df <- detailed_itineraries(r5r_core,
                           origins,
                           destinations,
                           departure_datetime,
                           max_walk_dist,
                           mode,
                           shortest_path = T,
                           n_threads= Inf)
)













##### TESTS travel_time_matrix ------------------------
options(java.parameters = "-Xmx16G")

# input
origins <- destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[c(1,100,300,500),]

# input
origins = points
destinations = points
mode = c('WALK', 'TRANSIT')
max_trip_duration = 600L
departure_datetime = as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")


 system.time(
 df <- travel_time_matrix( r5r_core = r5r_core,
                           origins = origins,
                           destinations = destinations,
                           mode = mode,
                          # transit_modes = transit_modes,
                           max_trip_duration = max_trip_duration,
                          verbose = F
                           )
)

 head(tt)
 nrow(tt)

 1474469/ 143.64
 245480 /32.74
 523074 / 46.96






 ##### TESTS select_mode ------------------------

 # mode = c('car')
 mode = c('BUS') !!!!!!!!!!!!!!!!!!!!!
         # mode = c('BICYCLE')  !!!!!!!!!!!!!!!!!!!!!
         mode <- c('BICYCLE', 'BUS')
 mode <- c('BICYCLE', 'car') ### WALK
 mode <- c('car', 'BUS')
 mode <- c('car', 'BUS', 'walk', 'BICYCLE')

 bu kike === walk
 se só tem direct mode, outros vazios

 mode_list <- select_mode(mode)





##### HEX sticker ------------------------

# load origin/destination points
 points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
 points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')
 points_sf2 <- sf::st_as_sf(points, coords = c("lon", "lat"))

 data_path <- system.file("extdata/poa", package = "r5r")
 points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
 a <-  sf::st_as_sf(points, coords = c("lon", "lat"))



 box <- st_as_sfc( st_bbox(points_sf), crs=st_crs(points_sf) )
 box <- st_sf(box)
 st_crs(box) <- 4674

# get hex
 hex_ids <- h3jsr::polyfill(box, res = 7, simple = FALSE)

 # pass the h3 ids to return the hexagonal grid
 hex_grid <- unlist(hex_ids$h3_polyfillers) %>%
         h3jsr::h3_to_polygon(simple = FALSE) %>%
         rename(id_hex = h3_address) %>%
         st_sf()

 selected_points <- subset(points_sf,
                           id %in% c('89a90129d97ffff',
                                     '89a90129977ffff',
                                     '89a90128a83ffff'))

 origin <- subset(points_sf, id == '89a90129977ffff')
 destinations <- subset(points_sf, id %like% c('89a901299'))

#  selected_points2 <- subset(points_sf,
#                            id %like% c('89a901299'))
#
# mapview(hex_grid) + selected_points + selected_points2
#
#
#
# # 89a90129d97ffff >> para direita
# # 89a90129977ffff ?? pra baixo
# # 89a90128a83ffff ?? nordeste







# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)


# input
mode = c('WALK', 'TRANSIT')
departure_time <- "14:00:00"
trip_date <- "2019-03-15"
max_street_time <- 30000L

df <- detailed_itineraries(r5r_core,
                    origins = origin,
                    destinations = destinations,
                    mode = 'WALK',
                    trip_date,
                    departure_time,
                    max_street_time)





# load origin/destination points
street_net <- street_network_to_sf(r5r_core)
mapview(street_net) + points_sf




 # plot
 ggplot() +
         geom_sf(data = df, color='gray1', alpha=1) +
         theme_void()



##### Coverage ------------------------

 Sys.setenv(NOT_CRAN = "true")


# each function separately
covr::function_coverage(fun=r5r::download_r5, test_file("tests/testthat/test-download_r5.R"))
covr::function_coverage(fun=r5r::setup_r5, test_file("tests/testthat/test-setup_r5.R"))
covr::function_coverage(fun=r5r::travel_time_matrix, test_file("tests/testthat/test-travel_time_matrix.R"))
covr::function_coverage(fun=r5r::street_network_to_sf, test_file("tests/testthat/test-street_network_to_sf.R"))
covr::function_coverage(fun=r5r::detailed_itineraries, test_file("tests/testthat/test-detailed_itineraries.R"))

covr::function_coverage(fun=r5r::set_max_walk_distance, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::posix_to_string, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::assert_points_input, test_file("tests/testthat/test-utils.R"))


covr::function_coverage(fun=r5r::select_mode, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_verbose, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_n_threads, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_speed, test_file("tests/testthat/test-utils.R"))

# nocov start

# nocov end

# the whole package
Sys.setenv(NOT_CRAN = "true")
r5r_cov <- covr::package_coverage(path = ".", type = "tests")
r5r_cov

x <- as.data.frame(r5r_cov)
covr::codecov( coverage = r5r_cov, token ='2a7013e9-6562-4011-beb9-168e922c4c84' )


##### Profiling function ------------------------
# p <-   profvis( update_newstoptimes("T2-1@1#2146") )
#
# p <-   profvis( b <- corefun("T2-1") )





# checks spelling
library(spelling)
devtools::spell_check(pkg = ".", vignettes = TRUE, use_wordlist = TRUE)

# Update documentation
devtools::document(pkg = ".")


# Write package manual.pdf
system("R CMD Rd2pdf --title=Package gtfs2gps --output=./gtfs2gps/manual.pdf")
# system("R CMD Rd2pdf gtfs2gps")




1. Failure: detailed_itineraries output is correct (@test-detailed_itineraries.R#182)
2. Failure: detailed_itineraries output is correct (@test-detailed_itineraries.R#202)

pdflatex



path <- 'E:/Dropbox/other_projects/0_jean_capability/opentripplanner/otp_got'
options(java.parameters = "-Xmx16G")
r5r_core <- setup_r5(path)

### CMD Check ----------------
# Check package errors
Sys.setenv(NOT_CRAN = "false")
devtools::check(pkg = ".",  cran = FALSE, env_vars = c(NOT_CRAN = "true"))
devtools::check(pkg = ".",  cran = TRUE, env_vars = c(NOT_CRAN = "false"))

devtools::check_win_release(pkg = ".")

beepr::beep()






# build binary
system("R CMD build . --resave-data") # build tar.gz










cities <- geobr::read_municipal_seat()
cities <- subset(cities, abbrev_state == 'SP')
sp <- subset(cities, name_muni  == 'São Paulo')


# allocate RAM memory to Java
options(java.parameters = "-Xmx20G")

r5r_core <- r5r::setup_r5(data_path = 'E:/Dropbox/bases_de_dados/OSM/brasil/t')

set.seed(1)
orig <- cities[sample(1:645, 200),]
dit <- r5r::detailed_itineraries(r5r_core,
                                 origins = orig,
                                 destinations = sp,
                                 mode='car',
                                 max_trip_duration = 600L, shortest_path = T)




head(dit)
plot(dit)
beepr:beep()

ggplot()+
        geom_sf(data=dit, color='black', alpha=.3)

# Run to build the website
pkgdown::build_site()
