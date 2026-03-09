#' @title Metric: Native Cover
#' @description Computes the percentage of plant cover that is native per site.
#' @name metric-native-cover
#' @importFrom dplyr filter group_by summarise mutate select distinct
#' @importFrom tidyr pivot_wider

#' Score Native Cover
#'
#' Filters to the requested year(s) (extracted from \code{samplecollectiondate}),
#' removes records with excluded statuses (\code{"Not recorded"}, \code{"naturalized"}),
#' missing data sentinel (\code{-88}), and unknown species. Sums
#' \code{estimatedcover} by site, year, and status, then calculates native
#' species as a percentage of total cover.
#'
#' @param vegetativecover_data A raw vegetation cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{samplecollectiondate},
#'   \code{status}, \code{scientificname}, \code{estimatedcover}.
#' @param function_name Character. Function label. Default \code{"Plant"}.
#' @param indicator_name Character. Indicator label. Default \code{"habitat"}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @return A data frame with columns: estuaryname, siteid, year, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_native_cover <- function(
  vegetativecover_data,
  function_name = "Plant",
  indicator_name = "vegetation",
  year = "all"
) {
  exclude_statuses <- c("Not recorded", "naturalized")
  missing_val <- -88

  veg <- vegetativecover_data |>
    dplyr::mutate(year = as.character(substr(samplecollectiondate, 1, 4)))

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$year %in% as.character(year))
  }

  veg_relative <- veg |>
    dplyr::filter(
      !is.na(.data$status),
      !.data$status %in% exclude_statuses,
      .data$estimatedcover != missing_val,
      !grepl("^unknown", .data$scientificname, ignore.case = TRUE)
    ) |>
    dplyr::group_by(estuaryname, siteid, year, status) |>
    dplyr::summarise(
      total_cover = sum(estimatedcover, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(siteid, year) |>
    dplyr::mutate(
      relative_abundance = round(total_cover / sum(total_cover) * 100, 1)
    ) |>
    dplyr::select(estuaryname, siteid, year, status, relative_abundance) |>
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
      metric_score = if ("native" %in% names(veg_relative)) native else NA_real_
    ) |>
    dplyr::select(
      estuaryname,
      siteid,
      year,
      function_name,
      indicator_name,
      metric_name,
      metric_score
    )
}
