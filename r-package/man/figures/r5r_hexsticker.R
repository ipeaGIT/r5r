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











### SMALL logo png ---------------

df <- data.frame(x = c(0, 0, 1, 1), y = c(0, 1, 0, 1))

 plot_small <- ggplot() +
                  geom_point(data= df, aes(x=x, y=y), color=NA) +
                  annotate("text", x = .42, y = .7, size=8, label = expression(paste("R"^5,"R")),
                           color='#2D3E50', family = "Roboto", fontface="bold", angle = 0) +
                  theme_void() +
                  theme(panel.grid.major=element_line(colour="transparent"))


# save .png
sticker2(plot_small, package="",
        s_x=1.12, s_y=.9, s_width=1.8, s_height=1.8, # ggplot image size and position
        h_fill="gray99", h_color="#2D3E50", h_size=2, # hexagon
        filename="./man/figures/r5r_logo_small.png", dpi=120.5)  # output name and resolution


# save .svg
sticker(plot_small, package="",
         s_x=1.12, s_y=.9, s_width=1.8, s_height=1.8, # ggplot image size and position
         h_fill="gray99", h_color="#2D3E50", h_size=2, # hexagon
         filename="./man/figures/r5r_logo_small.svg", dpi=120.5)  # output name and resolution




  ####################################################
# help functions to create small logo
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
  sticker <- sticker + geom_pkgname(package, p_x, p_y, p_color,
                                    p_family, p_size, ...)
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





