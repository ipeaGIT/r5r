options(java.parameters = "-Xmx2G")

if (Sys.getenv("NOT_CRAN") != "false") {
  data_path <- system.file("extdata/poa", package = "r5r")
  r5r_core <- setup_r5(data_path, verbose = FALSE)
  points <- data.table::fread(file.path(data_path, "poa_hexgrid.csv"))
  pois <- data.table::fread(file.path(data_path, "poa_points_of_interest.csv"))
  departure_datetime <- as.POSIXct(
    "13-05-2019 14:00:00",
    format = "%d-%m-%Y %H:%M:%S"
  )
  fare_structure <- read_fare_structure(
    system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
  )
}
