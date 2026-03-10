#' @title Metric: Vegetated Cover
#' @description Computes the percentage of vegetated vs non-vegetated cover
#'   per site from metadata.
#' @name metric-veg-cover
NULL

#' Score Vegetated Cover
#'
#' Extracts year from \code{samplecollectiondate}, filters to the requested
#' year(s), removes missing data sentinel (\code{-88}), then sums
#' \code{vegetated_cover} and \code{non_vegetated_cover} across all plots per
#' site and year. \code{metric_score} = vegetated cover as a percentage of
#' total cover. One output block is produced per value of \code{function_name}.
#'
#' @param vegetation_sample_metadata A raw vegetation sample metadata data frame
#'   with columns \code{estuaryname}, \code{siteid},
#'   \code{samplecollectiondate}, \code{vegetated_cover},
#'   \code{non_vegetated_cover}.
#' @param function_name Character vector. One or both of \code{"Plant"} and
#'   \code{"SLR"}. One output block is produced per value. Default
#'   \code{c("Plant", "SLR")}.
#' @param indicator_name Character. Indicator label. Default \code{"vegetation"}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @return A data frame with columns: estuaryname, siteid, year, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_veg_cover <- function(
  vegetation_sample_metadata,
  function_name = c("Plant", "SLR"),
  indicator_name = "vegetation",
  year = "all"
) {
  missing_val <- -88

  meta <- vegetation_sample_metadata |>
    dplyr::mutate(year = as.character(substr(samplecollectiondate, 1, 4)))

  if (!identical(year, "all")) {
    meta <- dplyr::filter(meta, .data$year %in% as.character(year))
  }

  scored <- meta |>
    dplyr::filter(
      .data$vegetated_cover != missing_val,
      .data$non_vegetated_cover != missing_val
    ) |>
    dplyr::group_by(estuaryname, siteid, year) |>
    dplyr::summarise(
      total_vegetated     = sum(vegetated_cover, na.rm = TRUE),
      total_non_vegetated = sum(non_vegetated_cover, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      indicator_name = indicator_name,
      metric_name    = "veg_cover",
      metric_score   = round(
        total_vegetated / (total_vegetated + total_non_vegetated) * 100, 1
      )
    )

  dplyr::bind_rows(lapply(function_name, function(fn) {
    dplyr::mutate(scored, function_name = fn)
  })) |>
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
