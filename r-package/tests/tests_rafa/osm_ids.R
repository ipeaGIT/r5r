library(r5r)
library(dplyr)
library(data.table)
library(ggplot2)
library(dodgr)

RcppParallel::setThreadOptions (numThreads = 4L) # or desired number

# data path where the .pbf file is located
data_path <- system.file("extdata/poa", package = "r5r")
pbf_path <- paste0(data_path,'/poa_osm.pbf')

# read layer of lines from pbf
edges <- sf::st_read(
  pbf_path,
  layer = 'lines',
  quiet = TRUE
)

nodes <- sf::st_read(
  pbf_path,
  layer = 'points',
  quiet = TRUE
)

# keep only osm ids
edges <- edges[,c("osm_id","highway")]
nodes <- nodes[,c("osm_id","highway")]


# build car network
car_network <- dodgr::weight_streetnet(
  x = edges,
  id_col = 'osm_id',
  wt_profile = "motorcar"
  )

# convert node ids to numeric
data.table::setDT(car_network)
car_network[, from_id := as.numeric(from_id)]
car_network[, to_id := as.numeric(to_id)]

# create a unique edge id with the first and last node of the edge
car_network <- car_network |>
  group_by(way_id)  |>
  mutate(unique_id_forward = paste0(min(from_id,to_id), '-', max(from_id,to_id)),
         unique_id_backward = paste0(max(from_id,to_id), '-', min(from_id,to_id))
  ) |>
  ungroup()

# create unique id where A-B equals B-A to identify two way segments
car_network <- car_network |>
  rowwise()  |>
  mutate(permut_id = paste0(min(from_id,to_id), '-', max(from_id,to_id))
  )

# select columns
df <- car_network |>
  dplyr::select(osm_id = way_id, unique_id_forward, unique_id_backward, permut_id,
                distance_m = d, time_s = time,
                from_id, to_id, from_lon, from_lat, to_lon, to_lat)

head(df)


# keep only the first observation of each edge
data.table::setDT(df)
df <- df[, .SD[1,], by=.(osm_id ,permut_id)]

head(df)







tttttt <- 835202042

t <- df |>
  filter(osm_id==tttttt)

t[, .(from_id = min(from_id),
      to_id = max(to_id),
      distance_m = sum(distance_m),
      time_s  = sum(time_s),
      from_lon = from_lon[which.min(from_id)],
      from_lat = from_lat[which.min(from_id)],
      to_lon = to_lon[which.max(from_id)],
      to_lat = to_lat[which.max(from_id)]
      ),
  by = .(osm_id, unique_id )]

edges |>
  filter(osm_id==tttttt) |>
  sf::st_length()

duvida.
no arcgis a gente pede apenas A-B, ou pede tambem B-A ?
a gente soh precisa do weight factor.... unidirecional
mas se a gente pedir a-b e somente for permitiodo b-a,
dai a rota e tempo de viagem vai ser meio loucae a gente
vai acabar tendo q rodar de novo
entao melhor rodar rodo a-b e b-a
