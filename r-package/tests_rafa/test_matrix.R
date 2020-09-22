library(r5r)

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

mode <- c("WALK", "TRANSIT")
max_walk_dist <- Inf
max_trip_duration <- 120L
departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                format = "%d-%m-%Y %H:%M:%S")

time_window <-  1
percentiles <-  c(5, 80)


# estimate travel time matrix
ttm <- travel_time_matrix(r5r_core,
                         origins = points,
                         destinations = points,
                         mode,
                         departure_datetime,
                         max_walk_dist,
                         max_trip_duration
                         , time_window= time_window
                         , percentiles = percentiles
                         )

head(ttm)





library(r5r)

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_obj <- setup_r5(data_path = data_path)

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:5,]

mode <- c("WALK", "TRANSIT")
max_walk_dist <- Inf
max_trip_duration <- 120L
departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S",
                                 tz = "America/Sao_Paulo")

# estimate travel time matrix
ttm <- travel_time_matrix(r5r_obj,
                          origins = points,
                          destinations = points,
                          mode,
                          departure_datetime,
                          max_walk_dist,
                          max_trip_duration)

head(ttm)
