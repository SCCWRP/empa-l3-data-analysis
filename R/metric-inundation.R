#' @title Metric: Marsh Plain Inundation
#' @description Computes marsh plain inundation scores per site (TBD).
#' @name metric-inundation
#' @importFrom dplyr mutate select distinct filter

#' Score Marsh Plain Inundation
#'
#' Placeholder metric for marsh plain inundation scoring. Currently returns
#' NA scores.
#'
#' @param veg A cleaned vegetation data frame (used for site list).
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "inundation".
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_marsh_plain_inundation <- function(
  veg,
  function_name = "Plant",
  indicator_name = "inundation",
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
      metric_name = "marsh_plain_inundation",
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
