testthat::skip_on_cran()

options(java.parameters = "-Xmx2G")

if (Sys.getenv("NOT_CRAN") != "false") {

  # porto alegre
  data_path <- system.file("extdata/poa", package = "r5r")
  r5r_network <- r5r::build_network(data_path, verbose = FALSE)
  points <- data.table::fread(file.path(data_path, "poa_hexgrid.csv"))
  pois <- data.table::fread(file.path(data_path, "poa_points_of_interest.csv"))
  departure_datetime <- as.POSIXct(
    "13-05-2019 14:00:00",
    format = "%d-%m-%Y %H:%M:%S"
  )
  fare_structure <- r5r::read_fare_structure(
    system.file("extdata/poa/fares/fares_poa.zip", package = "r5r")
  )

  # sao paulo
  spo_path <- system.file("extdata/spo", package = "r5r")
  spo_network <- r5r::build_network(spo_path, verbose = FALSE)
  spo_points <- data.table::fread(file.path(spo_path, "spo_hexgrid.csv"))
  spo_points[, opportunities := 1]
  spo_fare_struc <- r5r::setup_fare_structure(spo_network, 5)
  spo_fare_struc$fares_per_transfer <- data.table::data.table(NULL)
}
