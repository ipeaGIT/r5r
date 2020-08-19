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




#' Check class of Origin / Destination inputs
#' #'
#' @param df Any object
#' @export
#' @family support functions
#'
test_points_input <- function(df) {

  # is data.frame or sf
  any_df <- is(df, 'data.frame')

  if( is(df, 'sf') ){
            any_sf <- as.character(unique(sf::st_geometry_type(df))) == "MULTIPOINT"
            } else { any_sf <- FALSE}

  # check
  if ( sum(any_df, any_sf) < 1) {
    stop(message("Origin/Destinations must be either a 'data.frame' or a 'sf MULTIPOINT'"))
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
