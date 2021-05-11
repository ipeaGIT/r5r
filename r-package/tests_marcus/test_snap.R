##### Reprex 1 - Parallel Computing #####
options(java.parameters = "-Xmx16G")

devtools::load_all(".")
library(tidyverse)
library(mapview)
# system.file returns the directory with example data inside the r5r package
# set data path to directory containing your own data if not using the examples
data_path <- system.file("extdata/poa", package = "r5r")

r5r_core <- setup_r5(data_path, verbose = FALSE)

grid_df <- r5r_core$getGrid(8L)
grid_df <- jdx::convertToR(grid_df)

grid_df %>% mapview(xcol="lon", ycol="lat", crs=4326)

snap_df <- r5r_core$findSnapPoints(grid_df$id, grid_df$lat, grid_df$lon, "CAR")
snap_df <- jdx::convertToR(snap_df)
snap_df %>% mapview(xcol="snap_lon", ycol="snap_lat", zcol="found", crs=4326)





