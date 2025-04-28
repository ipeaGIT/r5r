devtools::load_all('.')
library(dplyr)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

# sample a few poits to make reprex faster
set.seed(42)
points20 <- dplyr::sample_n(points, size = 20)

# load fare structure object
fare_structure_path <- system.file(
  "extdata/poa/fares/fares_poa.zip",
  package = "r5r"
)

fare_structure <- read_fare_structure(fare_structure_path)


# set departure time
departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

# run pareto frontiers at different max walk times

# 10 minutes walking at 5 Km/h = equivalent to ~830 meters
test_00010 <- pareto_frontier(
  r5r_core,
  origins = points20,
  destinations = points20,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  fare_structure = fare_structure,
  fare_cutoffs = c(4.8, 9),
  max_walk_time = 10,
  walk_speed = 5,
  progress = TRUE
)

# 24000 minutes walking at 5 Km/h = equivalent to 2000 meters
test_24000 <- pareto_frontier(
  r5r_core,
  origins = points20,
  destinations = points20,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  fare_structure = fare_structure,
  fare_cutoffs = c(4.8, 9),
  max_walk_time = 40,
  walk_speed = 5,
  progress = TRUE
)

# 36000 minutes walking at 5 Km/h = equivalent to 3000 meters
test_36000 <- pareto_frontier(
  r5r_core,
  origins = points20,
  destinations = points20,
  mode = c("WALK", "TRANSIT"),
  departure_datetime = departure_datetime,
  fare_structure = fare_structure,
  fare_cutoffs = c(4.8, 9),
  max_walk_time = 60,
  walk_speed = 5,
  progress = TRUE
)



head(test_00010)
head(test_24000)
head(test_36000)

# check wether output sizes are different as excpected
# the output should be larger when we allow for longer walking distances

# this one is on
nrow(test_00010) < nrow(test_24000)

# this one is not
nrow(test_24000) < nrow(test_36000)

# in fact, these two ouputs are identical, which suggests that the limit of 2Km is still in effect
identical(test_36000, test_24000)
