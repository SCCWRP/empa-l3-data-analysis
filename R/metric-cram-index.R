#' @title Metric: CRAM Index
#' @description Computes a normalized CRAM index score per site using the
#'   latest available CRAM data, averaging across stations when multiple exist.
#' @name metric-cram-index
NULL

#' Score CRAM Index
#'
#' Always uses the **latest available** CRAM year per site (year filtering is
#' never applied to CRAM data). All sites present in \code{vegetativecover_data}
#' are included. No \code{year} column is produced. Averages \code{index}
#' across all stations when multiple exist. Sites with no CRAM data produce
#' \code{NA} score.
#'
#' @param cram A data frame with columns \code{siteid}, \code{MPA},
#'   \code{stationno}, \code{year}, \code{index}, \code{biotic},
#'   \code{physical}.
#' @param vegetativecover_data A vegetation data frame with columns
#'   \code{estuaryname} and \code{siteid}.
#' @param function_name Character vector. One or both of \code{"Plant"} and
#'   \code{"SLR"}. One output block is produced per value. Default
#'   \code{c("Plant", "SLR")}.
#' @param indicator_name Character. Indicator label. Default \code{"habitat"}.
#' @param cram_min Numeric. Minimum possible CRAM score. Default 25.
#' @param cram_range Numeric. Divisor for the normalization formula. Default 75.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_cram_index <- function(
  cram,
  vegetativecover_data,
  function_name = c("Plant", "SLR"),
  indicator_name = "habitat",
  cram_min = 25,
  cram_range = 75
) {
  # 1. Get all distinct sites from veg data (no year filtering for CRAM)
  veg_sites <- dplyr::distinct(vegetativecover_data, estuaryname, siteid)

  # 2. For each siteid, keep only the latest available year, then average index
  #    across stations
  cram_latest <- cram |>
    dplyr::filter(!is.na(.data$index)) |>
    dplyr::group_by(.data$siteid) |>
    dplyr::filter(.data$year == max(.data$year, na.rm = TRUE)) |>
    dplyr::summarise(
      empa_index = mean(.data$index, na.rm = TRUE),
      .groups = "drop"
    )

  # 3. Left join latest cram onto veg sites; sites with no CRAM data produce NA score
  scored <- dplyr::left_join(
    veg_sites,
    cram_latest,
    by = "siteid"
  ) |>
    dplyr::mutate(
      indicator_name = indicator_name,
      metric_name = "cram_index",
      metric_score = round(((empa_index - cram_min) / cram_range) * 100, 1)
    )

  # 4. Produce one block of rows per function_name
  dplyr::bind_rows(lapply(function_name, function(fn) {
    dplyr::mutate(scored, function_name = fn)
  })) |>
    dplyr::select(
      estuaryname,
      siteid,
      function_name,
      indicator_name,
      metric_name,
      metric_score
    )
}
