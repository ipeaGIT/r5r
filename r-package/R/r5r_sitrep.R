#' Generate an r5r situation report
#'
#' @description
#' The function reports:
#'
#' - The version of `{r5r}` in use. Is it the most up to date?
#' - The installed version of `r5r.jar`.
#' - The installed version of `R5.jar`.
#' - The Java version in use.
#' - The amount of memory set to Java through the `java.parameters` option.
#'
#' @return Invisibly returns `TRUE`.
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' r5r_sitrep()
#'
#' @export
r5r_sitrep <- function() {
  r5r_package_version <- utils::packageVersion("r5r")

  jar_dir <- system.file("jar", package = "r5r")
  jar_dir_files <- list.files(jar_dir)
  jar_dir_files_full_names <- list.files(jar_dir, full.names = TRUE)

  r5r_jar <- jar_dir_files[grepl("r5r_\\d_\\d_\\d.*\\.jar", jar_dir_files)]
  r5r_jar_version <- sub("\\.jar", "", sub("r5r_", "", r5r_jar))
  r5r_jar_version <- gsub("_", "\\.", r5r_jar_version)
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

  return(invisible(TRUE))
}
