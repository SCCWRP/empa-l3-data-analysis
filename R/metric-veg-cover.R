#' @title Metric: Vegetated Cover
#' @description Computes the percentage of vegetated vs non-vegetated cover
#'   per site from metadata.
#' @name metric-veg-cover
#' @importFrom dplyr filter group_by summarise mutate select
#' @importFrom tidyr pivot_wider

#' Score Vegetated Cover
#'
#' Sums vegetated and non-vegetated cover across all plots per site, then
#' calculates the percentage that is vegetated.
#'
#' @param metadata A cleaned veg metadata data frame (long format).
#' @param function_name Character. Default "Plant".
#' @param indicator_name Character. Default "vegetation".
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_veg_cover <- function(
  metadata,
  function_name = "Plant",
  indicator_name = "vegetation",
  year = "all",
  season = "all",
  config = get_config()
) {
  missing_val <- config$scoring$missing_data_value

  if (!identical(year, "all")) {
    metadata <- dplyr::filter(metadata, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    metadata <- dplyr::filter(metadata, .data$Season %in% season)
  }

  veg_cover <- metadata |>
    dplyr::filter(
      .data$siteid != "NA",
      .data$cover_value != missing_val,
      .data$estuaryname != "NA"
    ) |>
    dplyr::group_by(estuaryname, siteid, cover_type) |>
    dplyr::summarise(
      total_cover = sum(cover_value, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(siteid) |>
    dplyr::mutate(
      relative_abundance = round(total_cover / sum(total_cover) * 100, 1)
    ) |>
    dplyr::select(estuaryname, siteid, cover_type, relative_abundance) |>
    tidyr::pivot_wider(
      names_from = cover_type,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_cover |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "veg_cover",
      metric_score = vegetated_cover
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
