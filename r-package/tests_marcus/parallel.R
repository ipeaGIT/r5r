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
options(java.parameters = "-Xmx16G")

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

df %>% head(100)

