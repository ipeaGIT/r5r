
set_road_speed <- function(data_path,
                           motorway = NULL
                         , motorway_link = NULL
                         , trunk = NULL
                         , trunk_link = NULL
                         , primary = NULL
                         , primary_link = NULL
                         , secondary = NULL
                         , secondary_link = NULL
                         , tertiary = NULL
                         , tertiary_link = NULL
                         , living_street = NULL
                         , pedestrian = NULL
                         , residential = NULL
                         , unclassified = NULL
                         , service = NULL
                         , track = NULL
                         , road = NULL
                         , defaultSpeed = NULL){

  # create data frame with speeds passed by user
  speeds_df <- data.frame(
      'motorway' =      ifelse(is.null(motorway), NA, motorway)
    , 'motorway_link' = ifelse(is.null(motorway_link), NA, motorway_link)
    , 'trunk' =         ifelse(is.null(trunk), NA, trunk)
    , 'trunk_link' =    ifelse(is.null(trunk_link), NA, trunk_link)
    , 'primary' =       ifelse(is.null(primary), NA, primary)
    , 'primary_link' =  ifelse(is.null(primary_link), NA, primary_link)
    , 'secondary' =     ifelse(is.null(secondary), NA, secondary)
    , 'secondary_link' =ifelse(is.null(secondary_link), NA, secondary_link)
    , 'tertiary' =      ifelse(is.null(tertiary), NA, tertiary)
    , 'tertiary_link' = ifelse(is.null(tertiary_link), NA, tertiary_link)
    , 'living_street' = ifelse(is.null(living_street), NA, living_street)
    , 'pedestrian' =     ifelse(is.null(pedestrian), NA, pedestrian)
    , 'residential' =   ifelse(is.null(residential), NA, residential)
    , 'unclassified' =  ifelse(is.null(unclassified), NA, unclassified)
    , 'service' =       ifelse(is.null(service), NA, service)
    , 'track' =         ifelse(is.null(track), NA, track)
    , 'road' =          ifelse(is.null(road), NA, road)
    , 'defaultSpeed' =  ifelse(is.null(defaultSpeed), NA, defaultSpeed))

  # remove columns with missing value
  speeds_df <- speeds_df[ , apply(speeds_df, 2, function(x) !any(is.na(x)))]

  # retrieve default speed
  dflt_speed <- speeds_df$defaultSpeed
  speeds_df$defaultSpeed <- NULL

  # Convert to list in the json structure we need
  my_list <- list( speeds = list ( units = 'km/h',
                                   values= list(speeds_df),
                                   defaultSpeed = dflt_speed ) )

  # Prettify (add indentation)
  my_list <- jsonlite::toJSON(my_list, pretty = TRUE)

  # remove brackets
  my_list <- gsub("\\[|\\]", '', my_list)

  # save json
  write(my_list,file = paste0(path, '/build-config.json'))
}

#### example -----------------

library(jsonlite)
library(data.table)
library(r5r)

# build network
points <- read.csv(system.file("extdata/poa/poa_hexgrid.csv", package = "r5r"))[c(1:100, 500:600),]
path <- system.file("extdata/poa", package = "r5r")

# set road speeds
set_road_speed(data_path = path,
               primary = 666,
               secondary = 666,
               trunk = 666,
               road = 666,
               defaultSpeed = 666)

r5r_core <- setup_r5(data_path = path, verbose = F, overwrite = T)

tt <- r5r::travel_time_matrix(r5r_core = r5r_core, origins = points,destinations = points, mode = 'car')
# fwrite(tt, 'tt_test.csv')
