#' @param new_carspeeds A `data.frame` specifying the speed modifications. The
#'    table must contain columns \code{osm_id} and \code{max_speed}. OR A
#'    `sf data.frame` specifying the speed modifications. The table must contain
#'    columns \code{sf polygon}, \code{scale}, \code{priority}. See `link to congestion vignette`.
#' @param carspeed_scale Numeric. Default speed to use for road segments not
#'        specified in `new_carspeeds`.
#' @param new_lts A `data.frame` specifying the LTS levels. The
#'        table must contain columns \code{osm_id} and \code{lts}.
