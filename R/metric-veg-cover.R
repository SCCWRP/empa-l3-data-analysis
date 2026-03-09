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
#' @param vegetation_sample_metadata A cleaned metadata data frame in long
#'   format (output of \code{\link{clean_veg_metadata}}).
#' @param missing_val Numeric. Sentinel value for missing cover data. Default
#'   -88.
#' @param function_name Character. Function label ("Plant" or "SLR"). Default
#'   "Plant". This metric is shared between both functions.
#' @param year Numeric or character vector of years to include, or "all".
#'   Default "all".
#' @param season Character vector of seasons to include, or "all". Default
#'   "all".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_veg_cover <- function(
  vegetation_sample_metadata,
  missing_val   = -88,
  function_name = "Plant",
  year          = "all",
  season        = "all"
) {
  metadata <- vegetation_sample_metadata
  if (!identical(year, "all")) {
    metadata <- dplyr::filter(metadata, .data$calendar_year %in% as.character(year))
  }
  if (!identical(season, "all")) {
    metadata <- dplyr::filter(metadata, .data$Season %in% season)
  }

  veg_cover <- metadata |>
    dplyr::filter(.data$cover_value != missing_val) |>
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
      names_from  = cover_type,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_cover |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = "vegetation",
      metric_name    = "veg_cover",
      metric_score   = vegetated_cover
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
