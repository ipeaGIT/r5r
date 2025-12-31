# Allocate memory, load R packages, set paths
options(java.parameters = "-Xmx4G")

library(r5r)
library(sf)
library(data.table)

library(dplyr)

# Locate data path
data_path = system.file("extdata/poa", package = "r5r")
gtfs = gtfstools::read_gtfs( file.path(data_path, 'poa_eptc.zip'))

# Select a specific route
routes_data = gtfs$routes
stops_data = gtfs$stops
stop_times_data = gtfs$stop_times
trips_data = gtfs$trips
calendar_dates_data = gtfs$calendar_dates
SELECTED_ROUTE_ID = routes_data$route_id[5]  # Result is route_id ="654"

# Select an available trip as an example
stop_sequence_for_trip = trips_data %>%
  filter(route_id == SELECTED_ROUTE_ID) %>%
  slice(1) %>%
  left_join(stop_times_data, by = "trip_id") %>%
  left_join(stops_data, by = "stop_id") %>%
  arrange(stop_sequence) %>%
  select(stop_sequence, stop_id, stop_name, stop_lat, stop_lon,
         arrival_time, departure_time)

# Query information for the selected trip
temp1_record_selected_trip = trips_data %>% filter(route_id == SELECTED_ROUTE_ID) %>%  slice(1)   # Result is trip_id = 654-1@1#1240
temp2_record_selected_trip_stops = stop_times_data[stop_times_data$trip_id == temp1_record_selected_trip$trip_id,]  # Operation time: 12:40:00 - 13:25:00

# Rename columns
names(stop_sequence_for_trip)[2] = 'id' # stop_id
names(stop_sequence_for_trip)[4] = 'lat' # stop_lat
names(stop_sequence_for_trip)[5] = 'lon' # stop_lon

# Select Stop No.1 → No.40 as the OD pair
A_origin = stop_sequence_for_trip[1,]
A_stop_id = A_origin$id
B_destination = stop_sequence_for_trip[40,]
B_stop_id = B_destination$id

r5r_network = build_network(data_path = data_path)

# Service schedule
calendar_date_654 = gtfs$calendar_dates[calendar_dates_data$service_id %in% temp1_record_selected_trip$service_id,]

# Set assumed departure time and search for feasible routes
T1 = as.POSIXct("2019-06-18 12:35:00",tz = 'America/Sao_Paulo')

# T1 = as.POSIXct(
#   "18-06-2019 12:35:00",
#   format = "%d-%m-%Y %H:%M:%S"
#   )

# Q1: Route 654 cannot be found when setting time between 12:35:00 - 12:39:00
# Q2: Why can Route 654 be found when setting time between 12:40:00 - 12:50:00? Why do we get different departure times?
# Known trip duration is 12:40:00 - 13:25:00
# Q3: Route 654 can be found when setting time between 12:30:00 - 12:34:00, but the departure time is sometimes unstable

A_B_trip = detailed_itineraries(r5r_network,
                                origins = A_origin,
                                destinations = B_destination,
                                mode = c("WALK", "TRANSIT"),
                                departure_datetime = T1,
                                max_walk_time = 120,
                                max_trip_duration = 120,
                                time_window = 5,
                                # suboptimal_minutes = 15,
                                shortest_path = T)   # Set to FALSE to find Route 654

A_B_trip
plot(A_B_trip)

# rafa ---------------------------------

library(gtfstools)
library(mapview)
library(sfheaders)


A_origin_sf <- sfheaders::sf_point(A_origin, x="lon", y="lat", keep = T)
B_destination_sf <- sfheaders::sf_point(B_destination, x="lon", y="lat", keep = T)

route_sf <- gtfstools::filter_by_route_id(gtfs, route_id = SELECTED_ROUTE_ID) |>
  gtfstools::convert_shapes_to_sf()


mapview(A_B_trip, zcol = "option" ) +
  mapview(route_sf, col.regions="orange") +
  mapview(A_origin_sf, col.regions="green") +
  mapview(B_destination_sf, col.regions="red")


