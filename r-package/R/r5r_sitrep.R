#' Generate an r5r situation report to help debug errors
#'
#' @description
#' The function reports a list with the following information:
#'
#' - The package version of `{r5r}` in use.
#' - The installed version of `R5.jar`.
#' - The Java version in use.
#' - The amount of memory set to Java through the `java.parameters` option.
#' - The user's Session Info.
#'
#' @return A `list` with information of the versions of the r5r package, Java
#' and R5 Jar in use, the memory set to Java and user's Session Info.
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' r5r_sitrep()
#'
#' @export
r5r_sitrep <- function() {
  r5r_package_version <- utils::packageVersion("r5r")

  jar_dir <- r5r_env$cache_dir
  jar_dir_files <- list.files(jar_dir)
  jar_dir_files_full_names <- list.files(jar_dir, full.names = TRUE)

  r5r_jar <- jar_dir_files[grepl("r5r_\\d_\\d_\\d.*\\.jar", jar_dir_files)]

  r5r_jar_version <- r5r_env$r5_jar_version
  r5r_jar_path <- jar_dir_files_full_names[
    grepl("\\/r5r_\\d_\\d_\\d*\\.jar", jar_dir_files_full_names)
  ]

  r5_jar <- jar_dir_files[grepl("r5-v\\d\\.\\d.*\\.jar", jar_dir_files)]
  r5_jar_version <- substr(r5_jar, 5, 7)
  r5_jar_path <- jar_dir_files_full_names[
    grepl("\\/r5-v\\d\\.\\d.*\\.jar", jar_dir_files_full_names)
  ]

  rJava::.jinit()
  java_version <- rJava::.jcall(
    "java.lang.System",
    "S",
    "getProperty",
    "java.version"
  )

  set_memory <- getOption("java.parameters")

  output_list <- list(r5r_package_version,
                      r5_jar_version,
                      java_version,
                      # r5_jar_path,
                      # r5r_jar_path,
                      set_memory,
                     # jar_dir_files_full_names,
                      utils::sessionInfo())

  names(output_list) <- c('r5r_package_version',
                          'r5_jar_version',
                          'java_version',
                         # 'r5_jar_path',
                         # 'r5r_jar_path',
                          'set_memory',
                         # 'jar_dir_files_full_names',
                          'session_info'
                          )


  return(output_list)
}
