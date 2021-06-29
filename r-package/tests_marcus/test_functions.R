library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

access <- accessibility(r5r_core,
                        origins = points,
                        destinations = points,
                        opportunities_colname = "schools",
                        mode = "WALK",
                        cutoffs = c(25, 30),
                        max_trip_duration = 30,
                        verbose = FALSE)

ttm <- travel_time_matrix(r5r_core, origins = points,
                          destinations = points,
                          mode = c("BICYCLE"),
                          max_trip_duration = 30,
                          max_walk_dist = 800,
                          verbose = FALSE)

dit <- detailed_itineraries(r5r_core,
                            origins =points[1047, ],
                          destinations = points[590, ],
                          mode = c("WALK"),
                          max_trip_duration = 60,
                          max_walk_dist = 800,
                          max_bike_dist = 800,
                          verbose = FALSE)
mapview::mapview(dit)
mapview::mapview(points, xcol="lon", ycol="lat", crs = 4326)
