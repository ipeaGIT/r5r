devtools::load_all('.')
library(stringr)

# build regular network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, overwrite = T)
points <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)

# travel times before modifications
det <- detailed_itineraries(
  r5r_core,
  origins = points[10,],
  destinations = points[12,],
  mode = c("CAR"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60,
  osm_link_ids = TRUE
)

plot(det['total_duration'])
det$total_duration


# let's change the speeds
# get OSM ids as a vector
osm_ids <- det$osm_id_list |>
  stringr::str_remove_all("\\[|\\]") |>      # remove brackets
  stringr::str_split(",\\s*", simplify = TRUE) |>
  as.numeric()

osm_ids

# create csv with speed factors
df <- data.frame(osm_id = osm_ids, max_speed = .2)
tmep_df <- tempfile(fileext = '.csv')
data.table::fwrite(df, tmep_df)


r5rcore_new_speeds <- r5r:::modify_osm_carspeeds(
  pbf_path = system.file("extdata/poa/poa_osm.pbf", package = "r5r"),
  csv_path = tmep_df,
  output_dir = NULL,
  default_speed = 0.5,
  percentage_mode = TRUE
  )

# travel times AFTER modifications
det2 <- detailed_itineraries(
  r5rcore_new_speeds,
  origins = points[10,],
  destinations = points[12,],
  mode = c("CAR"),
  departure_datetime = departure_datetime,
  max_trip_duration = 60,
  osm_link_ids = TRUE
)

plot(det2['total_duration'])
det2$total_duration


