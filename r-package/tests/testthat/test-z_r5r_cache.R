context("r5r_cache")

# skip tests because they take too much time
skip_if(Sys.getenv("TEST_ONE") != "")
testthat::skip_on_cran()

try(silent = TRUE, r5r::stop_r5())

# Reading the data -----------------------

test_that("r5r_cache", {

  # simply list files
  testthat::expect_message( r5r::r5r_cache() )

  ## delete existing

  # download
  r5r::download_r5(force_update = FALSE)

  # cache dir
  cache_d <- paste0('r5r/r5_jar_v', "7.1.0")
  cache_dir <- tools::R_user_dir(cache_d, which = 'cache')

  # list cached files
  fname_full <- list.files(cache_dir, full.names = TRUE)
  fname <- basename(fname_full)

  testthat::expect_true( file.exists(fname_full) )
  testthat::expect_message( r5r::r5r_cache(delete_file = fname) )
  # testthat::expect_false( file.exists(fname_full) )

  ## delete ALL
  # download
  r5r::download_r5(force_update = FALSE)

  testthat::expect_true( file.exists(fname_full) )
  testthat::expect_message( r5r::r5r_cache(delete_file = 'all') )
  # testthat::expect_true( length(list.files(cache_dir)) == 0 )

  # if file does not exist, simply print message
  testthat::expect_message( r5r::r5r_cache(delete_file ='aaa') )

 })


# ERRORS and messages  -----------------------
test_that("r5r_cache", {

  testthat::expect_error(r5r_cache(list_files= 999))
  testthat::expect_error(r5r_cache(delete_file = 999))
  })


# clean cache
r5r_cache(delete_file = 'all')
