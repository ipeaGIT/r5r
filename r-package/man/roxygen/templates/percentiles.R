#' @param percentiles An integer vector (max length of 5). Specifies the
#'   percentile to use when returning accessibility estimates within the given
#'   time window. Please note that this parameter is applied to the travel time
#'   estimates that generate the accessibility results, and not to the
#'   accessibility distribution itself (i.e. if the 25th percentile is
#'   specified, the accessibility is calculated from the 25th percentile travel
#'   time, which may or may not be equal to the 25th percentile of the
#'   accessibility distribution itself). Defaults to 50, returning the
#'   accessibility calculated from the median travel time. If a vector with
#'   length bigger than 1 is passed, the output contains an additional column
#'   that specifies the percentile of each accessibility estimate. Due to
#'   upstream restrictions, only 5 percentiles can be specified at a time. For
#'   more details, please see `R5` documentation at <https://docs.conveyal.com/analysis/methodology#accounting-for-variability>.
