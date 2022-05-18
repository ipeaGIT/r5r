options(java.parameters = '-Xmx2G')

if (Sys.getenv("NOT_CRAN") != "false") {
  data_path <- system.file("extdata/poa", package = "r5r")
  r5r_core <- setup_r5(data_path, verbose = FALSE)
  points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
  pois <- read.csv(file.path(data_path, "poa_points_of_interest.csv"))
}

