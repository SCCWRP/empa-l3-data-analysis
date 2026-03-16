#' @title Metric: Sediment Supply
#' @description Placeholder — sediment supply scoring not yet implemented.
#' @name metric-sediment-supply
NULL

#' Score Sediment Supply
#'
#' Placeholder metric. Returns \code{NA} scores for all sites.
#'
#' @param vegetativecover_data A vegetation data frame used to obtain the site
#'   list — columns \code{estuaryname}, \code{siteid}.
#' @param function_name Character. Function label. Default \code{"SLR"}.
#' @param indicator_name Character. Indicator label. Default \code{"accretion"}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score (all NA).
#' @export
score_sediment_supply <- function(
  vegetativecover_data,
  function_name = "SLR",
  indicator_name = "accretion"
) {
  vegetativecover_data |>
    dplyr::filter(!is.na(.data$siteid)) |>
    dplyr::distinct(estuaryname, siteid) |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name,
      metric_name    = "sediment_supply",
      metric_score   = NA_real_
    ) |>
    dplyr::select(
      estuaryname,
      siteid,
      function_name,
      indicator_name,
      metric_name,
      metric_score
    )
}
