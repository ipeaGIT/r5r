# allocate RAM memory to Java
options(java.parameters = "-Xmx2G")

# 1) build transport network, pointing to the path where OSM and GTFS data are stored
library(r5r)
library(arrow)
library(dplyr)


path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = path, verbose = FALSE)

# 2) load origin/destination points and set arguments
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))
mode <- c("WALK", "TRANSIT")
max_walk_time <- 30   # minutes
max_trip_duration <- 60 # minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

# 3.1) calculate a travel time matrix
ttm <- travel_time_matrix(r5r_core = r5r_core,
                          origins = points,
                          destinations = points,
                          mode = mode,
                          departure_datetime = departure_datetime,
                          max_walk_time = max_walk_time,
                          max_trip_duration = max_trip_duration,
                          output_dir = './aaaa')



csv_files <- list.files(path = './aaaa', full.names = TRUE)

# Define the dataset
DS <- arrow::open_csv_dataset(sources = csv_files)

# Create a scanner
O <- Scanner$create(DS)

# Load it as Arrow Table in memory
AT <- SO$ToTable()


# prep land use data
jobs_df <- select(points, c('id', 'jobs', 'healthcare'))

# merge jobs
AT <- left_join(AT, jobs_df, by = c('to_id' = 'id'))

head(AT) |> collect()

# calculate cumulative access in less than 20 min.
access_df <- AT |>
              filter(travel_time_p50 <= 20) |>
              group_by(from_id) |>
              summarise(access = sum(jobs)) |>
              collect()

head(access_df)


# calculate access to closest healthcare facility
access_df2 <- AT |>
  filter(healthcare > 0) |>
  group_by(from_id) |>
  summarise(access = min(jobs)) |>
  collect()

head(access_df2)

