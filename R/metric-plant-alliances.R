#' @title Metric: Plant Alliances
#' @description Computes plant alliance scores per site (TBD).
#' @name metric-plant-alliances
#' @importFrom dplyr mutate select distinct

#' Score Plant Alliances
#'
#' Placeholder metric for plant alliance scoring. Currently returns NA scores.
#'
#' @param veg A cleaned vegetation data frame.
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "alliances".
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_plant_alliances <- function(
  veg,
  function_name = "Plant",
  indicator_name = "alliances",
  year = "all",
  season = "all",
  config = get_config()
) {
  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg |>
    dplyr::filter(.data$siteid != "NA") |>
    dplyr::distinct(estuaryname, siteid) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "plant_alliances",
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
