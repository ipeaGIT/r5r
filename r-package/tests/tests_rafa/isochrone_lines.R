options(java.parameters = "-Xmx2G")
library(r5r)
library(ggplot2)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# load origin/point of interest
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))
origin_1 <- points[936,]

departure_datetime <- as.POSIXct(
  "13-05-2019 14:00:00",
  format = "%d-%m-%Y %H:%M:%S"
)


iso_poly <- isochrone(r5r_core,
                       origins = origin_1,
                       mode = "walk",
                       polygon_output = T,
                       departure_datetime = departure_datetime,
                       cutoffs = seq(0, 100, 10)
)

ggplot() +
  geom_sf(data=iso_poly, aes(fill=factor(isochrone))) +
  scale_fill_manual(values = colors, name='Isochrone(min.)') +
  geom_point(data=origin_1, aes(x=lon, y=lat), color='red')+
  theme_void()

# estimate line-based isochrone from origin_1
iso_lines <- isochrone(r5r_core,
                      origins = origin_1,
                      mode = "walk",
                      polygon_output = F,
                      departure_datetime = departure_datetime,
                      cutoffs = seq(0, 100, 10)
)
head(iso_lines)


#### plot
colors <- c('#ffe0a5','#ffcb69','#ffa600','#ff7c43','#f95d6a',
            '#d45087','#a05195','#665191','#2f4b7c','#003f5c')


# lines
ggplot() +
  geom_sf(data=iso_lines, aes(color=factor(isochrone))) +
  scale_color_manual(values = colors, name='Isochrone(min.)') +
  geom_point(data=origin_1, aes(x=lon, y=lat), color='red')+
  theme_void()

