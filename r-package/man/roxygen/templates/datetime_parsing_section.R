#' @section Datetime parsing:
#'
#' `r5r` ignores the timezone attribute of datetime objects when parsing dates
#' and times, using the study area's timezone instead. For example, let's say
#' you are running some calculations using Rio de Janeiro, Brazil, as your study
#' area. The datetime `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S")` will be parsed as May 13th, 2019, 14:00h in
#' Rio's local time, as expected. But `as.POSIXct("13-05-2019 14:00:00",
#' format = "%d-%m-%Y %H:%M:%S", tz = "Europe/Paris")` will also be parsed as
#' the exact same date and time in Rio's local time, perhaps surprisingly,
#' ignoring the timezone attribute.
