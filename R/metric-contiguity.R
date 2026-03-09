#' @title Metric: Perimeter Contiguity
#' @description Computes the ratio of the largest contiguous open area to total
#'   open area around each site.
#' @name metric-contiguity
#' @importFrom dplyr filter select mutate
#' @importFrom tidyr pivot_wider

#' Score Perimeter Contiguity
#'
#' Divides the largest contiguous open patch by total open area and multiplies
#' by 100. Higher values mean less fragmented open space.
#'
#' @param gis_data A data frame as returned by \code{\link{load_gis_data}}.
#' @param largest_col Character. Landcover label for the largest contiguous
#'   patch. Default "Largest Contiguous".
#' @param total_col Character. Landcover label for total open area. Default
#'   "Total Open".
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_perimeter_contiguity <- function(
  gis_data,
  largest_col = "Largest Contiguous",
  total_col = "Total Open"
) {
  gis_data |>
    dplyr::filter(.data$landcover %in% c(largest_col, total_col)) |>
    dplyr::select(estuaryname, siteid, landcover, rastercount) |>
    tidyr::pivot_wider(
      names_from = landcover,
      values_from = rastercount
    ) |>
    dplyr::mutate(
      function_name = "SLR",
      indicator_name = "resiliency",
      metric_name = "perimeter_contiguity",
      metric_score = dplyr::if_else(
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
