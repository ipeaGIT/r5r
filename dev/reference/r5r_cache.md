# Manage cached files from the r5r package

Manage cached files from the r5r package

## Usage

``` r
r5r_cache(list_files = TRUE, delete_file = NULL)
```

## Arguments

- list_files:

  Logical. Whether to print a message with the address of r5r JAR files
  cached locally. Defaults to `TRUE`.

- delete_file:

  String. The file name (basename) of a JAR file cached locally that
  should be deleted. Defaults to `NULL`, so that no file is deleted. If
  `delete_file = "all"`, then all cached files are deleted.

## Value

A message indicating which file exist and/or which ones have been
deleted from local cache directory.

## Examples

``` r
# download r5 JAR
r5r::download_r5()
#> Using cached R5 version from /home/runner/.cache/R/r5r/r5_jar_v7.4.0/r5-v7.4-all.jar
#> [1] "/home/runner/.cache/R/r5r/r5_jar_v7.4.0/r5-v7.4-all.jar"

# list all files cached
r5r_cache(list_files = TRUE)
#> Files currently cached:
#> /home/runner/.cache/R/r5r/r5_jar_v7.4.0/r5-v7.4-all.jar

# delete r5 JAR
r5r_cache(delete_file = 'r5-v7.0')
#> The file 'r5-v7.0' is not cached.
#> Files currently cached:
#> /home/runner/.cache/R/r5r/r5_jar_v7.4.0/r5-v7.4-all.jar
```
