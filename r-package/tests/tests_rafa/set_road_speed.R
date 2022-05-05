#' Set custom road speed for vehicles on roads which do not have proper speed
#' information on OpenStreetMap.
#'
#' @description
#' By default, R5 considers that vehicles travel at the speed limit allowed on
#' each type of road, as informed on OpenStreetMap.pbf data. When the speed
#' information is not recorded on OpenStreetMap.pbf, this `set_road_speed()`
#' function allows users to set a custom speed for different types of roads. The
#' user needs to run this function before building the network with `setup_r5()`,
#' and then `set_road_speed()` will save a `build-config.json` file to the data
#' path, which will be picked up by R5 when building the network.
#'
#' @param data_path character string, the directory where data inputs are stored
#'                  and where the built `network.dat` will be saved.
#' @param motorway numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param motorway_link numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param trunk numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param trunk_link numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param primary numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param primary_link numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param secondary numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param secondary_link numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param tertiary numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param tertiary_link numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param living_street numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param pedestrian numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param residential numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param unclassified numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param service numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param track numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param road numeric. Speed in Km/h. Defaults to (`NULL`) use the speed recorded on OpenStreetMap.pdf data.
#' @param defaultSpeed numeric. Speed in Km/h. It cannot be `NULL`. defaultSpeed
#'                     is the speed used if none of tags matches and street doesn't
#'                     have maxspeed.
#'
#'
#' @return The functions saves a `build-config.json` file to the data path.
#'
#' @family support functions
#' @examples if (interactive()) {
#' library(r5r)
#'
#'# Get data path
#'path <- system.file("extdata/spo", package = "r5r")
#'
#'# set road speeds
#'set_road_speed(data_path = path,
#'                primary = 30,
#'                secondary = 20,
#'                trunk = 60,
#'                defaultSpeed = 50)
#'
#' # build transport network
#' r5r_core <- setup_r5(data_path = data_path, temp_dir = TRUE)
#'
#' }
#' @export
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
## check input

  # defaultSpeed cannot be NULL
  if( is.null(defaultSpeed) ){stop("Argument 'defaultSpeed' cannot be NULL")}
  checkmate::assert_class(defaultSpeed, 'numeric')

  if( !is.null(motorway) ){ checkmate::assert_class(motorway, 'numeric') }
  if( !is.null(motorway_link) ){ checkmate::assert_class(motorway_link, 'numeric') }
  if( !is.null(trunk) ){ checkmate::assert_class(trunk, 'numeric') }
  if( !is.null(trunk_link) ){ checkmate::assert_class(trunk_link, 'numeric') }
  if( !is.null(primary) ){ checkmate::assert_class(primary, 'numeric') }
  if( !is.null(primary_link) ){ checkmate::assert_class(primary_link, 'numeric') }
  if( !is.null(secondary) ){ checkmate::assert_class(secondary, 'numeric') }
  if( !is.null(secondary_link) ){ checkmate::assert_class(secondary_link, 'numeric') }
  if( !is.null(tertiary) ){ checkmate::assert_class(tertiary, 'numeric') }
  if( !is.null(tertiary_link) ){ checkmate::assert_class(tertiary_link, 'numeric') }
  if( !is.null(living_street) ){ checkmate::assert_class(living_street, 'numeric') }
  if( !is.null(pedestrian) ){ checkmate::assert_class(pedestrian, 'numeric') }
  if( !is.null(residential) ){ checkmate::assert_class(residential, 'numeric') }
  if( !is.null(unclassified) ){ checkmate::assert_class(unclassified, 'numeric') }
  if( !is.null(service) ){ checkmate::assert_class(service, 'numeric') }
  if( !is.null(track) ){ checkmate::assert_class(track, 'numeric') }
  if( !is.null(road) ){ checkmate::assert_class(road, 'numeric') }


## function
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
    , 'pedestrian' =    ifelse(is.null(pedestrian), NA, pedestrian)
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

  # save json to path
  write(my_list,file = paste0(path, '/build-config.json'))
  message(paste0('build-config.json file saved at ', paste0(path, '/build-config.json')))
}

