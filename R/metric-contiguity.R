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
#' @param function_name Character. Default "SLR".
#' @param indicator_name Character. Default "resiliency".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_perimeter_contiguity <- function(
  gis_data,
  function_name = "SLR",
  indicator_name = "resiliency",
  config = get_config()
) {
  contiguity_lc <- unlist(config$scoring$contiguity_landcovers)

  gis_data |>
    dplyr::filter(.data$landcover %in% contiguity_lc) |>
    dplyr::select(estuaryname, siteid, landcover, rastercount) |>
    tidyr::pivot_wider(
      names_from = landcover,
      values_from = rastercount
    ) |>
    dplyr::mutate(
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "perimeter_contiguity",
      metric_score = dplyr::if_else(
        `Total Open` > 0,
        round((`Largest Contiguous` / `Total Open`) * 100, 1),
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
