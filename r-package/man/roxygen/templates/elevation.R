#' @param elevation A string. The name of the impedance function to be used to
#'        calculate impedance for walking and cycling based on street slopes.
#'        Available options include `TOBLER` (Default) and `MINETTI`, or `NONE`
#'        to ignore elevation. R5 loads elevation data from `.tif` files saved
#'        inside the `data_path` directory. Elevation raster must be in WGS 84
#'        (EPSG:4326) coordinate reference system. See more info in the Details
#'        section below.
