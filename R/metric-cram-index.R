#' @title Metric: CRAM Index
#' @description Computes a normalized CRAM index score per site by averaging
#'   station-level scores then joining to vegetation survey sites.
#' @name metric-cram-index
NULL

#' Score CRAM Index
#'
#' For the selected year(s): filters vegetation data by \code{samplecollectiondate},
#' filters CRAM data by \code{Year_assessment}, averages the \code{index} column
#' per \code{Site} and year, then left-joins onto vegetation sites so every
#' surveyed site appears in the output (NA score when no CRAM data exists).
#'
#' @param cram A data frame with columns \code{Site}, \code{Year_assessment},
#'   and \code{index}.
#' @param vegetativecover_data A vegetation data frame with columns
#'   \code{estuaryname}, \code{siteid}, and \code{samplecollectiondate}.
#' @param function_name Character vector. One or both of \code{"Plant"} and
#'   \code{"SLR"}. One output block is produced per value. Default
#'   \code{c("Plant", "SLR")}.
#' @param indicator_name Character. Indicator label. Default \code{"habitat"}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @param cram_min Numeric. Minimum possible CRAM score. Default 25.
#' @param cram_range Numeric. Divisor for the normalization formula. Default 75.
#' @return A data frame with columns: estuaryname, siteid, year, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_cram_index <- function(
  cram,
  vegetativecover_data,
  function_name = c("Plant", "SLR"),
  indicator_name = "habitat",
  year = "all",
  cram_min = 25,
  cram_range = 75
) {
  # 1. Filter veg by year (samplecollectiondate), extract year, get distinct sites
  if (!identical(year, "all")) {
    vegetativecover_data <- dplyr::filter(
      vegetativecover_data,
      as.integer(substr(samplecollectiondate, 1, 4)) %in% as.integer(year)
    )
  }
  veg_sites <- vegetativecover_data |>
    dplyr::mutate(year = as.character(substr(samplecollectiondate, 1, 4))) |>
    dplyr::distinct(estuaryname, siteid, year)

  # 2. Filter cram by year (Year_assessment), average index per Site and year
  if (!identical(year, "all")) {
    cram <- dplyr::filter(cram, .data$Year_assessment %in% as.integer(year))
  }
  cram_avg <- cram |>
    dplyr::group_by(Site, Year_assessment) |>
    dplyr::summarise(
      empa_index = mean(index, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(year = as.character(Year_assessment))

  # 3. Left join averaged cram onto veg sites (siteid = Site, year = year)
  #    Sites with no CRAM data produce NA metric_score
  scored <- dplyr::left_join(
    veg_sites,
    cram_avg,
    by = c("siteid" = "Site", "year" = "year")
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
      year,
      function_name,
      indicator_name,
      metric_name,
      metric_score
    )
}
