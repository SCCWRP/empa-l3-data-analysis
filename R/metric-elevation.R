#' @title Metric: Habitat Distribution (Elevation)
#' @description Computes current and future wetland extent percentages from
#'   habitat zone data.
#' @name metric-elevation
#' @importFrom dplyr select filter group_by mutate across all_of
#' @importFrom tidyr pivot_wider

#' Score Current Habitat Distribution
#'
#' Filters to the "Current Wetland Footprint" extent and sums the percent cover
#' of Low, Mid, and High marsh zones.
#'
#' @param wetland A data frame as returned by \code{\link{load_wetland_extents}}.
#' @param function_name Character. Default "SLR".
#' @param indicator_name Character. Default "resiliency".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_current_extent <- function(
  wetland,
  function_name = "SLR",
  indicator_name = "resiliency",
  config = get_config()
) {
  score_elevation_extent(
    wetland,
    "current_extent",
    function_name,
    indicator_name,
    config
  )
}

#' Score Future Habitat Distribution
#'
#' Filters to the "Wetland Migration/Avoid Developed (1.2 ft)" extent and sums
#' the percent cover of Low, Mid, and High marsh zones.
#'
#' @param wetland A data frame as returned by \code{\link{load_wetland_extents}}.
#' @param function_name Character. Default "SLR".
#' @param indicator_name Character. Default "resiliency".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_future_extent <- function(
  wetland,
  function_name = "SLR",
  indicator_name = "resiliency",
  config = get_config()
) {
  score_elevation_extent(
    wetland,
    "future_extent",
    function_name,
    indicator_name,
    config
  )
}

# Internal helper shared by current and future extent scoring
score_elevation_extent <- function(
  wetland,
  extent_key,
  function_name,
  indicator_name,
  config
) {
  extent_map <- unlist(config$scoring$elevation_extent_mapping)
  sum_zones <- unlist(config$scoring$wetland_sum_zones)

  cover_num_col <- if ("cover_number" %in% names(wetland)) {
    "cover_number"
  } else {
    "Cover_number"
  }
  cover_col <- if ("cover_class" %in% names(wetland)) {
    "cover_class"
  } else {
    "Cover_class"
  }
  pct_col <- if ("percent_cover" %in% names(wetland)) {
    "percent_cover"
  } else {
    "Percent_cover"
  }
  extent_col <- if ("extent" %in% names(wetland)) "extent" else "Extent"

  target_extent <- names(extent_map[extent_map == extent_key])

  wetland |>
    dplyr::select(-dplyr::all_of(cover_num_col)) |>
    dplyr::filter(.data[[extent_col]] == target_extent) |>
    dplyr::group_by(estuaryname, siteid) |>
    tidyr::pivot_wider(
      names_from = dplyr::all_of(cover_col),
      values_from = dplyr::all_of(pct_col),
      values_fill = 0
    ) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = extent_key,
      metric_score = rowSums(
        dplyr::across(dplyr::all_of(sum_zones)),
        na.rm = TRUE
      ) *
        100
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
