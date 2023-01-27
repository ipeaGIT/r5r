if (identical(tolower(Sys.getenv("NOT_CRAN")), "true")) {
  options(java.parameters = '-Xmx2G')

  library(testthat)
  library(r5r)

  test_check("r5r")
}
