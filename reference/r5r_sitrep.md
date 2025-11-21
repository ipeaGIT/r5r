# Generate an r5r situation report to help debug errors

The function reports a list with the following information:

- The package version of `{r5r}` in use.

- The installed version of `R5.jar`.

- The Java version in use.

- The amount of memory set to Java through the `java.parameters` option.

- The user's Session Info.

## Usage

``` r
r5r_sitrep()
```

## Value

A `list` with information of the versions of the r5r package, Java and
R5 Jar in use, the memory set to Java and user's Session Info.

## Examples

``` r
r5r_sitrep()
#> $r5r_package_version
#> [1] ‘2.3.999’
#> 
#> $r5_jar_version
#> [1] "7.4"
#> 
#> $java_version
#> [1] "21.0.9"
#> 
#> $set_memory
#> [1] "-Xmx2G"
#> 
#> $session_info
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 22.04.5 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.20.so;  LAPACK version 3.10.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8          LC_NUMERIC=C             
#>  [3] LC_TIME=C.UTF-8           LC_COLLATE=C             
#>  [5] LC_MONETARY=C.UTF-8       LC_MESSAGES=C.UTF-8      
#>  [7] LC_PAPER=C.UTF-8          LC_NAME=C.UTF-8          
#>  [9] LC_ADDRESS=C.UTF-8        LC_TELEPHONE=C.UTF-8     
#> [11] LC_MEASUREMENT=C.UTF-8    LC_IDENTIFICATION=C.UTF-8
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] ggplot2_4.0.1 r5r_2.3.0999 
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       xfun_0.54          bslib_0.9.0        httr2_1.2.1       
#>  [5] htmlwidgets_1.6.4  processx_3.8.6     rJava_1.0-11       callr_3.7.6       
#>  [9] vctrs_0.6.5        tools_4.5.2        ps_1.9.1           generics_0.1.4    
#> [13] curl_7.0.0         proxy_0.4-27       tibble_3.3.0       fansi_1.0.7       
#> [17] sfheaders_0.4.4    pkgconfig_2.0.3    KernSmooth_2.23-26 data.table_1.17.8 
#> [21] checkmate_2.3.3    RColorBrewer_1.1-3 S7_0.2.1           desc_1.4.3        
#> [25] lifecycle_1.0.4    compiler_4.5.2     farver_2.1.2       brio_1.1.5        
#> [29] textshaping_1.0.4  fontawesome_0.5.3  class_7.3-23       htmltools_0.5.8.1 
#> [33] sass_0.4.10        yaml_2.3.10        pillar_1.11.1      pkgdown_2.2.0     
#> [37] jquerylib_0.1.4    whisker_0.4.1      openssl_2.3.4      classInt_0.4-11   
#> [41] cachem_1.1.0       wk_0.9.4           zip_2.3.3          tidyselect_1.2.1  
#> [45] digest_0.6.39      sf_1.0-22          dplyr_1.1.4        purrr_1.2.0       
#> [49] labeling_0.4.3     fastmap_1.2.0      grid_4.5.2         cli_3.6.5         
#> [53] magrittr_2.0.4     e1071_1.7-16       withr_3.0.2        scales_1.4.0      
#> [57] backports_1.5.0    rappdirs_0.3.3     rmarkdown_2.30     askpass_1.2.1     
#> [61] ragg_1.5.0         memoise_2.0.1      evaluate_1.0.5     knitr_1.50        
#> [65] testthat_3.3.0     s2_1.1.9           rlang_1.1.6        isoband_0.2.7     
#> [69] Rcpp_1.1.0         downlit_0.4.5      glue_1.8.0         DBI_1.2.3         
#> [73] xml2_1.5.0         rstudioapi_0.17.1  jsonlite_2.0.0     R6_2.6.1          
#> [77] rJavaEnv_0.3.0     units_1.0-0        systemfonts_1.3.1  fs_1.6.6          
#> 
```
