#' @title Metric: CRAM Index
#' @description Computes a normalized 0-100 CRAM index score per site.
#' @name metric-cram-index
#' @importFrom dplyr mutate select filter

#' Score CRAM Index
#'
#' Normalizes EMPA_index from a 25-100 scale to 0-100 using:
#' \code{((EMPA_index - 25) / 75) * 100}.
#'
#' @param cram A data frame with columns \code{estuaryname}, \code{siteid},
#'   \code{EMPA_index}.
#' @param function_name Character. Function label (e.g. "Plant", "SLR").
#' @param indicator_name Character. Indicator label. Default "habitat".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_cram_index <- function(
  cram,
  function_name,
  indicator_name = "habitat",
  config = get_config()
) {
  cram_min <- config$scoring$cram_min
  cram_range <- config$scoring$cram_range

  cram |>
    dplyr::filter(!is.na(siteid)) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "index",
      metric_score = round(
        ((EMPA_index - cram_min) / cram_range) * 100,
        digits = 1
      )
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
