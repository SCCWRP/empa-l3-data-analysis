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
#' @param veg A cleaned vegetation data frame.
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "vegetation".
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_native_cover <- function(
  veg,
  function_name = "Plant",
  indicator_name = "vegetation",
  year = "all",
  season = "all",
  config = get_config()
) {
  missing_val <- config$scoring$missing_data_value
  exclude_statuses <- unlist(config$scoring$veg_exclude_statuses)

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg_relative <- veg |>
    dplyr::filter(
      !is.na(.data$status),
      !.data$status %in% exclude_statuses,
      .data$siteid != "NA",
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
      names_from = status,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_relative |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "native_cover",
      metric_score = native
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
