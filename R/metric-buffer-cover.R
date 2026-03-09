#' @title Metric: Buffer Land Cover
#' @description Computes percentage of natural land cover within a buffer
#'   distance around each site.
#' @name metric-buffer-cover
#' @importFrom dplyr filter mutate case_when group_by summarise select

#' Score Buffer Cover
#'
#' Filters GIS buffer data to the specified buffer distance, groups landcover
#' into natural (Ag + Natural) vs developed, and returns the natural percentage.
#' Called twice: once for the 500 m buffer (\code{metric_name = "buffer_cover"})
#' and once for the 30 m buffer (\code{metric_name = "perimeter_land_cover"}).
#'
#' @param gis_data A GIS buffer land cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{buffer}, \code{landcover},
#'   \code{percent}.
#' @param buffer_size Character. Buffer distance to filter on (e.g. \code{"500 m"},
#'   \code{"30 m"}).
#' @param metric_name Character. Name for this metric in the output. Default
#'   \code{"buffer_cover"}.
#' @param function_name Character. Function label. Default \code{"SLR"}.
#' @param indicator_name Character. Indicator label. Default \code{"resiliency"}.
#' @param natural_classes Character vector. Landcover classes counted as
#'   natural. Default \code{c("Ag", "Natural")}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_buffer_cover <- function(
  gis_data,
  buffer_size,
  metric_name = "buffer_cover",
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
      metric_name    = metric_name
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
