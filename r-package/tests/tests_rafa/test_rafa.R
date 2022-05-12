# devtools::install_github("ipeaGIT/r5r", subdir = "r-package", force=T)
options(java.parameters = '-Xmx10G')
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
library(tictoc)
library(mapview)
mapviewOptions(platform = 'leafgl')


# utils::remove.packages('r5r')
# devtools::install_github("ipeaGIT/r5r", subdir = "r-package", ref = 'detach_r5_codebase')
# library(r5r)



##### INPUT  ------------------------

utils::remove.packages('r5r')
devtools::install_github("ipeaGIT/r5r", subdir = "r-package")



# build transport network
path <- system.file("extdata/poa", package = "r5r")
list.files(path)
spo <- system.file("extdata/spo", package = "r5r")

# r5r::download_r5(force_update = T)
r5r::download_r5()
r5r_core <- setup_r5(data_path = path, verbose = F)

# load origin/destination points
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

# remove files
# file.remove( file.path(path, "network.dat") )
# file.remove( file.path(.libPaths()[1], "r5r", "jar", "r5r_v4.9.0.jar") )
# list.files(path)
# list.files(file.path(.libPaths()[1], "r5r", "jar"))


############## get_all_od_combinations ------------------------------

library(r5r)
library(data.table)

points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))

origins = destinations = points

# function
get_all_od_combinations <- function(origins, destinations){

        # cross join to get all possible id combinations
        base <- CJ(origins$id, destinations$id, unique = TRUE)

        # rename df
        setnames(base, 'V1', 'id_orig')
        setnames(base, 'V2', 'id_dest')

        # bring spatial coordinates from origin and destination
        base[origins, on=c('id_orig'='id'), c('lon_orig', 'lat_orig') := list(i.lon, i.lat)]
        base[destinations, on=c('id_dest'='id'), c('lon_dest', 'lat_dest') := list(i.lon, i.lat)]

        return(base)
        }

# example
origins <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[1:800,]
destinations <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[400:1200,]

df <- get_all_od_combinations(origins, destinations)





##### TESTS isochrone ------------------------

library(r5r)
library(ggplot2)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/point of interest
origin <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[500,]

departure_datetime <- as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

# estimate travel time matrix
iso <- isochrone(r5r_core,
                 origin = origin,
                 mode = c("WALK"),
                 departure_datetime = departure_datetime,
                 cutoffs = c(0, 15, 30, 45, 60, 75, 90, 120),
                 max_walk_dist = Inf)


network <- street_network_to_sf(r5r_core)
road_network = network[[2]]


ggplot() +
        geom_sf(data=road_network, color='gray60') +
        geom_sf(data=iso, aes(color=isocrhones), alpha=.2) +
        geom_point(data=origin, color='red', aes(x=lon, y=lat)) +
        theme_minimal()


##### set_road_speed ------------------------
# https://github.com/ipeaGIT/r5r/issues/187

library(jsonlite)
library(data.table)
library(r5r)

# build network
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[c(1:100, 500:600),]
path <- system.file("extdata/poa", package = "r5r")

path <- 'R:/Dropbox/git/r5r/r-package/inst/extdata/poa'
r5r_core <- setup_r5(data_path = path, verbose = F, overwrite = T)

tt <- r5r::travel_time_matrix(r5r_core = r5r_core, origins = points,destinations = points, mode = 'car')
# fwrite(tt, 'tt_test.csv')

tt1 <- fread('tt_default.csv')

df=merge(tt, tt1, by=c('from_id','to_id'))
df[, d := travel_time.x - travel_time.y]
summary(df$d)






# cria json so com vars de input
# criar r5r_core, depois atualiza velocidades

# default config
speeds_js <- r5r_core$defaultBuildConfig()
cat(speeds_js)


a <- sub('"defaultSpeed" ://d+' ,'aaa', speeds_js)
cat(a)


# replace primary speed
speeds_js2 <- gsub('"primary" : 45', '"primary" : 111', speeds_js)


cat(speeds_js2)

speeds_df <- fromJSON(speeds_js, simplifyDataFrame = T)



x <- toJSON(speeds_df)
cat(x)





set_road_speed <- function( # path,
                            motorway = NULL
                           , motorway_link = NULL
                           , trunk = NULL
                           , trunk_link = NULL
                           , primary = NULL
                           , primary_link = NULL
                           , secondary = NULL
                           , secondary_link = NULL
                           , tertiary = NULL
                           , tertiary_link = NULL
                           , living_street = NULL
                           , pedestrian = NULL
                           , residential = NULL
                           , unclassified = NULL
                           , service = NULL
                           , track = NULL
                           , road = NULL
                           , defaultSpeed = NULL){
speeds_df <- data.frame(
                  'motorway' =      ifelse(is.null(motorway), NA, motorway)
                , 'motorway_link' = ifelse(is.null(motorway_link), NA, motorway_link)
                , 'trunk' =         ifelse(is.null(trunk), NA, trunk)
                , 'trunk_link' =    ifelse(is.null(trunk_link), NA, trunk_link)
                , 'primary' =       ifelse(is.null(primary), NA, primary)
                , 'primary_link' =  ifelse(is.null(primary_link), NA, primary_link)
                , 'secondary' =     ifelse(is.null(secondary), NA, secondary)
                , 'secondary_link' =ifelse(is.null(secondary_link), NA, secondary_link)
                , 'tertiary' =      ifelse(is.null(tertiary), NA, tertiary)
                , 'tertiary_link' = ifelse(is.null(tertiary_link), NA, tertiary_link)
                , 'living_street' = ifelse(is.null(living_street), NA, living_street)
                , 'pedestrian' =     ifelse(is.null(pedestrian), NA, pedestrian)
                , 'residential' =   ifelse(is.null(residential), NA, residential)
                , 'unclassified' =  ifelse(is.null(unclassified), NA, unclassified)
                , 'service' =       ifelse(is.null(service), NA, service)
                , 'track' =         ifelse(is.null(track), NA, track)
                , 'road' =          ifelse(is.null(road), NA, road)
                , 'defaultSpeed' =  ifelse(is.null(defaultSpeed), NA, defaultSpeed))

# remove columns with missing value
speeds_df <- speeds_df[ , apply(speeds_df, 2, function(x) !any(is.na(x)))]

return(speeds_df)
}

speeds_df <- set_road_speed(primary = 666,
                            secondary = 666,
                            trunk = 666,
                            road = 666,
                            defaultSpeed = 666)


# retrieve default speed
dflt_speed <- speeds_df$defaultSpeed
speeds_df$defaultSpeed <- NULL

my_list <- list( speeds = list ( units = 'km/h',
                                 values= list(speeds_df),
                                 defaultSpeed = dflt_speed
                                 ) )

my_list <- jsonlite::toJSON(my_list, pretty = TRUE)

# remove brackets
my_list <- gsub("\\[|\\]", '', my_list)


write(my_list,file = paste0(path, '/build-config.json'))


# save json
jsonlite::write_json(my_list, path = 'build-config.json')

66666

speeds_js <- toJSON(speeds_df, pretty=TRUE)
cat(speeds_js)

# export json to path file
jsonlite::write_json(speeds_js, path = paste0('build-configsssss.json'))

}



cat(a)

speeds_df <- as.data.frame(fromJSON(a))
x <- toJSON(speeds_df, pretty=TRUE)
cat(x)

a <- jsonlite::read_json('build-config.json')
jsonlite::write_json(cat(a), path = 'build-config2.json')

writeLines(a,con  = 'build-config3.json')

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
library(r5r)

# set up
data_path <- system.file("extdata/spo", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# input
points <- read.csv(file.path(data_path, "spo_hexgrid.csv"))[1:5,]
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")

#' # estimate travel time matrix
ttm <- travel_time_matrix(r5r_core,
                   origins = points,
                   destinations = points,
                   mode = c("WALK", "TRANSIT"),
                   departure_datetime = departure_datetime,
                   max_walk_dist = Inf,
                   max_trip_duration = 120L)









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


##### downloads ------------------------
library(ggplot2)
library(dlstats)

x <- cran_stats(c('r5r', 'otpr', 'opentripplanner', 'gtfsrouter', 'flightsbr'))

 if (!is.null(x)) {
         head(x)
         ggplot(x, aes(end, downloads, group=package, color=package)) +
                 geom_line() + geom_point(aes(shape=package))
 }

library(data.table)
setDT(x)

x[, .(total = sum(downloads)) , by=package][order(total)]

x[ start > as.Date('2021-01-01'), .(total = sum(downloads)) , by=package][order(total)]

x[package=='flightsbr',]

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
covr::function_coverage(fun=r5r::detailed_itineraries, test_file("tests/testthat/test-detailed_itineraries.R"))

covr::function_coverage(fun=r5r::street_network_to_sf, test_file("tests/testthat/test-street_network_to_sf.R"))
covr::function_coverage(fun=r5r::transit_network_to_sf, test_file("tests/testthat/test-transit_network_to_sf.R"))




covr::function_coverage(fun=r5r::set_max_walk_distance, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::posix_to_string, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::assert_points_input, test_file("tests/testthat/test-utils.R"))

covr::function_coverage(fun=tobler_hiking, test_file("tests/testthat/test-elevation_utils.R"))
# covr::function_coverage(fun=apply_elevation, test_file("tests/testthat/test-elevation_utils.R"))


covr::function_coverage(fun=r5r::find_snap, test_file("tests/testthat/test-find_snap.R"))


covr::function_coverage(fun=r5r::select_mode, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_verbose, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_n_threads, test_file("tests/testthat/test-utils.R"))
covr::function_coverage(fun=r5r::set_speed, test_file("tests/testthat/test-utils.R"))

# nocov start

# nocov end

# the whole package
Sys.setenv(NOT_CRAN = "true")
r5r_cov2 <- covr::package_coverage(path = ".", type = "tests")
r5r_cov


x <- as.data.frame(r5r_cov)
covr::codecov( coverage = r5r_cov, token ='2a7013e9-6562-4011-beb9-168e922c4c84' )

Error (test-street_network_to_sf.R:14:3): street_network_to_sf - expected behavior
Error (test-detailed_itineraries.R:169:3): detailed_itineraries output is correct



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

# LOCAL
Sys.setenv(NOT_CRAN = "true")
devtools::check(pkg = ".",  cran = FALSE, env_vars = c(NOT_CRAN = "true"))

# CRAN
Sys.setenv(NOT_CRAN = "false")
devtools::check(pkg = ".",  cran = TRUE, env_vars = c(NOT_CRAN = "false"))

devtools::check_win_release(pkg = ".")

# devtools::check_win_oldrelease()
# devtools::check_win_devel()


beepr::beep()



tictoc::tic()
devtools::check(pkg = ".",  cran = TRUE, env_vars = c(NOT_CRAN = "false"))
tictoc::toc()





# build binary -----------------
system("R CMD build . --resave-data") # build tar.gz


mode_list
mode_list <- list('direct_modes' = "WALK",
                  'transit_mode' =  "",# "TRANSIT;TRAM;SUBWAY;RAIL;BUS;FERRY;CABLE_CAR;GONDOLA;FUNICULAR",
                  'access_mode'  = "WALK",
                  'egress_mode'  = "CAR")



### pkgdown: update website ----------------

# Run to build the website
pkgdown::build_site()



#### argentina buenos aires -----

options(java.parameters = "-Xmx20G")

library(r5r)
library(osmextract)

library(sf)
library(ggplot2)
library(here)
library(data.table)
library(magrittr)


# create subdirectories "data" and "img"
dir.create(here::here("data"))
        # dir.create(here::here("img"))


# get city boundaries
city <- 'Buenos Aires'
# city_code <- lookup_muni(name_muni = city)
# city_boundary <- read_municipality(code_muni = city_code$code_muni, simplified = F)


# define city center
city_center_df <- data.frame(id='center', lon=-43.182811, lat=-22.906906)
city_center_sf <- sfheaders::sfc_point(obj = city_center_df, x='lon', y='lat')
st_crs(city_center_sf) <- 4326

# get OSM data
city_match <- osmextract::oe_match("Buenos Aires", quiet = TRUE)

osmextract::oe_download(file_url = city_match$url,
                        file_size = city_match$file_size,
                        provider = 'a',
                        download_directory = here::here("data"), force_download = T)


# build routing network
r5r_core <- r5r::setup_r5(data_path = here::here("data"), verbose = FALSE)

# get street network as sf
street_network <- r5r::street_network_to_sf(r5r_core)

# drop network outside our buffer
edges_buff <- street_network$edges[buff, ] %>% st_intersection(., buff)
vertices_buff <- street_network$vertices[buff, ] %>% st_intersection(., buff)
city_boundary_buff <- st_intersection(city_boundary, buff)
plot(city_boundary_buff)

# add id to vertices
vertices_buff$id <- vertices_buff$index


# calculate travel times to city center
tt <- r5r::travel_time_matrix(r5r_core,
                              origins = vertices_buff,
                              destinations = city_center_df,
                              mode = 'walk')



library(tibble)
library(ggplot2)

df <- tribble(~option, ~modes,       ~time, ~cost,
              1,      'Walk',         50,   0,
              2,      'Bus',          35,   3,
              3,      'Bus + Bus',    29,   5,
              4,      'Subway',       20,   6,
              5,      'Bus + Subway', 15,   8)


# data.frame
df <- structure(list(option = c(1, 2, 3, 4, 5),
                     modes = c("Walk", "Bus","Bus + Bus", "Subway", "Bus + Subway"),
                     time = c(50, 35, 29, 20, 15),
                     cost = c(0, 3, 5, 6, 8)), class = "data.frame",
                row.names = c(NA, -5L))

# figure
ggplot(data=df, aes(x=cost, y=time, label = modes)) +
        geom_step(linetype = "dashed") +
        geom_point() +
        geom_text(color='gray30', hjust = -.2, nudge_x = 0.05, angle = 45) +
        # labs(y="Travel time in minutes", x="Travel cost in R$") +
        scale_x_continuous(name="Travel cost (R$)", breaks=seq(0,12,3)) +
        scale_y_continuous(name="Travel time (minutes)", breaks=seq(0,60,10)) +
        coord_cartesian(xlim = c(0,15), ylim = c(0, 60)) +
        theme_classic()


