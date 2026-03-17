#' @title Internal Utilities
#' @description Shared internal helper functions used across metric files.
#' @name utils
NULL

# Internal helper shared by score_current_extent() and score_future_extent()
score_elevation_extent <- function(
  wetland,
  function_name,
  indicator_name,
  target_extent,
  metric_name,
  sum_zones
) {
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
      metric_name = metric_name,
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
