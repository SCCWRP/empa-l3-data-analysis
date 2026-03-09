#' @title Metric: Plant Alliances
#' @description Placeholder — plant alliance scoring not yet implemented.
#' @name metric-plant-alliances
#' @importFrom dplyr mutate select distinct filter

#' Score Plant Alliances
#'
#' Placeholder metric. Extracts year from \code{samplecollectiondate}, filters
#' to the requested year(s), and returns \code{NA} scores for all sites.
#'
#' @param vegetativecover_data A raw vegetation cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{samplecollectiondate}.
#' @param function_name Character. Function label. Default \code{"Plant"}.
#' @param indicator_name Character. Indicator label. Default \code{"alliances"}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @return A data frame with columns: estuaryname, siteid, year, function_name,
#'   indicator_name, metric_name, metric_score (all NA).
#' @export
score_plant_alliances <- function(
  vegetativecover_data,
  function_name = "Plant",
  indicator_name = "alliances",
  year = "all"
) {
  veg <- vegetativecover_data |>
    dplyr::mutate(year = as.character(substr(samplecollectiondate, 1, 4)))

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$year %in% as.character(year))
  }

  veg |>
    dplyr::distinct(estuaryname, siteid, year) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "plant_alliances",
      metric_score = NA_real_
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
