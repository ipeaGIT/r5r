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



# nocov end
