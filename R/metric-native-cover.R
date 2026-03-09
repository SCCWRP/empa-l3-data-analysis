#' @title Metric: Native Cover
#' @description Computes the percentage of plant cover that is native per site.
#' @name metric-native-cover
#' @importFrom dplyr filter group_by summarise mutate select
#' @importFrom tidyr pivot_wider

#' Score Native Cover
#'
#' Filters out excluded statuses and missing data, then computes relative
#' abundance of native species as a percentage of total cover.
#'
#' @param vegetativecover_data A cleaned vegetation data frame (output of
#'   \code{\link{clean_veg}}).
#' @param missing_val Numeric. Sentinel value for missing cover data. Default
#'   -88.
#' @param exclude_statuses Character vector. Status values to exclude from the
#'   relative abundance calculation. Default \code{c("Not recorded",
#'   "naturalized")}.
#' @param year Numeric or character vector of years to include, or "all".
#'   Default "all".
#' @param season Character vector of seasons to include, or "all". Default
#'   "all".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_native_cover <- function(
  vegetativecover_data,
  missing_val       = -88,
  exclude_statuses  = c("Not recorded", "naturalized"),
  year              = "all",
  season            = "all"
) {
  veg <- vegetativecover_data
  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% as.character(year))
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg_relative <- veg |>
    dplyr::filter(
      !is.na(.data$status),
      !.data$status %in% exclude_statuses,
      .data$estimatedcover != missing_val
    ) |>
    dplyr::group_by(estuaryname, siteid, status) |>
    dplyr::summarise(
      total_cover = sum(estimatedcover, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(siteid) |>
    dplyr::mutate(
      relative_abundance = round(total_cover / sum(total_cover) * 100, 1)
    ) |>
    dplyr::select(estuaryname, siteid, status, relative_abundance) |>
    tidyr::pivot_wider(
      names_from  = status,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_relative |>
    dplyr::mutate(
      function_name  = "Plant",
      indicator_name = "vegetation",
      metric_name    = "native_cover",
      metric_score   = native
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
