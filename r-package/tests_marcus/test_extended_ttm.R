options(java.parameters = '-Xmx2G')

# library(r5r)
devtools::load_all(".")
library(data.table)
library(tidyverse)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, verbose = FALSE, overwrite = FALSE)

# load origin/destination points

departure_datetime <- as.POSIXct("13-05-2019 14:00:00", format = "%d-%m-%Y %H:%M:%S")
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))

r5r_core$setBenchmark(TRUE)

t_ttm_warmup <- system.time(
  travel_time_matrix(r5r_core,
                     origins = points,
                     destinations = points,
                     departure_datetime = departure_datetime,
                     mode = c("WALK", "TRANSIT"),
                     max_trip_duration = 60,
                     max_walk_dist = 800,
                     time_window = 30,
                     # percentiles = c(25),
                     percentiles = c(25, 50, 75),
                     verbose = FALSE)
)

r5r_core$setTravelTimesBreakdown(FALSE)
t_ttm_normal <- system.time(
  ttm_n <- travel_time_matrix(r5r_core,
                            origins = points,
                            destinations = points,
                            departure_datetime = departure_datetime,
                            mode = c("WALK", "TRANSIT"),
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 30,
                            # percentiles = c(25),
                            percentiles = c(25, 50, 75),
                            verbose = FALSE)
)

r5r_core$setTravelTimesBreakdown(TRUE)
t_ttm_breakdown <- system.time(
  ttm_b <- travel_time_matrix(r5r_core,
                            origins = points,
                            destinations = points,
                            departure_datetime = departure_datetime,
                            mode = c("WALK", "TRANSIT"),
                            max_trip_duration = 60,
                            max_walk_dist = 800,
                            time_window = 30,
                            # percentiles = c(25),
                            percentiles = c(25, 50, 75),
                            verbose = FALSE)
)


t_ttm_warmup
t_ttm_normal
t_ttm_breakdown

rbind(
  ttm_n %>% select(fromId, execution_time) %>% distinct() %>% mutate(method = "normal"),
  ttm_b %>% select(fromId, execution_time) %>% distinct() %>% mutate(method = "breakdown")
) %>%
  ggplot(aes(execution_time)) + geom_histogram() + facet_wrap(~method, scales = "free")



# max_trip_duration = 60
#
# travel_times = data.table::copy(ttm)
# for(j in seq(from = 3, to = (length(percentiles) + 3))){
#   data.table::set(travel_times, i=which(travel_times[[j]]>max_trip_duration), j=j, value=NA_integer_)
# }
#
# names
# colnames <- names(travel_times)[startsWith(names(travel_times), "travel_time")]
# for(j in colnames){
#   data.table::set(travel_times, i=which(travel_times[j]>max_trip_duration), j=j, value=NA_integer_)
# }
#
# length(c(25, 50, 75))
