############# Support functions for r5r
# nocov start





#' Convert sf spatial objects to data.frame
#'
#' @param sf A spatial sf MULTIPOINT object where the 1st column is the point id.
#' @export
#' @family support functions
#'
sf_to_df_r5r <- function(sf){

  df <- sfheaders::sf_to_df(sf, fill = TRUE)
  data.table::setDT(df)
  data.table::setnames(df, 'x', 'lon')
  data.table::setnames(df, 'y', 'lat')
  data.table::setnames(df, names(sf)[1], 'id')
  return(df)
}

#' Set verbose argument
#'
#' @param verbose logical, passed from function above
#' @export
#' @family support functions
#'
set_verbose <- function(verbose){

  if (verbose == TRUE) {
    r5r_core$verboseMode()

  } else if (verbose == FALSE) {
    # Only errors are reported.
    r5r_core$silentMode()

  } else {
    stop("Parameter 'verbose' must be either TRUE or FALSE")
  }
}



#' Check class of Origin / Destination inputs
#' #'
#' @param df Any object
#' @export
#' @family support functions
#'
test_points_input <- function(df) {

  # is data.frame or sf
  any_df <- is(df, 'data.frame')

  if (is(df, 'sf')) {
    any_sf <- as.character(unique(sf::st_geometry_type(df))) == "MULTIPOINT"
  } else {
    any_sf <- FALSE
  }

  # check df type

  if (sum(any_df, any_sf) < 1) {
    stop("Origin/Destinations must be either a 'data.frame' or a 'sf MULTIPOINT'.")
  }

  # check df columns' types

  if (!is.character(df$id)) {

    df$id <- as.character(df$id)
    stop("id must be a character column.")

  }

  if (!any_sf && (!is.numeric(df$lon) || !is.numeric(df$lat))) {

    stop("lat and lon must be numeric columns.")

  }

}


#' Set max walking distance
#'
#' @param max_walk_dist numeric, Maximum walking distance (in Km) for the whole
#'                      trip. Passed from routing functions.
#' @param walk_speed numeric, Average walk speed in Km/h. Defaults to 3.6 Km/h.
#'                    Passed from routing functions.
#' @param max_trip_duration numeric, Maximum trip duration in seconds. Defaults
#'                          to 7200 seconds (2 hours). Passed from routing functions.
#' @export
#' @family support functions
#'
set_max_walk_distance <- function(max_walk_dist, walk_speed, max_trip_duration){

  if (is.null(max_walk_dist)) {
    max_street_time = as.integer(max_trip_duration)
    return(max_street_time)

  } else if (!is.numeric(max_walk_dist)) {
    stop("max_walk_dist must be numeric")

  } else {
    max_street_time = as.integer(3600 * max_walk_dist / walk_speed)
    return(max_street_time)
  }
}


#' Select transport mode
#' #'
#' @param mode character string, defaults to "WALK"
#' @export
#' @family support functions
#'
select_mode <- function(mode="WALK") {

  mode <- toupper(unique(mode))

  # List all available modes
  dr_modes <- c('WALK','BICYCLE','CAR','BICYCLE_RENT','CAR_PARK')
  tr_modes <- c('TRANSIT', 'TRAM','SUBWAY','RAIL','BUS','FERRY','CABLE_CAR','GONDOLA','FUNICULAR')
  all_modes <- c(tr_modes, dr_modes)

  # check for invalid input
  lapply(X=mode, FUN=function(x){
    if(!x %chin% all_modes){stop(paste0("Eror: ", x, " is not a valid 'mode'.
                                      Please use one of the following: ",
                                        paste(unique(all_modes),collapse = ", ")))} })

  # assign modes accordingly
  direct_modes <- mode[which(mode %chin% dr_modes)]
  transit_mode <- mode[which(mode %chin% tr_modes)]


  # if only a direct_mode is passed, all others are empty
  if (length(direct_modes) != 0 & length(transit_mode) == 0) {
    egress_mode <- access_mode <- "WALK"
    transit_mode <- ""
  } else

    # if only transit mode is passed, assume 'WALK' as access_ and egress_modes
    if (length(transit_mode) != 0 & length(direct_modes) == 0) {
      egress_mode <- access_mode <- 'WALK'
      direct_modes <- ""

    } else

      # if transit & direct modes are passed, consider direct as access & egress_modes
      if (length(transit_mode) != 0 & length(direct_modes) != 0) {
        access_mode <- direct_modes[which(direct_modes %chin% c('WALK', 'BICYCLE', 'CAR'))]
        egress_mode <- access_mode <- unique(c('WALK', access_mode))
      }


  # create output as a list
  mode_list <- list('direct_modes' = paste0(direct_modes, collapse = ";"),
                    'transit_mode' = paste0(transit_mode, collapse = ";"),
                    'access_mode' = paste0(access_mode, collapse = ";"),
                    'egress_mode' = paste0(egress_mode, collapse = ";"))


  return(mode_list)
}

# nocov end
