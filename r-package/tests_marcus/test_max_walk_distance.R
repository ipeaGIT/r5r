data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

origins <- points
destinations <- points[15:1,]
mode = c("WALK", "BUS")
departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")
max_walk_dist <- 31

max_street_time <- set_max_street_time(max_walk_dist, 3.6, 120L)

df <- detailed_itineraries(r5r_core,
                           origins,
                           destinations,
                           mode,
                           departure_datetime,
                           max_walk_dist)
