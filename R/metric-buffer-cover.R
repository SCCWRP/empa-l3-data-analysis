#' @title Metric: Buffer Land Cover
#' @description Computes percentage of natural land cover within a buffer
#'   distance around each site.
#' @name metric-buffer-cover
#' @importFrom dplyr filter mutate case_when group_by summarise select

#' Score Buffer Cover
#'
#' Aggregates buffer land cover into natural (Agricultural + Natural) vs
#' Developed, and returns the natural percentage.
#'
#' @param gis_data A data frame as returned by \code{\link{load_gis_data}}.
#' @param buffer_size Character. Buffer distance (e.g. "500 m", "30 m").
#' @param metric_name Character. Name for the metric. Default "buffer_cover".
#' @param function_name Character. Default "SLR".
#' @param indicator_name Character. Default "resiliency".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_buffer_cover <- function(
  gis_data,
  buffer_size,
  metric_name = "buffer_cover",
  function_name = "SLR",
  indicator_name = "resiliency",
  config = get_config()
) {
  natural_classes <- unlist(config$scoring$natural_landcover_classes)

  gis_data |>
    dplyr::filter(.data$buffer == buffer_size) |>
    dplyr::mutate(
      landcover_group = dplyr::case_when(
        .data$landcover %in% natural_classes ~ "natural",
        .data$landcover == "Developed" ~ "developed",
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
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = metric_name
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
