#' @title Metric: Habitat Distribution (Elevation)
#' @description Computes current and future wetland extent percentages from
#'   habitat zone data.
#' @name metric-elevation
#' @importFrom dplyr select filter group_by mutate across all_of
#' @importFrom tidyr pivot_wider

#' Score Current Habitat Distribution
#'
#' Filters to the current wetland footprint extent and sums the percent cover
#' of the specified marsh zones.
#'
#' @param wetland A data frame as returned by \code{\link{load_wetland_extents}}.
#' @param target_extent Character. The extent label to filter on. Default
#'   \code{"Current Wetland Footprint"}.
#' @param sum_zones Character vector. Cover class zones to sum. Default
#'   \code{c("Low", "Mid", "High")}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_current_extent <- function(
  wetland,
  target_extent = "Current Wetland Footprint",
  sum_zones = c("Low", "Mid", "High")
) {
  score_elevation_extent(
    wetland,
    target_extent = target_extent,
    metric_name = "current_habitat_distribution",
    sum_zones = sum_zones
  )
}

#' Score Future Habitat Distribution
#'
#' Filters to the sea level rise migration extent and sums the percent cover
#' of the specified marsh zones.
#'
#' @param wetland A data frame as returned by \code{\link{load_wetland_extents}}.
#' @param target_extent Character. The extent label to filter on. Default
#'   \code{"Wetland Migration/Avoid Developed (1.2 ft)"}.
#' @param sum_zones Character vector. Cover class zones to sum. Default
#'   \code{c("Low", "Mid", "High")}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_future_extent <- function(
  wetland,
  target_extent = "Wetland Migration/Avoid Developed (1.2 ft)",
  sum_zones = c("Low", "Mid", "High")
) {
  score_elevation_extent(
    wetland,
    target_extent = target_extent,
    metric_name = "future_habitat_distribution",
    sum_zones = sum_zones
  )
}

# Internal helper shared by current and future extent scoring
score_elevation_extent <- function(wetland, target_extent, metric_name, sum_zones) {
  cover_num_col <- if ("cover_number" %in% names(wetland)) "cover_number" else "Cover_number"
  cover_col     <- if ("cover_class"  %in% names(wetland)) "cover_class"  else "Cover_class"
  pct_col       <- if ("percent_cover" %in% names(wetland)) "percent_cover" else "Percent_cover"
  extent_col    <- if ("extent" %in% names(wetland)) "extent" else "Extent"

  wetland |>
    dplyr::select(-dplyr::all_of(cover_num_col)) |>
    dplyr::filter(.data[[extent_col]] == target_extent) |>
    dplyr::group_by(estuaryname, siteid) |>
    tidyr::pivot_wider(
      names_from  = dplyr::all_of(cover_col),
      values_from = dplyr::all_of(pct_col),
      values_fill = 0
    ) |>
    dplyr::mutate(
      function_name  = "SLR",
      indicator_name = "resiliency",
      metric_name    = metric_name,
      metric_score   = rowSums(dplyr::across(dplyr::all_of(sum_zones)), na.rm = TRUE) * 100
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
