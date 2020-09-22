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




# estimate travel time matrix
travel_time_matrix(r5r_core,
                         origins = points,
                         destinations = points,
                         mode,
                         departure_datetime,
                         max_walk_dist,
                         max_trip_duration
                          # , time_window= 60
                          # , percentiles =  c(50, 50)
                         )

head(ttm)




