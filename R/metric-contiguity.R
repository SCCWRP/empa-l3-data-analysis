#' @title Metric: Perimeter Contiguity
#' @description Computes the ratio of the largest contiguous open area to total
#'   open area around each site.
#' @name metric-contiguity
#' @importFrom dplyr filter select mutate
#' @importFrom tidyr pivot_wider

#' Score Perimeter Contiguity
#'
#' Filters GIS data to the "Largest Contiguous" and "Total Open" landcover rows,
#' pivots to wide format, then computes
#' \code{(Largest Contiguous / Total Open) * 100}. A higher score means the
#' open space surrounding the site is less fragmented.
#'
#' @param gis_data A GIS buffer land cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{landcover}, \code{rastercount}.
#' @param function_name Character. Function label. Default \code{"SLR"}.
#' @param indicator_name Character. Indicator label. Default \code{"resiliency"}.
#' @param largest_col Character. Landcover label for the largest contiguous
#'   patch. Default \code{"Largest Contiguous"}.
#' @param total_col Character. Landcover label for total open area. Default
#'   \code{"Total Open"}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_perimeter_contiguity <- function(
  gis_data,
  function_name = "SLR",
  indicator_name = "resiliency",
  largest_col = "Largest Contiguous",
  total_col = "Total Open"
) {
  gis_data |>
    dplyr::filter(.data$landcover %in% c(largest_col, total_col)) |>
    dplyr::select(estuaryname, siteid, landcover, rastercount) |>
    tidyr::pivot_wider(
      names_from  = landcover,
      values_from = rastercount
    ) |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name,
      metric_name    = "perimeter_contiguity",
      metric_score   = dplyr::if_else(
        .data[[total_col]] > 0,
        round((.data[[largest_col]] / .data[[total_col]]) * 100, 1),
        NA_real_
      )
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
