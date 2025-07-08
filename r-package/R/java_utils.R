#' Java object to data.table
#'
#' @description Converts a Java object returned by r5r_network to an R `data.table`
#'
#' @param obj A Java Object reference
#'
#' @return An R data.table
#' @family java support functions
#'
#' @keywords internal
java_to_dt <- function(obj) {

  # check input
  if(class(obj)[1] != "jobjRef"){
    stop("Input must be an object of class 'jobjRef'")}

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

#' data.table to speedMap
#'
#' @description Converts a `data.frame` with road OSM id's and respective speeds
#'              to a Java Map<Long, Float> for use by r5r_network.
#'
#' @param dt data.frame/data.table. Table specifying the
#'        speed modifications. The table must contain columns \code{osm_id} and
#'        \code{max_speed}.
#' @return A speedMap (Java HashMap<Long, Float>)
#' @family java support functions
#' @keywords internal
dt_to_speed_map <- function(dt) {
  checkmate::assert_names(names(dt), identical.to = c("osm_id", "max_speed"))
  checkmate::assert_numeric(dt$osm_id, any.missing = FALSE, all.missing = FALSE)
  checkmate::assert_numeric(dt$max_speed, any.missing = FALSE, all.missing = FALSE)

  # Create new HashMap<Long, Float>
  speed_map <- rJava::.jnew("java/util/HashMap")
  for (i in seq_len(nrow(dt))) {
    speed_map$put(
      rJava::.jnew("java/lang/Long", as.character(dt$osm_id[i])),
      rJava::.jnew("java/lang/Float", as.numeric(dt$max_speed[i])))
  }
  return(speed_map)
}
