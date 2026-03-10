#' @title Metric: Invasive Severity
#' @description Computes a native resiliency score based on invasive species
#'   penalties per site.
#' @name metric-invasive-severity
NULL

#' Score Invasive Severity
#'
#' Extracts year from \code{samplecollectiondate}, filters to the requested
#' year(s), then identifies unique invasive species per site and year using the
#' Cal-IPC \code{rating} column. Starts at 100 and subtracts penalty points per
#' unique invasive species: Limited = 5, Moderate = 10, High = 15 (or as
#' specified by \code{penalties}). Score is floored at 0.
#'
#' @param vegetativecover_data A raw vegetation cover data frame with columns
#'   \code{estuaryname}, \code{siteid}, \code{samplecollectiondate},
#'   \code{scientificname}, \code{rating}.
#' @param function_name Character. Function label. Default \code{"Plant"}.
#' @param indicator_name Character. Indicator label. Default \code{"vegetation"}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @param penalties Named numeric vector mapping Cal-IPC rating labels to
#'   penalty points. Default \code{c(Limited = 5, Moderate = 10, High = 15)}.
#' @return A data frame with columns: estuaryname, siteid, year, function_name,
#'   indicator_name, metric_name, metric_score.
#' @export
score_invasive_severity <- function(
  vegetativecover_data,
  function_name = "Plant",
  indicator_name = "vegetation",
  year = "all",
  penalties = c(Limited = 5, Moderate = 10, High = 15)
) {
  veg <- vegetativecover_data |>
    dplyr::mutate(year = as.character(substr(samplecollectiondate, 1, 4)))

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$year %in% as.character(year))
  }

  # All sites × years present in the data (to preserve sites with no invasives)
  all_sites <- dplyr::distinct(veg, estuaryname, siteid, year)

  # Unique invasive species per site × year, with their penalty
  penalties_df <- data.frame(
    rating = names(penalties),
    penalty = unname(penalties),
    stringsAsFactors = FALSE
  )

  invasive_penalties <- veg |>
    dplyr::filter(.data$rating %in% names(penalties)) |>
    dplyr::distinct(estuaryname, siteid, year, scientificname, rating) |>
    dplyr::left_join(penalties_df, by = "rating") |>
    dplyr::group_by(estuaryname, siteid, year) |>
    dplyr::summarise(
      total_penalty = sum(penalty, na.rm = TRUE),
      .groups = "drop"
    )

  all_sites |>
    dplyr::left_join(
      invasive_penalties,
      by = c("estuaryname", "siteid", "year")
    ) |>
    dplyr::mutate(
      total_penalty = ifelse(is.na(total_penalty), 0, total_penalty),
      function_name = function_name,
      indicator_name = indicator_name,
      metric_name = "invasive_severity",
      metric_score = pmax(100 - total_penalty, 0)
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
