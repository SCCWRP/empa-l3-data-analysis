#' @title Calculate SLR Function Scores
#' @description Orchestrates all indicator and metric calculations for the
#'   SLR (Sea Level Rise Vulnerability) function.
#' @name calculate-slr
#' @importFrom dplyr bind_rows

#' Calculate All SLR Function Metrics
#'
#' Runs every metric under the SLR function and returns a single long-format
#' table. Accepts raw or pre-cleaned data — cleaning is applied automatically
#' if not already done.
#'
#' SLR function structure:
#' \itemize{
#'   \item Indicator: habitat -> Metric: index (CRAM)
#'   \item Indicator: vegetation -> Metric: veg_cover
#'   \item Indicator: resiliency -> Metrics: buffer_cover,
#'     perimeter_land_cover, perimeter_contiguity, current_extent,
#'     future_extent
#' }
#'
#' @param cram CRAM data frame (from \code{\link{load_cram_data}}).
#' @param veg_metadata Raw or cleaned vegetation metadata data frame.
#' @param gis_data Raw or cleaned GIS buffer data frame.
#' @param wetland_extents Raw or cleaned wetland extents data frame.
#' @param year Character vector of calendar years, or "all". Default "all".
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A long-format data frame with columns: estuaryname, siteid,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
calculate_function_slr <- function(
  cram,
  veg_metadata,
  gis_data,
  wetland_extents,
  year = "all",
  season = "all",
  config = get_config()
) {
  if (!"cover_value" %in% names(veg_metadata)) {
    veg_metadata <- clean_veg_metadata(veg_metadata) |> order_veg_metadata()
  }
  if (!is.ordered(gis_data$siteid)) {
    gis_data <- order_gis_data(gis_data)
  }
  if (!is.ordered(wetland_extents$siteid)) {
    wetland_extents <- order_wetland_extents(wetland_extents)
  }

  dplyr::bind_rows(
    # Indicator: habitat
    score_cram_index(cram, function_name = "SLR", config = config),

    # Indicator: vegetation
    score_veg_cover(
      veg_metadata,
      function_name = "SLR",
      indicator_name = "vegetation",
      year = year,
      season = season,
      config = config
    ),

    # Indicator: resiliency
    score_buffer_cover(gis_data, buffer_size = "500 m",
                       metric_name = "buffer_cover", config = config),
    score_buffer_cover(gis_data, buffer_size = "30 m",
                       metric_name = "perimeter_land_cover", config = config),
    score_perimeter_contiguity(gis_data, config = config),
    score_current_extent(wetland_extents, config = config),
    score_future_extent(wetland_extents, config = config)
  )
}
