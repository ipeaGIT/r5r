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
points_sf <- sfheaders::sf_multipoint(points, x='lon', y='lat', multipoint_id = 'id')

origin <- subset(points_sf, id == '89a90129977ffff')
destinations <- subset(points_sf, id %like% c('89a901299'))

# build transport network
data_path <- system.file("extdata", package = "r5r")
r5r_core <- setup_r5(data_path = data_path)

# input
mode = c('WALK', 'TRANSIT')
departure_time <- "14:00:00"
trip_date <- "2019-03-15"
max_street_time <- 30000L

# routing
df <- detailed_itineraries(r5r_core,
                           origins = origin,
                           destinations = destinations,
                           mode = 'WALK',
                           trip_date,
                           departure_time,
                           max_street_time)


# plot results
test <- ggplot() +
          geom_sf(data = df, color='gray95', alpha=.2) +
          # annotate("text", x = -51.193, y = -30.001, size=10, label = expression(paste("R"^5,"R")),
          #          color='gray95', family = "Roboto", fontface="bold", angle = 0) +
          scale_x_continuous(limits = c(-51.20560, -51.18052 )) +
          scale_y_continuous(limits = c(-30.02239, -30.0002 )) +
          theme_void() +
          theme(panel.grid.major=element_line(colour="transparent"))



# Create hex sticker
sticker2(test,

         # package name
         package= expression(paste("R"^5,"R")),  p_size=10, p_y = 1.5, p_color = "gray95",

         # ggplot image size and position
         s_x=1, s_y=.85, s_width=1.5, s_height=1.5,

         # hexagon
         h_fill="#009dcc", h_color="gray95", h_size=2,

         # url
         url = "github.com/ipeaGIT/r5r", u_color= "gray95", u_family = "Roboto",

         # save output name and resolution
           filename="./man/figures/r5r_test.png", dpi=120.5 #
          # filename="./man/figures/r5r_test.svg", dpi=120.5
        )



# big
sticker2(test,

         # package name
         package= expression(paste("R"^5,"R")),  p_size=22, p_y = 1.5, p_color = "gray95",

         # ggplot image size and position
         s_x=1, s_y=.85, s_width=1.5, s_height=1.5,

         # hexagon
         h_fill="#009dcc", h_color="gray95", h_size=2,

         # url
         url = "github.com/ipeaGIT/r5r", u_color= "gray95", u_family = "Roboto", u_size = 4,

         # save output name and resolution
         filename="./man/figures/r5r_test_b.png", dpi=300 #
)

# ### SMALL logo png ---------------
#
# df <- data.frame(x = c(0, 0, 1, 1), y = c(0, 1, 0, 1))
#
#  plot_small <- ggplot() +
#                   geom_point(data= df, aes(x=x, y=y), color=NA) +
#                   annotate("text", x = .42, y = .7, size=8, label = expression(paste("R"^5,"R")),
#                            color='#2D3E50', family = "Roboto", fontface="bold", angle = 0) +
#                   theme_void() +
#                   theme(panel.grid.major=element_line(colour="transparent"))
#
#
# # save .png
# sticker2(plot_small, package="",
#         s_x=1.12, s_y=.9, s_width=1.8, s_height=1.8, # ggplot image size and position
#         h_fill="gray99", h_color="#2D3E50", h_size=2, # hexagon
#         filename="./man/figures/r5r_logo_small.png", dpi=120.5)  # output name and resolution
#
#
# # save .svg
# sticker(plot_small, package="",
#          s_x=1.12, s_y=.9, s_width=1.8, s_height=1.8, # ggplot image size and position
#          h_fill="gray99", h_color="#2D3E50", h_size=2, # hexagon
#          filename="./man/figures/r5r_logo_small.svg", dpi=120.5)  # output name and resolution



