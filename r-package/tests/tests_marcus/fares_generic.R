# options(java.parameters = '-Xmx16384m')
# options(java.parameters = c("-XX:+UseConcMarkSweepGC", "-Xmx16384m"))

# library(r5r)
devtools::load_all(".")
library(tidyverse)
library(sf)
library(h3jsr)
library(data.table)
library(jsonlite)

# POA --------------
data_path <- "~/Repos/r5r_fares/poa"
core_poa <- setup_r5(data_path = data_path, verbose = FALSE)

# RIO --------------
data_path <- "~/Repos/r5r_fares/rio"
core_rio <- setup_r5(data_path = data_path, verbose = FALSE)


# SPO --------------
data_path <- system.file("extdata/spo", package = "r5r")
core_spo <- setup_r5(data_path = data_path, verbose = FALSE)


# get fare settings -------------
f_struct <- setup_fare_calculator(core_poa, base_fare = 470, by = "MODE")
f_struct$base_fare <- 500

f_struct <- setup_fare_calculator(core_poa,
                                  base_fare = 470,
                                  by = "MODE")

write_fare_calculator(f_struct, "c:\fares_poa.zip")

f_struct <- read_fare_calculator("c:\fares_poa.zip")


f_struct <- fare_calculator_settings(core_poa, 470, "AGENCY")
f_struct <- fare_calculator_settings(core_poa, 470, "AGENCY_ID")
f_struct <- fare_calculator_settings(core_poa, 470, "AGENCY_NAME")
f_struct <- fare_calculator_settings(core_poa, 470, "GENERIC")

f_struct <- fare_calculator_settings(core_rio, 405, "MODE")
f_struct <- fare_calculator_settings(core_spo, 440, "MODE")

f_struct$base_fare
f_struct$max_discounted_transfers

f_struct$fare_per_mode

View(f_struct$fare_per_mode)
View(f_struct$fare_per_transfer)
View(f_struct$routes_info)

zip::zip_list()


f_struct_json <- jsonlite::toJSON(f_struct)
clipr::write_clip(f_struct_json)


###
t_net <- transit_network_to_sf(core_poa)
t_net$routes %>%
  filter(str_starts(short_name, "R")) %>%
  # filter(str_starts(short_name, "T")) %>%
  mapview::mapview()
