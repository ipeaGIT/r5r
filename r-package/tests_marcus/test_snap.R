library(r5r)

# initialize r5r
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)

# get regular grid at resolution 8
grid_df <- r5r_core$getGrid(8L)
grid_df <- jdx::convertToR(grid_df)

# snap grid to street network
snap_df <- r5r_core$findSnapPoints(grid_df$id, grid_df$lat, grid_df$lon, "CAR")
snap_df <- jdx::convertToR(snap_df)

mv1 <- mapview::mapview(snap_df, xcol="lon", ycol="lat", crs=4326)
mv2 <- mapview::mapview(snap_df, xcol="snap_lon", ycol="snap_lat", zcol="found", crs=4326)

leafsync::sync(mv1, mv2)




