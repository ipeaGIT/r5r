options(java.parameters = "-Xm10G")

devtools::load_all(".")
library(bench)

path <- system.file("extdata/poa", package = "r5r")
r5r_network <- setup_r5(data_path = path, verbose = FALSE)

# 2) load origin/destination points and set arguments
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
points <- rbind(points, points, points)
mode <- c("WALK", "TRANSIT")
max_walk_time <- 30   # minutes
max_trip_duration <- 60 # minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")


bench::mark(iterations = 3, check = FALSE,
            ttm <- travel_time_matrix(r5r_network = r5r_network,
                                      origins = points,
                                      destinations = points,
                                      mode = mode,
                                      departure_datetime = departure_datetime,
                                      max_walk_time = max_walk_time,
                                      max_trip_duration = max_trip_duration,
                                      progress = T)
)


# expression    min median `itr/sec` mem_alloc `gc/sec` n_itr  n_gc total_time result
# java_to_dt    29s  30.6s    0.0332     229MB   0.0774     3     7      1.51m <NULL>
#  arrow df   24.3s  25.2s    0.0389     570MB   0.0519     3     4      1.28m <NULL>
#arrow arrow  25.3s  26.7s    0.0363     569MB   0.0485     3     4      1.38m <NULL>



# # Define the dataset
# DS <- arrow::open_csv_dataset(sources = csv_files)
#
# # Create a scanner
# O <- Scanner$create(DS)
#
# # Load it as Arrow Table in memory
# AT <- SO$ToTable()
#
#
# # prep land use data
# jobs_df <- select(points, c('id', 'jobs', 'healthcare'))
#
# # merge jobs
# AT <- left_join(AT, jobs_df, by = c('to_id' = 'id'))
#
# head(AT) |> collect()
#
# # calculate cumulative access in less than 20 min.
# access_df <- AT |>
#               filter(travel_time_p50 <= 20) |>
#               group_by(from_id) |>
#               summarise(access = sum(jobs)) |>
#               collect()
#
# head(access_df)
#
#
# # calculate access to closest healthcare facility
# access_df2 <- AT |>
#   filter(healthcare > 0) |>
#   group_by(from_id) |>
#   summarise(access = min(jobs)) |>
#   collect()
#
# head(access_df2)
#
