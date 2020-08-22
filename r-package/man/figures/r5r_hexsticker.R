
##### HEX sticker ------------------------


### Libraries ------------------------
remotes::install_github("GuangchuangYu/hexSticker")

library(hexSticker) # https://github.com/GuangchuangYu/hexSticker
library(ggplot2)
library(sf)
library(r5r)
library(sysfonts)

# add special text font
sysfonts::font_add_google(name = "Roboto", family = "Roboto")

library(extrafont)
font_import()
loadfonts(device = "win")



### setup ------------------------

# load origin/destination points
points <- read.csv(system.file("extdata/poa_hexgrid.csv", package = "r5r"))
points_sf <- sfheaders::sf_point(points, x='lon', y='lat', keep = T)

origin <- subset(points_sf, id == '89a90129977ffff')
destinations <- subset(points_sf, id %like% c('89a901299'))

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)


# routing
df <- detailed_itineraries(r5r_core,
                           origins = origin,
                           destinations = destinations,
                           mode = 'WALK',
                           departure_datetime = as.POSIXct("13-03-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S"),
                           max_trip_duration = 30000L)


st_crs(destinations) <- st_crs(df)


### network plot  ------------------------

# plot results
test <- ggplot() +
          geom_sf(data = df, color='gray95', alpha=.2) +
          # geom_sf(data=destinations,  color='gray95', size=1) +
          # geom_sf(data=destinations,  color='navyblue', size=.6) +
          scale_x_continuous(limits = c(-51.20560, -51.18052 )) +
          scale_y_continuous(limits = c(-30.02239, -30.0002 )) +
          theme_void() +
          theme(panel.grid.major=element_line(colour="transparent"))




### save sticker  ------------------------



sticker(test,

        # package name
        package= expression(paste("R"^5,"R")),  p_size=10, p_y = 1.5, p_color = "gray95", p_family="Roboto",

        # ggplot image size and position
        s_x=1, s_y=.85, s_width=1.4, s_height=1.4,

        # blue hexagon
        h_fill="#0d8bb1", h_color="white", h_size=1.3,

        ## black hexagon
        # h_fill="gray20", h_color="gray80", h_size=1.3,

        # url
        url = "github.com/ipeaGIT/r5r", u_color= "gray95", u_family = "Roboto", u_size = 1.8,

        # save output name and resolution
        filename="./man/figures/r5r_blue.png", dpi=300 #
)
