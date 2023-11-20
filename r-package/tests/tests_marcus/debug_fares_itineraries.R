# load packages
#library("r5r")
devtools::load_all('.')
library("dplyr")
library("ggplot2")

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

# load fare structure object
fare_structure_path <- system.file(
  "extdata/poa/fares/fares_poa.zip",
  package = "r5r"
)
fare_structure <- read_fare_structure(fare_structure_path)

# inputs
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")
# plan itineraries
dit <- detailed_itineraries(r5r_core,
                            origins = points[10,],
                            destinations = points[12,],
                            mode = c("WALK", "TRANSIT"),
                            departure_datetime = departure_datetime,
                            max_trip_duration = 140,
                            fare_structure = fare_structure,
                            max_fare = 9,
                            shortest_path = FALSE,
                            drop_geometry = TRUE)


# build Pareto frontiers
pareto_df <- dit  |>
  group_by(option) |>
  summarise(travel_time = max(total_duration),
            fare = max(total_fare),
            mode = paste(if_else(mode == "WALK", "", mode), collapse = " ")) |>
  mutate(mode = if_else(mode == "", "WALK", mode))


# plot Pareto frontiers
ggplot(pareto_df , aes(x=fare, y=travel_time)) +
  geom_step() +
  geom_point() +
  geom_text(aes(label=mode), hjust = -0.1, vjust=-0.5) +
  geom_text(aes(label=paste("BRL", scales::comma(fare, accuracy = 0.01))),
            hjust = 0.3, vjust=1.5) +
  scale_y_continuous(breaks = seq(0, 140, 20), limits = c(0, 140)) +
  scale_x_continuous(breaks = 0:10, limits = c(0, 10),
                     labels = scales::comma_format(accuracy = 0.01)) +
  theme_light() +
  labs(x = "fare (BRL)", y = "travel time (minutes)",
       subtitle = "Travel time and monetary cost of trips between\nFarrapos Station and Praia de Belas Shopping Mall")
