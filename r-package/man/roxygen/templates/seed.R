#' @param seed An integer or `NULL`. The seed of the Monte Carlo draws of the
#'   departure offsets of frequency-based transit routes. Defaults to `NULL`,
#'   in which case the draws are random and results may vary slightly between
#'   runs. With an integer, the same inputs always give the same results,
#'   regardless of `n_threads`. Results are still a Monte Carlo sample, so a
#'   different seed may give slightly different results: report the seed used
#'   and check how sensitive the results are to it. Note that `set.seed()` has
#'   no effect on these draws. This parameter only affects the results when the
#'   GTFS feeds contain a `frequencies.txt` table.<%= if (exists("seed_mcraptor")) " The departure times sampled within `time_window` are already fixed for each origin; `seed` only controls the departure offsets of frequency-based routes." else "" %>
