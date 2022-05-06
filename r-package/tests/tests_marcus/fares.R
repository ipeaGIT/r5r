library("tidyverse")

fare_schema_df <- read_csv("../java-r5rcore/src/main/resources/fares/rio/fare_schema.csv")
routes_info_df <- read_csv("../java-r5rcore/src/main/resources/fares/rio/routes_info.csv")


modes_prices_df <- routes_info_df %>%
  select(type, price) %>%
  distinct()

modes_prices_df %>% write_csv("../java-r5rcore/src/main/resources/fares/rio/price_per_mode.csv")
