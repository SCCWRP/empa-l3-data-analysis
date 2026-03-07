#' @title Metric: Invasive Severity
#' @description Computes a native resiliency score based on invasive species
#'   penalties per site.
#' @name metric-invasive-severity
#' @importFrom dplyr filter distinct mutate group_by summarise select

#' Score Invasive Severity
#'
#' Starts at 100 and subtracts penalty points for each unique invasive species
#' found at a site, based on Cal-IPC rating. Score cannot go below 0.
#'
#' @param veg A cleaned vegetation data frame.
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "vegetation".
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param penalties Named numeric vector mapping ratings to penalty points.
#'   Defaults to \code{\link{invasive_penalty_mapping}()}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_invasive_severity <- function(
  veg,
  function_name = "Plant",
  indicator_name = "vegetation",
  year = "all",
  season = "all",
  penalties = invasive_penalty_mapping(),
  config = get_config()
) {
  base_score <- config$scoring$invasive_base_score

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg |>
    dplyr::filter(.data$siteid != "NA") |>
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
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "invasive_severity"
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
