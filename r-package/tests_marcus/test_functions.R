options(java.parameters = '-Xmx16384m')
options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

library(r5r)
library(ggplot2)
library(data.table)
# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
dest <- points

points <- r5r_core$getGrid(11L)
points <- jdx::convertToR(points)
points$schools <- 1

dest <- points
dest <- dplyr::sample_n(points, 5000)

r5r_core$setBenchmarkMode(TRUE)
system.time(
  access <- accessibility(r5r_core,
                        origins = points,
                        destinations = dest,
                        opportunities_colname = "schools",
                        mode = "WALK",
                        cutoffs = c(25, 30),
                        max_trip_duration = 30,
                        verbose = FALSE)
)

system.time(
  ttm <- travel_time_matrix(r5r_core, origins = points,
                            destinations = dest,
                            mode = c("BICYCLE"),
                            max_trip_duration = 30,
                            max_walk_dist = 800,
                            verbose = FALSE)
)

system.time(
  dit <- detailed_itineraries(r5r_core,
                            origins =points,
                          destinations = points[1227:1,],
                          mode = c("BICYCLE"),
                          max_trip_duration = 120,
                          max_walk_dist = Inf,
                          max_bike_dist = Inf,
                          verbose = FALSE,
                          drop_geometry = FALSE)
)
dit %>% ggplot() + geom_sf()
mapview::mapview(points, xcol="lon", ycol="lat", crs = 4326)

street_net <- street_network_to_sf(r5r_core)
mapview::mapview(street_net$vertices)
mapview::mapview(street_net$edges)

transit_net <- transit_network_to_sf(r5r_core)
mapview::mapview(transit_net$stops %>% filter(linked_to_street == TRUE))
mapview::mapview(transit_net$routes)

snap <- r5r::find_snap(r5r_core, points)

system.time(ttm2 <- data.table::copy(ttm))

## raw ttm

v_from <- ttm$get("fromId")
jdx::convertToR(ttm$keySet())

ttm_dt <- data.table::data.table(fromId = ttm$get("fromId"),
                                 toId = ttm$get("toId"))
ttm_dt$travel_time <- ttm$get("travel_time")
head(ttm_dt, 10000) %>% View()

ttm$get("fromId")
ttm$get("fromId")

rJava::.jcall(obj = ttm, returnSig = "java/lang/Object", method = "get", "fromId")
system.time(ttm$get("fromId"))
.jcall("java/lang/System","S","getProperty","os.name")

system.time(r5r_core$buildVector(900000000L))

system.time(v <- r5r_core$v)
View(v)
v_dt <- data.table(v = v)

cat("Gathering results")
cat('\014')
message("Gathering results", appendLF = FALSE)
