data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

origins <- points
destinations <- points[15:1,]
mode = c("WALK", "BUS")
max_walk_dist <- 1000
departure_datetime <- as.POSIXct("13-03-2019 14:00:00",
                                format = "%d-%m-%Y %H:%M:%S")

df <- detailed_itineraries(r5r_core,
                          origins,
                          destinations,
                          mode,
                          departure_datetime,
                          max_walk_dist)

r5r_obj <- setup_r5(data_path, verbose = TRUE)
r5r_obj <- setup_r5(data_path, verbose = TRUE)
r5r_obj <- setup_r5(data_path, verbose = FALSE)
r5r_obj <- setup_r5(data_path, verbose = TRUE)


