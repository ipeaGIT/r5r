#' create lines with new LTS for sample data - Porto Alegre
#'
#' Here we simulate that local authorities would have build dedicated lanes
#' along all secondary roads in the city.

library(sf)
library(dplyr)
library(mapview)

# data path
data_path <- system.file("extdata/poa", package = "r5r")

# path to OSM pbf
pbf_path <- paste0(data_path, "/poa_osm.pbf")

# read layer of lines from pbf
allroads <- sf::st_read(
  pbf_path,
  layer = 'lines',
  quiet = TRUE
)

# Filter only road types of interest
roads <- allroads |>
  select(osm_id, highway) |>
  filter(highway %in% "secondary")

head(roads)

# Suppose your sf object is called `lines`
lines_multi <- st_sf(
  line_id = '1',
  lts = 2L,
  priority = 1L,
  geometry = st_combine(roads)
)

mapview::mapview(lines_multi)

saveRDS(lines_multi, 'poa_mls_lts.rds')
