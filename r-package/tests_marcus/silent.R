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
origins <- destinations <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

# input
direct_modes <- "WALK"
transit_modes <-"BUS"
departure_time <- "14:00:00"
trip_date <- "2019-03-20"
street_time = 15L
max_street_time = 30L
max_trip_duration = 300L

r5_core$silentMode()
r5_core$verboseMode()

tictoc::tic("max")
df <- travel_time_matrix( r5r_core = r5_core,
                          origins = origins,
                          destinations = destinations,
                          trip_date = trip_date,
                          departure_time = departure_time,
                          mode =  direct_modes,
                          max_street_time = max_street_time,
                          max_trip_duration = max_trip_duration
)
tictoc::toc()
