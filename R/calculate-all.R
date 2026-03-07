#' @title Calculate All Function Scores
#' @description Combines Plant and SLR function calculations into a single
#'   master table.
#' @name calculate-all
#' @importFrom dplyr bind_rows

#' Calculate All EMPA Function Metrics
#'
#' Runs both Plant and SLR function calculations and returns a combined
#' long-format table. Accepts raw or pre-cleaned data — cleaning is applied
#' automatically if not already done.
#'
#' @param cram CRAM data frame.
#' @param veg Raw or cleaned vegetation data frame.
#' @param veg_metadata Raw or cleaned vegetation metadata data frame.
#' @param gis_data Raw or cleaned GIS buffer data frame.
#' @param wetland_extents Raw or cleaned wetland extents data frame.
#' @param rugged Ruggedness data frame.
#' @param year Character or numeric vector of calendar years (e.g.
#'   \code{c(2023, 2024, 2025)}). Required.
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A long-format data frame with columns: estuaryname, siteid, year,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
calculate_function_all <- function(
  cram,
  veg,
  veg_metadata,
  gis_data,
  wetland_extents,
  rugged,
  year,
  season = "all",
  config = get_config()
) {
  # Clean once, pass pre-cleaned to sub-functions (avoids cleaning twice)
  if (!"calendar_year" %in% names(veg)) {
    veg <- clean_veg(veg) |> order_veg()
  }
  if (!"cover_value" %in% names(veg_metadata)) {
    veg_metadata <- clean_veg_metadata(veg_metadata) |> order_veg_metadata()
  }
  if (!is.ordered(gis_data$siteid)) {
    gis_data <- order_gis_data(gis_data)
  }
  if (!is.ordered(wetland_extents$siteid)) {
    wetland_extents <- order_wetland_extents(wetland_extents)
  }

  plant <- calculate_function_plant(
    cram, veg, veg_metadata, rugged,
    year = year, season = season, config = config
  )
  slr <- calculate_function_slr(
    cram, veg_metadata, gis_data, wetland_extents,
    year = year, season = season, config = config
  )

  dplyr::bind_rows(plant, slr)
}
