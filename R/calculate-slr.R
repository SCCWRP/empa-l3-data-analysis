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
#'   \item Indicator: accretion -> Metric: sediment_supply
#'   \item Indicator: habitat -> Metric: cram_index
#'   \item Indicator: resiliency -> Metrics: buffer_cover,
#'     current_habitat_distribution, future_habitat_distribution,
#'     perimeter_contiguity, perimeter_land_cover
#'   \item Indicator: vegetation -> Metric: veg_cover
#' }
#'
#' @param cram CRAM data frame.
#' @param veg_metadata Raw or cleaned vegetation metadata data frame.
#' @param gis_data GIS buffer land cover data frame.
#' @param wetland_extents Wetland extents data frame.
#' @param year Numeric or character vector of calendar years (e.g.
#'   \code{c(2023, 2024)}). Required.
#' @param season Character vector of seasons, or "all". Default "all".
#' @param config A configuration list used to supply scoring parameter defaults.
#'   Defaults to \code{\link{get_config}()}.
#' @return A long-format data frame with columns: estuaryname, siteid, year,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
calculate_function_slr <- function(
  cram,
  veg_metadata,
  gis_data,
  wetland_extents,
  year,
  season = "all",
  config = get_config()
) {
  year <- as.character(year)

  if (!"cover_value" %in% names(veg_metadata)) {
    veg_metadata <- clean_veg_metadata(veg_metadata)
  }
  if (!is.ordered(gis_data$siteid)) {
    gis_data <- order_gis_data(gis_data)
  }
  if (!is.ordered(wetland_extents$siteid)) {
    wetland_extents <- order_wetland_extents(wetland_extents)
  }

  # Scoring parameters from config
  cram_min         <- config$scoring$cram_min
  cram_range       <- config$scoring$cram_range
  missing_val      <- config$scoring$missing_data_value
  natural_classes  <- unlist(config$scoring$natural_landcover_classes)
  largest_col      <- config$scoring$contiguity_landcovers$largest
  total_col        <- config$scoring$contiguity_landcovers$total
  buffer_large     <- config$buffer_sizes$large
  buffer_small     <- config$buffer_sizes$small
  metric_large     <- config$buffer_metric_names$large
  metric_small     <- config$buffer_metric_names$small
  sum_zones        <- unlist(config$scoring$wetland_sum_zones)
  extent_map       <- unlist(config$scoring$elevation_extent_mapping)
  current_extent   <- names(extent_map[extent_map == "current_habitat_distribution"])
  future_extent    <- names(extent_map[extent_map == "future_habitat_distribution"])

  # Static metrics (no year variation)
  static <- dplyr::bind_rows(
    score_sediment_supply(cram),
    score_buffer_cover(gis_data, buffer_size = buffer_large,
                       metric_name = metric_large, natural_classes = natural_classes),
    score_buffer_cover(gis_data, buffer_size = buffer_small,
                       metric_name = metric_small, natural_classes = natural_classes),
    score_perimeter_contiguity(gis_data, largest_col = largest_col, total_col = total_col),
    score_current_extent(wetland_extents, target_extent = current_extent, sum_zones = sum_zones),
    score_future_extent(wetland_extents, target_extent = future_extent, sum_zones = sum_zones)
  )

  results <- lapply(year, function(y) {
    yearly <- dplyr::bind_rows(
      score_cram_index(cram, function_name = "SLR",
                       cram_min = cram_min, cram_range = cram_range, year = y),
      score_veg_cover(veg_metadata, missing_val = missing_val,
                      function_name = "SLR", year = y, season = season)
    )
    yearly$year <- y

    s      <- static
    s$year <- y
    dplyr::bind_rows(s, yearly)
  })

  dplyr::bind_rows(results) |>
    dplyr::select(
      estuaryname, siteid, year,
      function_name, indicator_name, metric_name, metric_score
    )
}
