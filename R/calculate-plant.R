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
#'   \item Indicator: habitat -> Metric: index (CRAM)
#'   \item Indicator: vegetation -> Metrics: native_cover, native_resiliency,
#'     veg_cover
#'   \item Indicator: elevation -> Metric: ruggedness
#' }
#'
#' @param cram CRAM data frame (from \code{\link{load_cram_data}}).
#' @param veg Raw or cleaned vegetation data frame.
#' @param veg_metadata Raw or cleaned vegetation metadata data frame.
#' @param rugged Ruggedness data frame. If \code{NULL} (default), loads the
#'   bundled file via \code{\link{load_ruggedness_data}}.
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A long-format data frame with columns: estuaryname, siteid,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
calculate_function_plant <- function(
  cram,
  veg,
  veg_metadata,
  rugged = NULL,
  year = "all",
  season = "all",
  config = get_config()
) {
  if (!"calendar_year" %in% names(veg)) {
    veg <- clean_veg(veg) |> order_veg()
  }
  if (!"cover_value" %in% names(veg_metadata)) {
    veg_metadata <- clean_veg_metadata(veg_metadata) |> order_veg_metadata()
  }
  if (is.null(rugged)) {
    rugged <- load_ruggedness_data()
  }

  dplyr::bind_rows(
    # Indicator: habitat
    score_cram_index(cram, function_name = "Plant", config = config),

    # Indicator: vegetation
    score_native_cover(veg, year = year, season = season, config = config),
    score_invasive_severity(veg, year = year, season = season, config = config),
    score_veg_cover(veg_metadata, year = year, season = season, config = config),

    # Indicator: elevation
    score_ruggedness(rugged)
  )
}
