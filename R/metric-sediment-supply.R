#' @title Metric: Sediment Supply
#' @description Computes sediment accretion/supply scores per site (TBD).
#' @name metric-sediment-supply
#' @importFrom dplyr mutate select distinct filter

#' Score Sediment Supply
#'
#' Placeholder metric for sediment supply scoring. Currently returns NA scores.
#'
#' @param cram A CRAM data frame (used for site list).
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_sediment_supply <- function(cram) {
  cram |>
    dplyr::filter(!is.na(.data$siteid)) |>
    dplyr::distinct(estuaryname, siteid) |>
    dplyr::mutate(
      function_name  = "SLR",
      indicator_name = "accretion",
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
