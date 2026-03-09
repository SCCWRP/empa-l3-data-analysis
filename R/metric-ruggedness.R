#' @title Metric: Ruggedness
#' @description Passes through the pre-computed surface ruggedness index per
#'   site.
#' @name metric-ruggedness
#' @importFrom dplyr mutate select

#' Score Ruggedness
#'
#' Passes the pre-computed surface ruggedness index directly through with no
#' transformation. Higher values indicate greater topographic complexity.
#' This is a static metric — no year variation.
#'
#' @param rugged A data frame with columns \code{estuaryname}, \code{siteid},
#'   and \code{ruggedness}.
#' @param function_name Character. Function label. Default \code{"Plant"}.
#' @param indicator_name Character. Indicator label. Default \code{"elevation"}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_ruggedness <- function(
  rugged,
  function_name = "Plant",
  indicator_name = "elevation"
) {
  rugged |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name,
      metric_name    = "ruggedness",
      metric_score   = ruggedness
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
