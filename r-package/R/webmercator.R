deg2rad <- function(deg) {
    return(deg * pi / 180)
}

rad2deg <- function(rad) {
    return(rad * 180 / pi)
}

# these are web mercator _pixels_ not tile numbers
lon_to_webmercator_pixel <- function (lon, zoom) {
    return((lon + 180) / 360 * 2 ^ zoom * 256)
}

lat_to_webmercator_pixel <- function (lat, zoom) {
    latr = deg2rad(lat)
    return(
        (1 - 
            log(tan(latr) + 1/cos(latr)) / pi
        ) * 2 ^ (zoom - 1) * 256
    )
}

webmercator_pixel_to_lon <- function(px, zoom) {
    return(px / 256 / 2^zoom * 360 - 180)
}

webmercator_pixel_to_lat <- function(px, zoom) {
    return(rad2deg(atan(sinh(pi - px / 256 / 2^zoom * 2 * pi))))
}