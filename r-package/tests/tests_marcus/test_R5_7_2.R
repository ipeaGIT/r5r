# increase Java memory
options(java.parameters = "-Xmx2G")
library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r::download_r5(version = '7.2.0', force_update = TRUE)
r5r_core <- setup_r5(data_path, overwrite = TRUE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

ettm <- expanded_travel_time_matrix(
  r5r_core,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  time_window = 20,
  departure_datetime = departure_datetime,
  max_trip_duration = 60
)

head(ettm)
