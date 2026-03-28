# initial message about ram memory
.onAttach <- function(lib, pkg) { # nocov start
  msg <- cli::format_inline(
    "Please make sure you have already allocated some memory to Java by running
    {.code options(java.parameters = '-Xmx2G')} *before* loading library(r5r)

    You should replace {.val 2G} by the amount of memory you'll need.
    Currently, Java memory is set to {.val {getOption('java.parameters')}}."
  )

  packageStartupMessage(msg)
  } # nocov end

# package global variables
r5r_env <- new.env(parent = emptyenv())
