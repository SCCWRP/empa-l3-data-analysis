#' @title Metric: Future Habitat Distribution
#' @description Computes wetland extent percentage from the sea level rise
#'   migration extent.
#' @name metric-future-habitat-distribution
NULL

#' Score Future Habitat Distribution
#'
#' Filters to the sea level rise migration extent and sums the percent cover
#' of the specified marsh zones.
#'
#' @param wetland A wetland extents data frame with columns \code{estuaryname},
#'   \code{siteid}, \code{extent}, \code{cover_class}, \code{percent_cover}.
#' @param function_name Character. Function label. Default \code{"SLR"}.
#' @param indicator_name Character. Indicator label. Default \code{"resiliency"}.
#' @param target_extent Character. The extent label to filter on. Default
#'   \code{"Wetland Migration/Avoid Developed (1.2 ft)"}.
#' @param sum_zones Character vector. Cover class zones to sum. Default
#'   \code{c("Low", "Mid", "High")}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_future_habitat_distribution <- function(
  wetland,
  function_name = "SLR",
  indicator_name = "resiliency",
  target_extent = "Wetland Migration/Avoid Developed (1.2 ft)",
  sum_zones = c("Low", "Mid", "High")
) {
  score_elevation_extent(
    wetland,
    function_name = function_name,
    indicator_name = indicator_name,
    target_extent = target_extent,
    metric_name = "future_habitat_distribution",
    sum_zones = sum_zones
  )
}
