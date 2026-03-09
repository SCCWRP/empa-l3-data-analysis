#' @title Calculate Plant Function Scores
#' @description Orchestrates all indicator and metric calculations for the
#'   Plant (Vegetation Health) function.
#' @name calculate-plant
#' @importFrom dplyr bind_rows

#' Calculate All Plant Function Metrics
#'
#' Runs every metric under the Plant function and returns a single long-format
#' table. Accepts raw or pre-cleaned data — cleaning is applied automatically
#' if not already done.
#'
#' Plant function structure:
#' \itemize{
#'   \item Indicator: alliances -> Metric: plant_alliances
#'   \item Indicator: elevation -> Metric: ruggedness
#'   \item Indicator: habitat -> Metric: cram_index
#'   \item Indicator: inundation -> Metric: marsh_plain_inundation
#'   \item Indicator: vegetation -> Metrics: invasive_severity, native_cover,
#'     veg_cover
#' }
#'
#' @param cram CRAM data frame.
#' @param veg Raw or cleaned vegetation data frame.
#' @param veg_metadata Raw or cleaned vegetation metadata data frame.
#' @param rugged Ruggedness data frame.
#' @param year Numeric or character vector of calendar years (e.g.
#'   \code{c(2023, 2024)}). Required.
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list used to supply scoring parameter defaults.
#'   Defaults to \code{\link{get_config}()}.
#' @return A long-format data frame with columns: estuaryname, siteid, year,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
calculate_function_plant <- function(
  cram,
  veg,
  veg_metadata,
  rugged,
  year,
  season = "all",
  config = get_config()
) {
  year <- as.character(year)

  if (!"calendar_year" %in% names(veg)) {
    veg <- clean_veg(veg)
  }
  if (!"cover_value" %in% names(veg_metadata)) {
    veg_metadata <- clean_veg_metadata(veg_metadata)
  }

  # Scoring parameters from config (used as defaults for metric calls)
  missing_val      <- config$scoring$missing_data_value
  exclude_statuses <- unlist(config$scoring$veg_exclude_statuses)
  penalties        <- invasive_penalty_mapping(config)
  base_score       <- config$scoring$invasive_base_score
  cram_min         <- config$scoring$cram_min
  cram_range       <- config$scoring$cram_range

  # Static metrics (no year variation)
  static <- dplyr::bind_rows(
    score_ruggedness(rugged)
  )

  results <- lapply(year, function(y) {
    yearly <- dplyr::bind_rows(
      score_cram_index(cram, function_name = "Plant",
                       cram_min = cram_min, cram_range = cram_range, year = y),
      score_plant_alliances(veg, year = y, season = season),
      score_marsh_plain_inundation(veg, year = y, season = season),
      score_native_cover(veg, missing_val = missing_val,
                         exclude_statuses = exclude_statuses,
                         year = y, season = season),
      score_invasive_severity(veg, base_score = base_score, penalties = penalties,
                              year = y, season = season),
      score_veg_cover(veg_metadata, missing_val = missing_val,
                      function_name = "Plant", year = y, season = season)
    )
    yearly$year <- y

    s       <- static
    s$year  <- y
    dplyr::bind_rows(s, yearly)
  })

  dplyr::bind_rows(results) |>
    dplyr::select(
      estuaryname, siteid, year,
      function_name, indicator_name, metric_name, metric_score
    )
}
