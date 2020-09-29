library(r5r)
devtools::load_all()

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
poi <- read.csv(system.file("extdata/poa_points_of_interest.csv", package = "r5r"))

mode <- c("WALK", "TRANSIT")
max_walk_dist <- 1000
max_trip_duration <- 120L
departure_datetime <- lubridate::as_datetime("2019-03-20 14:00:00")




# estimate travel time matrix
tictoc::tic()
ttm <- travel_time_matrix(r5r_core,
                          origins = points,
                          destinations = points,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_dist = max_walk_dist,
                          max_trip_duration = max_trip_duration
                          , time_window= 60
                          # , percentiles = c(25, 50, 75, 100)
)
tictoc::toc()



head(ttm)




