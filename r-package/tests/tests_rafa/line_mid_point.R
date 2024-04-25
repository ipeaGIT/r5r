# https://gis.stackexchange.com/questions/277219/sf-equivalent-of-r-maptools-packages-spatiallinesmidpoints

get_mid_point <- function(a){
  new_shape <- sf::st_segmentize(x = a, dfMaxLength = 50)
  new_shape <- sfheaders::sf_cast(new_shape, "POINT")

  m_position <- (nrow(new_shape) /2) |> round(digits = 0)
  mid_point <- new_shape[m_position,]
  return(mid_point)
}

m <- get_mid_point(a)



mapview(m)
library(ggplot2)


c <- st_centroid(a)

ss <- st_line_midpoints(a)

ggplot() +
geom_sf(data = new_shape, color='blue')+
  geom_sf(data = a, color='gray')+
  geom_sf(data = m, color='red') +
  geom_sf(data = c, color='green') +
  geom_sf(data = ss, color='orange')


library(bench)

bench::mark(check=F,
    get_mid_point(a),
  st_line_midpoints(sf_lines = a)
)

expression              min  median `itr/sec` mem_alloc `gc/sec` n_itr  n_gc
<bch:expr>          <bch:t> <bch:t>     <dbl> <bch:byt>    <dbl> <int> <dbl>
  1 get_mid_point(a)     25.2ms  27.1ms      36.7     322KB     2.30    16     1
2 st_line_midpoints(… 799.9µs 826.1µs    1139.     12.7KB     0      570     0
                     # ℹ 5 more variables: total_time <bch:tm>, result <list>, memory <list>,
