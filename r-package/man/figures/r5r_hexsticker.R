library(hexSticker) # https://github.com/GuangchuangYu/hexSticker
library(ggplot2)
library(sf)
library(ggtext)
library(r5r)

# add special text font
library(sysfonts)
font_add_google(name = "Roboto", family = "Roboto")
# font_add_google(name = "HelveticaR", family = "Linotype")

library(extrafont)
font_import()
loadfonts(device = "win")




####################################################
# help functions to create small logo
geom_pkgname2 <- function (package, x = 1, y = 1.4, color = "#FFFFFF", family = "Roboto",
                           size = 8, ...)
{
  # family <- load_font(family)
  annotate("text", x = x, y = y, label = package,  size = size, color = color)
}

sticker2 <- function (subplot, s_x = 0.8, s_y = 0.75, s_width = 0.4, s_height = 0.5,
                      package, p_x = 1, p_y = 1.4, p_color = "#FFFFFF", p_family = "Aller_Rg",
                      p_size = 8, h_size = 1.2, h_fill = "#1881C2", h_color = "#87B13F",
                      spotlight = FALSE, l_x = 1, l_y = 0.5, l_width = 3, l_height = 3,
                      l_alpha = 0.4, url = "", u_x = 1, u_y = 0.08, u_color = "black",
                      u_family = "Aller_Rg", u_size = 1.5, u_angle = 30, white_around_sticker = FALSE,
                      ..., filename = paste0(package, ".png"), asp = 1, dpi = 300)
{
  hex <- ggplot() + geom_hexagon(size = h_size, fill = h_fill,
                                 color = NA)
  if (inherits(subplot, "character")) {
    d <- data.frame(x = s_x, y = s_y, image = subplot)
    sticker <- hex + geom_image(aes_(x = ~x, y = ~y, image = ~image),
                                d, size = s_width, asp = asp)
  }
  else {
    sticker <- hex + geom_subview(subview = subplot, x = s_x,
                                  y = s_y, width = s_width, height = s_height)
  }
  sticker <- sticker + geom_hexagon(size = h_size, fill = NA,
                                    color = h_color)
  if (spotlight)
    sticker <- sticker + geom_subview(subview = spotlight(l_alpha),
                                      x = l_x, y = l_y, width = l_width, height = l_height)
  sticker <- sticker + geom_pkgname2(package, p_x, p_y, p_color,
                                    p_family, p_size)
  sticker <- sticker + geom_url(url, x = u_x, y = u_y, color = u_color,
                                family = u_family, size = u_size, angle = u_angle)
  if (white_around_sticker)
    sticker <- sticker + white_around_hex(size = h_size)
  sticker <- sticker + theme_sticker(size = h_size)
  save_sticker2(filename, sticker, dpi = dpi)
  invisible(sticker)
}


save_sticker2 <- function (filename, sticker = last_plot(), ...)
{
  ggsave(sticker, width = 3.83, height = 4.43, filename = filename,
         bg = "transparent", units = "cm", ...)
}



##### HEX sticker ------------------------

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

# plot results
test <- ggplot() +
          geom_sf(data = df, color='gray95', alpha=.2) +
          # geom_sf(data=destinations,  color='gray95', size=1) +
          # geom_sf(data=destinations,  color='navyblue', size=.6) +
          scale_x_continuous(limits = c(-51.20560, -51.18052 )) +
          scale_y_continuous(limits = c(-30.02239, -30.0002 )) +
          theme_void() +
          theme(panel.grid.major=element_line(colour="transparent"))




# big
sticker(test,

         # package name
         package= expression(paste("R"^5,"R")),  p_size=25, p_y = 1.5, p_color = "gray95", p_family="Roboto",

         # ggplot image size and position
         s_x=1, s_y=.85, s_width=1.4, s_height=1.4,

         # hexagon
         h_fill="#0d8bb1", h_color="white", h_size=1.3,

         # url
         url = "github.com/ipeaGIT/r5r", u_color= "gray95", u_family = "Roboto", u_size = 4,

         # save output name and resolution
         filename="./man/figures/r5r_big.png", dpi=300 #
)


sticker(test,

        # package name
        package= expression(paste("R"^5,"R")),  p_size=12, p_y = 1.5, p_color = "gray95", p_family="Roboto",

        # ggplot image size and position
        s_x=1, s_y=.85, s_width=1.4, s_height=1.4,

        # hexagon
        h_fill="#0d8bb1", h_color="white", h_size=2,

        # url
        url = "github.com/ipeaGIT/r5r", u_color= "gray95", u_family = "Roboto",

        # save output name and resolution
        filename="./man/figures/r5r_small.png", dpi=120.5 #
        # filename="./man/figures/r5r_test22.png", dpi=120.5
)

