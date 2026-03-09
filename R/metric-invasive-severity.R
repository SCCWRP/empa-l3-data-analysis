#' @title Metric: Invasive Severity
#' @description Computes a native resiliency score based on invasive species
#'   penalties per site.
#' @name metric-invasive-severity
#' @importFrom dplyr filter distinct mutate group_by summarise select

#' Score Invasive Severity
#'
#' Starts at \code{base_score} and subtracts penalty points for each unique
#' invasive species found at a site, based on Cal-IPC rating. Score cannot go
#' below 0.
#'
#' @param vegetativecover_data A cleaned vegetation data frame (output of
#'   \code{\link{clean_veg}}).
#' @param base_score Numeric. Starting score before penalties. Default 100.
#' @param penalties Named numeric vector mapping Cal-IPC rating labels to
#'   penalty points. Default \code{c(Limited = 5, Moderate = 10, High = 15)}.
#' @param year Numeric or character vector of years to include, or "all".
#'   Default "all".
#' @param season Character vector of seasons to include, or "all". Default
#'   "all".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_invasive_severity <- function(
  vegetativecover_data,
  base_score = 100,
  penalties  = c(Limited = 5, Moderate = 10, High = 15),
  year       = "all",
  season     = "all"
) {
  veg <- vegetativecover_data
  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% as.character(year))
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg |>
    dplyr::distinct(estuaryname, siteid, scientificname, rating) |>
    dplyr::mutate(
      penalty = dplyr::if_else(
        .data$rating %in% names(penalties),
        penalties[.data$rating],
        0
      )
    ) |>
    dplyr::group_by(estuaryname, siteid) |>
    dplyr::summarise(
      metric_score = pmax(base_score - sum(penalty), 0),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      function_name  = "Plant",
      indicator_name = "vegetation",
      metric_name    = "invasive_severity"
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
