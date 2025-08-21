library(r5r)
library(dplyr)
library(data.table)
library(ggplot2)
library(dodgr)

RcppParallel::setThreadOptions (numThreads = 4L) # or desired number

# data path where the .pbf file is located
data_path <- system.file("extdata/poa", package = "r5r")
pbf_path <- file.path(data_path,'/poa_osm.pbf')

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

edges$oneway <- ifelse(
  edges$other_tags %like% "\"oneway\"=>\"yes\"",
  "yes",
  NA)

# keep only osm ids
edges <- edges[,c("osm_id","highway", "oneway")]
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

# unique id, mas a edge_id ja eh uma unique id de cada edge
car_network[,
            unique_id := paste(way_id, geom_num, edge_id, from_id, to_id, sep = "_"),
            by = .I
            ]

head(car_network)


data.table::setDT(edges)
car_network[edges, on = .(way_id=osm_id), oneway := i.oneway]
car_network$oneway

# 26786730 one way
# 27126547 two ways
car_network2 <- car_network[way_id %in% c(26786730, 27126547), ]
car_network2 <- car_network

# edges_sf <- sf::st_sf(edges)
# mapview::mapview(
#   filter(edges_sf, osm_id==27126547)
# )

one_way_net <- car_network2 |>
  filter(oneway=="yes") |>
  rename(osm_id = way_id) |>
  group_by(osm_id, oneway)  |>
  summarise(from_id = min(from_id),
            from_lat = from_lat[which.min(from_id)],
            from_lon = from_lon[which.min(from_id)],
            to_id =  max(to_id),
            to_lat = from_lat[which.max(to_id)],
            to_lon = from_lon[which.max(to_id)]
            ) |>
  ungroup()


two_way_net_forwards <- car_network2 |>
  filter(is.na(oneway)) |>
  rename(osm_id = way_id) |>
  group_by(osm_id)  |>
  summarise(oneway = "forwards",
            from_id = min(from_id),
            from_lat = from_lat[which.min(from_id)],
            from_lon = from_lon[which.min(from_id)],
            to_id =  max(to_id),
            to_lat = from_lat[which.max(to_id)],
            to_lon = from_lon[which.max(to_id)]
  ) |>
  ungroup()



two_way_net_backwards <- car_network2 |>
  filter(is.na(oneway)) |>
  rename(osm_id = way_id) |>
  group_by(osm_id)  |>
  summarise(oneway = "backwards",
            from_id = max(from_id),
            from_lat = from_lat[which.max(from_id)],
            from_lon = from_lon[which.max(from_id)],
            to_id =  min(to_id),
            to_lat = from_lat[which.min(to_id)],
            to_lon = from_lon[which.min(to_id)]
  ) |>
  ungroup()




my_net <- rbind(one_way_net, two_way_net_forwards, two_way_net_backwards)
my_net
