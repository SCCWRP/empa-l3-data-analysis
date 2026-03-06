#' @title Metric: Ruggedness
#' @description Passes through the pre-computed surface ruggedness index per
#'   site.
#' @name metric-ruggedness
#' @importFrom dplyr mutate select

#' Score Ruggedness
#'
#' Takes the ruggedness value directly from the dataset with no further
#' calculation.
#'
#' @param rugged A data frame with columns \code{estuaryname}, \code{siteid},
#'   and \code{ruggedness} (or \code{Ruggedness}).
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "elevation".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_ruggedness <- function(
  rugged,
  function_name = "Plant",
  indicator_name = "elevation"
) {
  rug_col <- if ("Ruggedness" %in% names(rugged)) "Ruggedness" else "ruggedness"

  rugged |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "ruggedness",
      metric_score = .data[[rug_col]]
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
