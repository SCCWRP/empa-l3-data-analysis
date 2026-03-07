#' @title Metric: Sediment Supply
#' @description Computes sediment accretion/supply scores per site (TBD).
#' @name metric-sediment-supply
#' @importFrom dplyr mutate select distinct filter

#' Score Sediment Supply
#'
#' Placeholder metric for sediment supply scoring. Currently returns NA scores.
#'
#' @param cram A CRAM data frame (used for site list).
#' @param function_name Character. Default "SLR".
#' @param indicator_name Character. Default "accretion".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_sediment_supply <- function(
  cram,
  function_name = "SLR",
  indicator_name = "accretion",
  config = get_config()
) {
  cram |>
    dplyr::filter(!is.na(siteid)) |>
    dplyr::distinct(estuaryname, siteid) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "sediment_supply",
      metric_score = NA_real_
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
