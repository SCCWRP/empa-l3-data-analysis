#' @title Metric: Perimeter Land Cover
#' @description Computes percentage of natural land cover within the 30 m
#'   perimeter buffer around each site.
#' @name metric-perimeter-land-cover
NULL

#' Score Perimeter Land Cover
#'
#' Filters GIS buffer data to the 30 m buffer, groups landcover into natural
#' (Ag + Natural) vs developed, and returns the natural percentage.
#'
#' @param gis_data A GIS buffer land cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{buffer}, \code{landcover},
#'   \code{percent}.
#' @param buffer_size Character. Buffer distance to filter on. Default
#'   \code{"30 m"}.
#' @param function_name Character. Function label. Default \code{"SLR"}.
#' @param indicator_name Character. Indicator label. Default \code{"resiliency"}.
#' @param natural_classes Character vector. Landcover classes counted as
#'   natural. Default \code{c("Ag", "Natural")}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_perimeter_land_cover <- function(
  gis_data,
  buffer_size = "30 m",
  function_name = "SLR",
  indicator_name = "resiliency",
  natural_classes = c("Ag", "Natural")
) {
  gis_data |>
    dplyr::filter(.data$buffer == buffer_size) |>
    dplyr::mutate(
      landcover_group = dplyr::case_when(
        .data$landcover %in% natural_classes ~ "natural",
        .data$landcover == "Developed"       ~ "developed",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(.data$landcover_group == "natural") |>
    dplyr::group_by(estuaryname, siteid) |>
    dplyr::summarise(
      metric_score = sum(percent, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name,
      metric_name    = "perimeter_land_cover"
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
