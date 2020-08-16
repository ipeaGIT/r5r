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



# nocov end
