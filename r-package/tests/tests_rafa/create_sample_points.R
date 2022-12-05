# create sample points used in poa and spo examples

library(aopdata)
library(data.table)



####### POA ------------------------------------

data_path_poa <- system.file("extdata/poa", package = "r5r")

list.files(data_path_poa)

# load origin/destination points
points_poa <- fread(file.path(data_path_poa, "poa_hexgrid.csv"))
head(points_poa)




####### SPO ------------------------------------

data_path_spo <- system.file("extdata/spo", package = "r5r")

list.files(data_path_spo)

# load origin/destination points
points_spo <- fread(file.path(data_path_spo, "spo_hexgrid.csv"))
head(points_spo)

