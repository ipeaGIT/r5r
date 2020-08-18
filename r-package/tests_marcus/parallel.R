options(java.parameters = "-Xmx10G")

library(r5r)
library(sf)


# build transport network
path <- system.file("extdata", package = "r5r")
list.files(path)
list.files(file.path(.libPaths()[1], "r5r", "jar"))



# r5r::download_r5()

r5_core <- setup_r5(data_path = path)

##### TESTS travel_time_matrix ------------------------

# input
origins <- destinations <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))

# input
direct_modes <- c("WALK", "BICYCLE", "CAR")
transit_modes <-"BUS"
departure_time <- "14:00:00"
trip_date <- "2019-03-20"
street_time = 15L
max_street_time = 30L
max_trip_duration = 300L

r5_core$setNumberOfThreadsToMax()

tictoc::tic("max")
df <- travel_time_matrix( r5_core = r5_core,
                          origins = origins,
                          destinations = destinations,
                          trip_date = trip_date,
                          departure_time = departure_time,
                          direct_modes = direct_modes,
                          transit_modes = transit_modes,
                          max_street_time = max_street_time,
                          max_trip_duration = max_trip_duration
)
tictoc::toc(log = TRUE, quiet = TRUE)

for (x in 1:12) {
  r5_core$setNumberOfThreads(as.integer(x))

  tictoc::tic(x)

  df <- travel_time_matrix( r5_core = r5_core,
                            origins = origins,
                            destinations = destinations,
                            trip_date = trip_date,
                            departure_time = departure_time,
                            direct_modes = direct_modes,
                            transit_modes = transit_modes,
                            max_street_time = max_street_time,
                            max_trip_duration = max_trip_duration)

  tictoc::toc(log = TRUE, quiet = TRUE)
}

log.txt <- tictoc::tic.log(format = TRUE)
log.lst <-tictoc::tic.log(format = FALSE)
unlist(lapply(log.lst, function(x) x$toc - x$tic))
writeLines(unlist(log.txt))

# on common thread pool : 61.554 sec elapsed
# on custom thread pool, number of threads = number of processor cores (12): 68.929 sec elapsed
# on custom thread pool, number of threads = 6: 84.92 sec elapsed
# on custom thread pool, number of threads = 2: 150.749 sec elapsed


df %>% head(100)

r5_core$getNumberOfThreads()
r5_core$setNumberOfThreads(12L)
r5_core$setNumberOfThreads(6L)
r5_core$setNumberOfThreads(2L)

##### TESTS multiple itinerarires ------------------------

trip_date <- "2019-03-17"
departure_time <- "14:00:00"
street_time = 15L
direct_modes <- c("WALK", "BICYCLE", "CAR")
transit_modes <-"BUS"
max_street_time = 30

origins = dplyr::sample_n(origins, 1000, replace = TRUE)
destinations = dplyr::sample_n(destinations, 1000, replace = TRUE)

trip_requests <- data.frame(id = 1:1000,
                            fromLat = origins$lat,
                            fromLon = origins$lon,
                            toLat = destinations$lat,
                            toLon = destinations$lon )

# trip_requests2 <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

r5_core$setNumberOfThreadsToMax()

tictoc::tic("max")
trips <- multiple_detailed_itineraries( r5_core,
                                        trip_requests,
                                        trip_date = trip_date,
                                        departure_time = departure_time,
                                        direct_modes = direct_modes,
                                        transit_modes = transit_modes,
                                        max_street_time = max_street_time)
tictoc::toc(log = TRUE, quiet = TRUE)

for (x in 1:12) {
  r5_core$setNumberOfThreads(as.integer(x))

  tictoc::tic(x)

  trips <- multiple_detailed_itineraries( r5_core,
                                          trip_requests,
                                          trip_date = trip_date,
                                          departure_time = departure_time,
                                          direct_modes = direct_modes,
                                          transit_modes = transit_modes,
                                          max_street_time = max_street_time)

  tictoc::toc(log = TRUE, quiet = TRUE)
}

log.txt <- tictoc::tic.log(format = TRUE)
log.lst <-tictoc::tic.log(format = FALSE)
unlist(lapply(log.lst, function(x) x$toc - x$tic))
writeLines(unlist(log.txt))

# on common thread pool : 2.624 sec elapsed
# on custom thread pool, number of threads = number of processor cores (12): 80.79 sec elapsed
# on custom thread pool, number of threads = 6: 88.962 sec elapsed
# on custom thread pool, number of threads = 2: 137.23 sec elapsed
# on custom thread pool, number of threads = 1: 238.58 sec elapsed

r5_core$getNumberOfThreads()
r5_core$setNumberOfThreads(12L)
r5_core$setNumberOfThreads(6L)
r5_core$setNumberOfThreads(2L)
r5_core$setNumberOfThreads(1L)

sink()
