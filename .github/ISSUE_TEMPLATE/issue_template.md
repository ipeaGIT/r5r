---
name: Bug report or feature request
about: Describe a bug you've seen or make a case for a new feature
---
When opening an issue, please mind the 3 steps below:

1) Briefly describe your problem and what output you expect. If you have a question, please don't use this form. Instead, ask on Stack Overflow <https://stackoverflow.com/>.

2) Include a minimal reproducible example. If necessary, you can use one of the sample data sets that come within the `r5r` package. See example below.

3) Run the `r5r::r5r_sitrep()` function to generate a situation report, and paste the output along with your issue. This will help us find eventual bugs.

### Brief description of the problem:
...


### Reproducible example here
```r
# insert reproducible example here

library(r5r)

# build transport network
data_path <- system.file("extdata/poa", package = "r5r")
r5r_core <- setup_r5(data_path = data_path, temp_dir = TRUE)

# load origin/destination points
points <- read.csv(file.path(data_path, "poa_hexgrid.csv"))



```







### Situation report here
```r
r5r::r5r_sitrep()


```

