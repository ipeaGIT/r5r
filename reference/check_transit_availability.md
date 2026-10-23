# Check transit service availability by date

Counts the public transport services in the GTFS feeds of a
`r5r_network` that are active on given dates, and their proportion of
all services. Use it to pick a departure date with adequate service:
public transport routing only finds trips on dates when services run
(per the GTFS calendars and date exceptions).

## Usage

``` r
check_transit_availability(
  r5r_network,
  dates = NULL,
  start_date = NULL,
  end_date = NULL,
  r5r_core = deprecated()
)
```

## Arguments

- r5r_network:

  A routable transport network created with
  [`build_network()`](https://ipea.github.io/r5r/reference/build_network.md).

- dates:

  A vector of specific dates to be checked. Can be character strings in
  "YYYY-MM-DD" format, or objects of class `Date`. This argument cannot
  be used with `start_date` or `end_date`. Defaults to `NULL`; when all
  date arguments are `NULL`, operating dates are discovered from the
  network.

- start_date:

  The start date for a continuous date range. Must be a single character
  string in "YYYY-MM-DD" format or a `Date` object. Must be used with
  `end_date`.

- end_date:

  The end date for a continuous date range. Must be a single character
  string in "YYYY-MM-DD" format or a `Date` object. Must be used with
  `start_date`.

- r5r_core:

  The `r5r_core` argument is deprecated as of r5r v2.3.0. Use the
  `r5r_network` argument instead.

## Value

A `data.table` with four columns: `date`, `total_services`,
`active_services`, and `pct_active` (the proportion of active services).
Automatic discovery returns dates in ascending order, or a zero-row
table with these columns if no retained transit trips operate.

## Details

When no date arguments are supplied, the function discovers all dates
with an active service referenced by a retained transit trip, including
frequency-based trips. This accounts for weekday calendars and date
exceptions, including exception-only services. A date with active
service does not guarantee a trip at every departure time or between
every pair of points.

You can also specify the dates to check in two ways:

- Using the `dates` argument to provide a vector of specific dates.

- Using the `start_date` and `end_date` arguments to provide a
  continuous date range.

You cannot combine these methods. In all modes, `total_services` counts
every imported service, not only those used by trips; counts are of
services, not trips. If calendar bounds are invalid, automatic discovery
reports the affected service; explicit date queries remain available.

## Examples

``` r
library(r5r)
data_path <- system.file("extdata/poa", package = "r5r")
r5r_network <- build_network(data_path)
#> ℹ Using cached network from
#>   /home/runner/work/_temp/Library/r5r/extdata/poa/network.dat.

# Discover operating dates without knowing the feed's date range
availability1 <- check_transit_availability(r5r_network)
head(availability1)
#>          date total_services active_services  pct_active
#>        <Date>          <int>           <int>       <num>
#> 1: 2019-03-01            118               1 0.008474576
#> 2: 2019-03-02            118               1 0.008474576
#> 3: 2019-03-03            118               1 0.008474576
#> 4: 2019-03-04            118               1 0.008474576
#> 5: 2019-03-05            118               1 0.008474576
#> 6: 2019-03-06            118               1 0.008474576
# plot availability over the year
library(ggplot2)
ggplot(availability1, aes(x = date, y = pct_active)) +
  geom_line() +
  geom_point() +
  theme_classic(base_size = 16)


# Example 2: Check a vector of specific dates
# Let's check a regular weekday and a Sunday, where service may differ.
dates_to_check <- c("2019-05-13", "2019-05-19")
availability2 <- check_transit_availability(
  r5r_network,
  dates = dates_to_check
)
head(availability2)
#>          date total_services active_services  pct_active
#>        <Date>          <int>           <int>       <num>
#> 1: 2019-05-13            118             116 0.983050847
#> 2: 2019-05-19            118               1 0.008474576

# Example 3: Check a continuous date range using start_date and end_date
availability3 <- check_transit_availability(
  r5r_network,
  start_date = "2019-01-01",
  end_date = "2019-12-31"
)
availability3[121:124,]
#>          date total_services active_services  pct_active
#>        <Date>          <int>           <int>       <num>
#> 1: 2019-05-01            118              62 0.525423729
#> 2: 2019-05-02            118             116 0.983050847
#> 3: 2019-05-03            118             116 0.983050847
#> 4: 2019-05-04            118               1 0.008474576


stop_r5(r5r_network)
#> r5r_network has been successfully stopped.
```
