#' @title Metric: Marsh Plain Inundation
#' @description Computes marsh plain inundation scores per site (TBD).
#' @name metric-inundation
#' @importFrom dplyr mutate select distinct filter

#' Score Marsh Plain Inundation
#'
#' Placeholder metric for marsh plain inundation scoring. Currently returns
#' NA scores.
#'
#' @param vegetativecover_data A cleaned vegetation data frame (output of
#'   \code{\link{clean_veg}}).
#' @param year Numeric or character vector of years to include, or "all".
#'   Default "all".
#' @param season Character vector of seasons to include, or "all". Default
#'   "all".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_marsh_plain_inundation <- function(
  vegetativecover_data,
  year   = "all",
  season = "all"
) {
  veg <- vegetativecover_data
  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% as.character(year))
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg |>
    dplyr::distinct(estuaryname, siteid) |>
    dplyr::mutate(
      function_name  = "Plant",
      indicator_name = "inundation",
      metric_name    = "marsh_plain_inundation",
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
