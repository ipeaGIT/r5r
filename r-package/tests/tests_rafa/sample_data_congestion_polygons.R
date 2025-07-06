# create polygons with new speeds for sample data - Porto Alegre

library(sf)
library(dplyr)
library(mapview)

# 1. City-centre reference point (lon, lat in EPSG:4326) -----------------------

# Porto Alegre city-centre coords
poa_center <- st_sf(
  geometry = st_sfc(
    st_point(c(-51.2350, -30.0345)),
    crs = 4326
  )
)

mapview(poa_center)

# Re-project to a metric CRS (SIRGAS-2000 / UTM 22 S, EPSG:31982)
poa_center_utm <- st_transform(poa_center, 31982)



# 2. Build 1st buffer of 1 Km) -------------------------------------------------

# (a) 1 km radius, centred on city centre
poly_1km <- st_buffer(poa_center_utm, dist = 1000)
mapview(poly_1km)

# (b) 1000 km radius, whose centre is 1.5 km due-east (4 km + 2 km) of (a)
# shift in metres (E, N)
offset_east <- c(1500, 0)

poly_500m_east <- poa_center_utm
st_geometry(poly_500m_east) <- st_geometry(poly_500m_east) + offset_east
poly_500m_east <- st_buffer(poly_500m_east, dist = 500)

st_crs(poly_500m_east) <- st_crs(poly_1km)

# 3. Combine into a two-row sf object) -------------------------------------------------
multipolys <- rbind(
  st_sf(id = 1,      geometry = st_geometry(poly_1km)),
  st_sf(id = 2, geometry = st_geometry(poly_500m_east))
)

# (Optional) Transform back to WGS-84 for leaflet/GeoJSON export
multipolys_wgs84 <- st_transform(multipolys, 4326)

mapview(multipolys_wgs84)

# set max speed
multipolys_wgs84$max_speed <- c(0.7, 0.8)

# reorder columns
multipolys_wgs84 <- multipolys_wgs84 |>
  select(poly_id = id, max_speed)

# save data
saveRDS(multipolys_wgs84, 'poa_poly_congestion.rds')
