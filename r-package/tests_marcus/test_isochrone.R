options(java.parameters = "-Xmx16G")

devtools::load_all(".")
# library(r5r)
library(tidyverse)
library(sf)
library(data.table)
library(mapview)

data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path, verbose = FALSE)

points <- fread(file.path(data_path, "poa_hexgrid.csv"))
central_bus_stn <- points[291,]

# points %>% mapview(xcol="lon", ycol="lat", crs=4326)
# market <- points[id == "89a90128843ffff",]

# routing inputs
mode <- c("WALK", "BUS")
max_walk_dist <- 1000 # in meters
max_trip_duration <- 60 # in minutes
departure_datetime <- as.POSIXct("13-05-2019 14:00:00",
                                 format = "%d-%m-%Y %H:%M:%S")

cutoffs = c(5L, 15L, 30L, 45L)

iso <- isochrones(r5r_core,
                  origins = central_bus_stn,
                  cutoffs = cutoffs,
                  zoom = 14L,
                  mode = mode,
                  max_walk_dist = max_walk_dist,
                  max_trip_duration = max_trip_duration,
                  departure_datetime = departure_datetime,
                  verbose = TRUE
                  )
iso$geometry <- st_as_sfc(iso$geometry)
iso <- st_as_sf(iso)
iso <- iso %>%
  st_make_valid() %>%
  mutate(geom = lag(geometry)) %>%
  mutate(geometry = map2(geometry, geom, st_difference)) %>%
  select(-geom)
st_crs(iso) <- 4326

iso2 <- iso %>% filter(cutoff > 10)
mapview(iso, zcol = "cutoff")

iso %>%
  mutate(geom = lag(geometry)) %>%
  mutate(geom2 = map2(geometry, geom, st_difference)) %>%
  mutate(geom2 = st_as_sfc(geom2)) %>% View()
  ggplot() + geom_sf(aes(geometry = geom2, fill = factor(cutoff)))
  View()
  mapview(zcol="cutoff")

mask <- subset(iso, cutoff == 0)
mapview(mask)

iso <- st_difference(iso %>% filter(cutoff>0), mask)
st_reverse(mask) %>% mapview()
iso %>% mapview()
iso <- iso %>% filter(travel_time < 120)
mapview(iso, xcol="lon",ycol="lat",zcol="travel_time", crs=4326)

iso$geometry[1]
st_cast(iso$geometry[1], to = "POLYGON")
street = street_network_to_sf(r5r_core)
street$edges %>% mapview()
iso$geometry[2]

iso$geometry[1][1]
st_cast(iso, to = "POLYGON") %>% filter(cutoff==15) %>%  mapview(zcol="cutoff")


geo <- "POLYGON ((-51.26770019504329 -29.990623478530463, -51.26770019504329 -30.112463828433018, -51.13311767578125 -30.112463828433018, -51.13311767578125 -29.989434054377867, -51.266326904296875 -29.989434054377867, -51.26770019504329 -29.990623478530463))"
a <- data_frame(a=1, geo=geo)
a$geo <- st_as_sfc(a$geo, crs = 4326)
a <- st_as_sf(a)
a %>% mapview()

geos <- str_split(iso$geometry[2], pattern = "\\(")
iso$geometry[[1]][[1,]]

geo <- "POLYGON ((-51.21839904785156 -30.02213803127762, -51.21826171875 -30.02511058549258, -51.21551513671875 -30.025705085640663, -51.21551513671875 -30.022732549250406, -51.21839904785156 -30.02213803127762))"
a <- data_frame(a=1, geo=geo)
a$geo <- st_as_sfc(a$geo, crs = 4326)
a <- st_as_sf(a)
a %>% mapview()

