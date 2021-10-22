############# Support functions for r5r

#' Java object to data.table
#'
#' @description Converts a Java object returned by r5r_core to an R data.table
#'
#' @param obj A Java Object reference
#'
#' @return An R data.table
#' @family java support functions

java_to_dt <- function(obj) {

  # get column names from Java table
  columns <- obj$getColumnNames()

  # get the contents of each column in a vector, and return them in a list
  dt <- lapply(columns, function(column_name) {
    # check column data type, so we can call the appropriate Java function
    column_type <- obj$getColumnType(column_name)

    if (column_type == "String") { v <- obj$getStringColumn(column_name) }
    if (column_type == "Integer") { v <- obj$getIntegerColumn(column_name) }
    if (column_type == "Long") { v <- obj$getLongColumn(column_name) }
    if (column_type == "Double") { v <- obj$getDoubleColumn(column_name) }
    if (column_type == "Boolean") { v <- obj$getBooleanColumn(column_name) }
    return(v)
  })

  # convert list of vectors to a data.table, and rename columns accordingly
  data.table::setDT(dt)
  data.table::setnames(dt, new = columns)
}
