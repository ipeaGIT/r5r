# Travel time matrices

Abstract

This vignette shows how to use the travel_time_matrix() and
expanded_travel_time_matrix() functions in r5r.

## 1. Introduction

Some of the most common tasks in transport planning and modeling involve
require having good quality data with travel time estimates between
origins and destinations. `R5` is incredibly fast in generating
realistic door-to-door travel time estimates in multimodal transport
systems.

The `r5r` package has two functions that allow users to leverage the
computing power of `R5`: -
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/travel_time_matrix.md) -
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md) -
[`arrival_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/arrival_travel_time_matrix.md)

This vignette shows a reproducible example to explain how these two
functions work and the differences between them.

## 2. Build routable transport network with `build_network()`

First, let’s build the multimodal transport network we’ll be using in
this vignette. In this example we’ll be using the a sample data set for
the city of Porto Alegre (Brazil) included in `r5r`.

``` r
# increase Java memory
options(java.parameters = "-Xmx2G")

# load libraries
library(r5r)
library(data.table)
library(ggplot2)

# build a routable transport network with r5r
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)

# routing inputs
mode <- c('walk', 'transit')
max_trip_duration <- 60 # minutes

# departure time
departure_datetime <- as.POSIXct("13-05-2019 14:00:00", 
                                 format = "%d-%m-%Y %H:%M:%S")

# load origin/destination points
points <- fread(file.path(data_path, "poa_points_of_interest.csv"))
```

## 3. The `travel_time_matrix()` function

The
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/travel_time_matrix.md)
function provides a simple and really fast way to calculate the travel
time between all possible origin destination pairs at a given departure
time using a given transport mode.

The user can also customize many parameters such as: -
`max_trip_duration`: maximum trip duration - `max_rides`: maximum number
of transfer in the public transport system - `max_walk_time` and
`max_bike_time`: maximum walking or cycling time to and from public
transport - `walk_speed` and `bike_speed`: maximum walking or cycling
speed - `max_fare`: maximum monetary cost in public transport. [See this
vignette](https://ipeagit.github.io/r5r/articles/fare_structure.html).

``` r
# estimate travel time matrix
ttm <- travel_time_matrix(
  r5r_network,   
  origins = points,
  destinations = points,    
  mode = mode,
  max_trip_duration = max_trip_duration,
  departure_datetime = departure_datetime
  )

head(ttm, n = 10)
#>           from_id                     to_id travel_time_p50
#>            <char>                    <char>           <int>
#>  1: public_market             public_market               0
#>  2: public_market       bus_central_station              13
#>  3: public_market          gasometer_museum              12
#>  4: public_market       santa_casa_hospital              13
#>  5: public_market                  townhall               3
#>  6: public_market           piratini_palace              14
#>  7: public_market    metropolitan_cathedral              15
#>  8: public_market          farroupilha_park              18
#>  9: public_market moinhos_de_vento_hospital              20
#> 10: public_market          farrapos_station              20
```

Now remember that travel time estimates can vary significantly across
the day because of variations in public transport service levels. In
order to account for this, you might want to calculate multiple travel
time matrices departing at different times.

This can be done very efficiently by using the `time_window` and
`percentile` parameters in the
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/travel_time_matrix.md)
function. When these parameters are set, R⁵ will automatically compute
multiple travel times estimates considering multiple departures per
minute within the `time_window` selected by the user. [More information
about this functionality can found in this
vignette](https://ipeagit.github.io/r5r/articles/time_window.html).

## 4. The `expanded_travel_time_matrix()` function

Sometimes, we want to know more than simply the total travel time from A
to B. This is when the
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
function comes in. By default, the output of this function will also
tell which public transport routes were taken between each origin
destination pair.

Nonetheless, you may set the parameter `breakdown = TRUE` to gather much
more info for each trip. In this case,
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
will tell the number of transfers used to complete each trip and their
total access, waiting, in-vehicle and transfer times. Please note that
setting `breakdown = TRUE` can make the function slower for large data
sets.

*A general call to expanded_travel_time_matrix()*

``` r
ettm <- expanded_travel_time_matrix(
  r5r_network,   
  origins = points,
  destinations = points,    
  mode = mode,
  max_trip_duration = max_trip_duration,
  departure_datetime = departure_datetime
  )

head(ettm, n = 10)
#>           from_id         to_id departure_time draw_number routes total_time
#>            <char>        <char>         <char>       <int> <char>      <num>
#>  1: public_market public_market       14:00:00           1 [WALK]          0
#>  2: public_market public_market       14:01:00           1 [WALK]          0
#>  3: public_market public_market       14:02:00           1 [WALK]          0
#>  4: public_market public_market       14:03:00           1 [WALK]          0
#>  5: public_market public_market       14:04:00           1 [WALK]          0
#>  6: public_market public_market       14:05:00           1 [WALK]          0
#>  7: public_market public_market       14:06:00           1 [WALK]          0
#>  8: public_market public_market       14:07:00           1 [WALK]          0
#>  9: public_market public_market       14:08:00           1 [WALK]          0
#> 10: public_market public_market       14:09:00           1 [WALK]          0
```

*Calling expanded_travel_time_matrix() with `breakdown = TRUE`*

``` r
ettm2 <- expanded_travel_time_matrix(
  r5r_network,   
  origins = points,
  destinations = points,    
  mode = mode,
  max_trip_duration = max_trip_duration,
  departure_datetime = departure_datetime,
  breakdown = TRUE
  )

head(ettm2, n = 10)
#>           from_id         to_id departure_time draw_number access_time
#>            <char>        <char>         <char>       <int>       <num>
#>  1: public_market public_market       14:00:00           1           0
#>  2: public_market public_market       14:01:00           1           0
#>  3: public_market public_market       14:02:00           1           0
#>  4: public_market public_market       14:03:00           1           0
#>  5: public_market public_market       14:04:00           1           0
#>  6: public_market public_market       14:05:00           1           0
#>  7: public_market public_market       14:06:00           1           0
#>  8: public_market public_market       14:07:00           1           0
#>  9: public_market public_market       14:08:00           1           0
#> 10: public_market public_market       14:09:00           1           0
#>     wait_time ride_time transfer_time egress_time routes n_rides total_time
#>         <num>     <num>         <num>       <num> <char>   <int>      <num>
#>  1:         0         0             0           0 [WALK]       0          0
#>  2:         0         0             0           0 [WALK]       0          0
#>  3:         0         0             0           0 [WALK]       0          0
#>  4:         0         0             0           0 [WALK]       0          0
#>  5:         0         0             0           0 [WALK]       0          0
#>  6:         0         0             0           0 [WALK]       0          0
#>  7:         0         0             0           0 [WALK]       0          0
#>  8:         0         0             0           0 [WALK]       0          0
#>  9:         0         0             0           0 [WALK]       0          0
#> 10:         0         0             0           0 [WALK]       0          0
```

You will notice in the documentation that the
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
also has a `time_window` parameter. In this case, though, when the user
sets a `time_window` value, the
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
will return the fastest route alternative departing each minute within
the specified time window. Please note this function can be very memory
intensive for large data sets and time windows.

``` r
ettm_window <- expanded_travel_time_matrix(
  r5r_network,   
  origins = points,
  destinations = points,    
  mode = mode,
  max_trip_duration = max_trip_duration,
  departure_datetime = departure_datetime,
  breakdown = TRUE,
  time_window = 10
  )

ettm_window[15:25,]
#>           from_id               to_id departure_time draw_number access_time
#>            <char>              <char>         <char>       <int>       <num>
#>  1: public_market bus_central_station       14:04:00           1         1.3
#>  2: public_market bus_central_station       14:05:00           1         3.1
#>  3: public_market bus_central_station       14:06:00           1         3.1
#>  4: public_market bus_central_station       14:07:00           1         4.0
#>  5: public_market bus_central_station       14:08:00           1         2.1
#>  6: public_market bus_central_station       14:09:00           1         2.1
#>  7: public_market    gasometer_museum       14:00:00           1         2.5
#>  8: public_market    gasometer_museum       14:01:00           1         4.3
#>  9: public_market    gasometer_museum       14:02:00           1         4.3
#> 10: public_market    gasometer_museum       14:03:00           1         4.3
#> 11: public_market    gasometer_museum       14:04:00           1         4.3
#>     wait_time ride_time transfer_time egress_time routes n_rides total_time
#>         <num>     <num>         <num>       <num> <char>   <int>      <num>
#>  1:       1.7       3.5             0         6.7    525       1       13.2
#>  2:       2.9       1.6             0         6.2 LINHA1       1       13.8
#>  3:       1.9       1.6             0         6.2 LINHA1       1       12.8
#>  4:       2.0       2.0             0         6.7    493       1       14.7
#>  5:       4.9       1.1             0         7.4    D72       1       15.5
#>  6:       3.9       1.1             0         7.4    D72       1       14.5
#>  7:       1.5       4.5             0         1.8   2821       1       10.3
#>  8:       4.7       4.3             0         1.8    346       1       15.1
#>  9:       3.7       4.3             0         1.8    346       1       14.1
#> 10:       2.7       4.3             0         1.8    346       1       13.1
#> 11:       1.7       4.3             0         1.8    346       1       12.1
```

## 4. The `arrival_travel_time_matrix()` function

Both of the functions
[`travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/travel_time_matrix.md)
and
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
consider a **departure** time set by the user. In some cases, though,
you might need to calculate travel times considering an **arrival
time**. For such cases, you can use
[`arrival_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/arrival_travel_time_matrix.md).
In this function, you need to set the latest arrival time desired and a
maximum trip duration. The function returns the travel time of the trip
with the latest departure time that arrives before the arrival time.

This function is useful when modeling user behavior in situations where
arriving by a specific time is important, such as getting to work or
school for a set start time (e.g., 9 a.m.). In these scenarios, it is
often most convenient for a person to take the latest possible departure
that still ensures arrival before their required start time, rather than
choosing the trip with the shortest travel time but arriving much
earlier and waiting unnecessarily at the destination.

Note that the output of this function includes more information with
additional columns, like in the
[`expanded_travel_time_matrix()`](https://ipeagit.github.io/r5r/dev/reference/expanded_travel_time_matrix.md)
function (you can also use `breakdown = TRUE`).

*A general call to arrival_travel_time_matrix()*

``` r

arrival_datetime <- as.POSIXct(
 "13-05-2019 14:00:00",
 format = "%d-%m-%Y %H:%M:%S"
)

arrival_ttm <- arrival_travel_time_matrix(
  r5r_network,
  origins = points,
  destinations = points,
  mode = c("WALK", "TRANSIT"),
  arrival_datetime = arrival_datetime,
  max_trip_duration = 60
)

head(arrival_ttm, n = 10)
#>           from_id                     to_id departure_time draw_number  routes
#>            <char>                    <char>         <char>       <int>  <char>
#>  1: public_market             public_market       13:59:00           1  [WALK]
#>  2: public_market       bus_central_station       13:46:00           1  LINHA1
#>  3: public_market          gasometer_museum       13:46:00           1    2441
#>  4: public_market       santa_casa_hospital       13:46:00           1  [WALK]
#>  5: public_market                  townhall       13:56:00           1  [WALK]
#>  6: public_market           piratini_palace       13:45:00           1  [WALK]
#>  7: public_market    metropolitan_cathedral       13:44:00           1  [WALK]
#>  8: public_market          farroupilha_park       13:40:00           1     R41
#>  9: public_market moinhos_de_vento_hospital       13:36:00           1 731|637
#> 10: public_market          farrapos_station       13:36:00           1  LINHA1
#>     total_time
#>          <num>
#>  1:        0.0
#>  2:       12.8
#>  3:       10.7
#>  4:       13.6
#>  5:        3.2
#>  6:       14.9
#>  7:       15.5
#>  8:       16.5
#>  9:       20.2
#> 10:       16.5
```

#### Cleaning up after usage

`r5r` objects are still allocated to any amount of memory previously set
after they are done with their calculations. In order to remove an
existing `r5r` object and reallocate the memory it had been using, we
use the `stop_r5` function followed by a call to Java’s garbage
collector, as follows:

``` r
r5r::stop_r5(r5r_network)
rJava::.jgc(R.gc = TRUE)
```

If you have any suggestions or want to report an error, please visit
[the package GitHub page](https://github.com/ipeaGIT/r5r).

### References
