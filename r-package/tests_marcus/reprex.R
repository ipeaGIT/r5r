##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

library(r5r)

path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = path)


##### input
origins <- destinations <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))[1:100,]
trip_date = "2019-05-20"
departure_time = "14:00:00"
mode = c('WALK', 'TRANSIT')
max_street_time = 600L
max_trip_duration = 600L


##### Max threads
r5r_core$setNumberOfThreadsToMax()

system.time(
  df <- travel_time_matrix( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            trip_date = trip_date,
                            departure_time = departure_time,
                            mode = mode,
                            max_street_time = max_street_time,
                            max_trip_duration = max_trip_duration
  )
)

# user  system elapsed
# 12.982   0.864   1.647

##### Six threads
r5r_core$setNumberOfThreads(6L)

system.time(
  df2 <- travel_time_matrix( r5r_core = r5r_core,
                            origins = origins,
                            destinations = destinations,
                            trip_date = trip_date,
                            departure_time = departure_time,
                            mode = mode,
                            max_street_time = max_street_time,
                            max_trip_duration = max_trip_duration
  )
)

# user  system elapsed
# 5.794   1.278   1.460

##### Single thread (sequential)
r5r_core$setNumberOfThreads(1L)

system.time(
  df3 <- travel_time_matrix( r5r_core = r5r_core,
                             origins = origins,
                             destinations = destinations,
                             trip_date = trip_date,
                             departure_time = departure_time,
                             mode = mode,
                             max_street_time = max_street_time,
                             max_trip_duration = max_trip_duration
  )
)

# user  system elapsed
# 4.915   0.436   4.586
