options(java.parameters = '-Xmx7G')
library(r5r)
library(ggplot2)
library(mapview)


a <- read.csv(file.path(data_path, "poa_hexgrid.csv"))[c(700,936),]
a


t <- isochrone(r5r_core = r5r_core,
               origins = a,
               mode = c("TRANSIT"), # TRANSIT WALK
               cutoffs = c(15, 30),
               departure_datetime = departure_datetime
               )

mapview(t)
mapview(t2)

ggplot() +
  geom_sf(data=subset(t, id==unique(t$id)[1]), aes(fill=isochrone))

ggplot() +
  geom_sf(data=subset(t, id==unique(t$id)[3]), aes(fill=isochrone))





aaaa <- sfheaders::sf_point(points , x='lon', y='lat', keep = T)
mapview(aaaa)

