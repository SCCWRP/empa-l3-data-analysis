#' @title EMPA Scoring Functions
#' @description Functions that compute indicator scores and summary tables for
#'   the EMPA dashboard. All hard-coded parameters are read from the active
#'   configuration (see \code{\link{load_config}}).
#' @name scoring
#' @importFrom dplyr mutate select filter rename group_by summarise across
#' @importFrom tidyr pivot_wider

#' Score CRAM Index
#'
#' Computes a 0-100 index score from CRAM EMPA_index values using the formula
#' \code{((EMPA_index - cram_min) / cram_range) * 100}, where \code{cram_min}
#' and \code{cram_range} are read from the config.
#'
#' @param cram A data frame containing CRAM data with columns \code{estuaryname},
#'   \code{siteid}, and \code{EMPA_index}.
#' @param function_name Character. The function category label (e.g. "Plant",
#'   "SLR").
#' @param indicator_name Character. The indicator label (e.g. "habitat").
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, index.
#' @export
score_cram <- function(cram, function_name, indicator_name = "habitat",
                       config = get_config()) {
  cram_min   <- config$scoring$cram_min
  cram_range <- config$scoring$cram_range

  cram |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name,
      index = round(((EMPA_index - cram_min) / cram_range) * 100, digits = 1)
    ) |>
    dplyr::select(estuaryname, siteid, function_name, indicator_name, index) |>
    dplyr::filter(!is.na(siteid))
}

#' Score Relative Native Vegetation Cover
#'
#' Computes relative abundance (%) of each vegetation status category and
#' returns a summary with the native cover percentage.
#'
#' @param veg A cleaned vegetation data frame.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param year Character vector of calendar years to include (e.g.
#'   \code{c("2023", "2024")}), or \code{"all"} to use all years. Default
#'   \code{"all"}.
#' @param season Character vector of seasons to include (e.g. \code{"Fall"}),
#'   or \code{"all"} to use all seasons. Default \code{"all"}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, native_cover.
#' @export
score_veg_relative <- function(veg, function_name = "Plant",
                               indicator_name = "vegetation",
                               year = "all", season = "all",
                               config = get_config()) {
  missing_val      <- config$scoring$missing_data_value
  exclude_statuses <- unlist(config$scoring$veg_exclude_statuses)

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  veg_relative <- veg |>
    dplyr::filter(
      !.data$status %in% exclude_statuses,
      .data$siteid != "NA",
      .data$estimatedcover != missing_val
    ) |>
    dplyr::group_by(estuaryname, siteid, status) |>
    dplyr::summarise(total_cover = sum(estimatedcover, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::group_by(siteid) |>
    dplyr::mutate(
      relative_abundance = round(total_cover / sum(total_cover) * 100, 1)
    ) |>
    dplyr::select(estuaryname, siteid, status, relative_abundance) |>
    tidyr::pivot_wider(
      names_from  = status,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_relative |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    ) |>
    dplyr::select(estuaryname, siteid, function_name, indicator_name, native) |>
    dplyr::rename(native_cover = native)
}

#' Score Invasive Severity
#'
#' Computes a native resiliency score by applying penalties based on Cal-IPC
#' invasive ratings for species found at each site.
#'
#' @param veg A cleaned vegetation data frame.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param year Character vector of calendar years to include (e.g.
#'   \code{c("2023", "2024")}), or \code{"all"} to use all years. Default
#'   \code{"all"}.
#' @param season Character vector of seasons to include (e.g. \code{"Fall"}),
#'   or \code{"all"} to use all seasons. Default \code{"all"}.
#' @param penalties A named numeric vector mapping rating labels to penalty
#'   points. Defaults to \code{\link{invasive_penalty_mapping}()}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, native_resiliency,
#'   function_name, indicator_name.
#' @export
score_invasive_severity <- function(veg, function_name = "Plant",
                                    indicator_name = "vegetation",
                                    year = "all", season = "all",
                                    penalties = invasive_penalty_mapping(),
                                    config = get_config()) {
  base_score <- config$scoring$invasive_base_score

  if (!identical(year, "all")) {
    veg <- dplyr::filter(veg, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    veg <- dplyr::filter(veg, .data$Season %in% season)
  }

  scoring <- veg |>
    dplyr::filter(.data$siteid != "NA") |>
    dplyr::distinct(estuaryname, siteid, scientificname, rating) |>
    dplyr::mutate(
      penalty = dplyr::if_else(
        .data$rating %in% names(penalties),
        penalties[.data$rating],
        0
      )
    ) |>
    dplyr::group_by(estuaryname, siteid) |>
    dplyr::summarise(
      total_penalty     = sum(penalty),
      native_resiliency = pmax(base_score - total_penalty, 0),
      .groups = "drop"
    )

  scoring |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    ) |>
    dplyr::select(estuaryname, siteid, native_resiliency,
                  function_name, indicator_name)
}

#' Score Vegetated Cover
#'
#' Computes relative vegetated vs non-vegetated cover from metadata and returns
#' the vegetated cover percentage.
#'
#' @param metadata A cleaned veg metadata data frame (long format).
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param year Character vector of calendar years to include (e.g.
#'   \code{c("2023", "2024")}), or \code{"all"} to use all years. Default
#'   \code{"all"}.
#' @param season Character vector of seasons to include (e.g. \code{"Fall"}),
#'   or \code{"all"} to use all seasons. Default \code{"all"}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, veg_cover.
#' @export
score_veg_cover <- function(metadata, function_name = "Plant",
                            indicator_name = "vegetation",
                            year = "all", season = "all",
                            config = get_config()) {
  missing_val <- config$scoring$missing_data_value

  if (!identical(year, "all")) {
    metadata <- dplyr::filter(metadata, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    metadata <- dplyr::filter(metadata, .data$Season %in% season)
  }

  veg_cover <- metadata |>
    dplyr::filter(
      .data$siteid != "NA",
      .data$cover_value != missing_val,
      .data$estuaryname != "NA"
    ) |>
    dplyr::group_by(estuaryname, siteid, cover_type) |>
    dplyr::summarise(total_cover = sum(cover_value, na.rm = TRUE),
                     .groups = "drop") |>
    dplyr::group_by(siteid) |>
    dplyr::mutate(
      relative_abundance = round(total_cover / sum(total_cover) * 100, 1)
    ) |>
    dplyr::select(estuaryname, siteid, cover_type, relative_abundance) |>
    tidyr::pivot_wider(
      names_from  = cover_type,
      values_from = relative_abundance,
      values_fill = 0
    )

  veg_cover |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    ) |>
    dplyr::select(estuaryname, siteid, function_name, indicator_name,
                  vegetated_cover) |>
    dplyr::rename(veg_cover = vegetated_cover)
}

#' Score Ruggedness
#'
#' Prepares the ruggedness summary table for the dashboard.
#'
#' @param rugged A data frame as returned by \code{\link{load_ruggedness_data}}.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @return A data frame with columns: estuaryname, siteid, function_name,
#'   indicator_name, ruggedness.
#' @export
score_ruggedness <- function(rugged, function_name = "Plant",
                             indicator_name = "elevation") {
  # Handle both capitalizations
  rug_col <- if ("Ruggedness" %in% names(rugged)) "Ruggedness" else "ruggedness"

  rugged |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    ) |>
    dplyr::select(estuaryname, siteid, function_name, indicator_name,
                  dplyr::all_of(rug_col)) |>
    dplyr::rename(ruggedness = dplyr::all_of(rug_col))
}

#' Score Buffer Land Cover (500 m or 30 m)
#'
#' Aggregates buffer land cover into a combined natural + agricultural cover
#' percentage for a given buffer distance.
#'
#' @param gis_data A data frame as returned by \code{\link{load_gis_data}}.
#' @param buffer_size Character. Buffer distance (e.g. "500 m", "30 m").
#' @param cover_name Character. Name for the aggregated cover column.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with cover summary columns.
#' @export
score_buffer <- function(gis_data, buffer_size, cover_name = "buffer_cover",
                         function_name = "SLR",
                         indicator_name = "migration",
                         config = get_config()) {
  natural_classes <- unlist(config$scoring$natural_landcover_classes)

  gis_data |>
    dplyr::filter(.data$buffer == buffer_size) |>
    dplyr::mutate(
      landcover_group = dplyr::case_when(
        .data$landcover %in% natural_classes ~ cover_name,
        .data$landcover == "Developed"       ~ "Developed",
        TRUE                                 ~ NA_character_
      )
    ) |>
    dplyr::group_by(estuaryname, siteid, landcover_group) |>
    dplyr::summarise(total_percent = sum(percent, na.rm = TRUE),
                     .groups = "drop") |>
    tidyr::pivot_wider(
      names_from  = landcover_group,
      values_from = total_percent,
      values_fill = 0
    ) |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    )
}

#' Score Buffer Contiguity
#'
#' Computes the ratio of the largest contiguous open area to total open area
#' around each site.
#'
#' @param gis_data A data frame as returned by \code{\link{load_gis_data}}.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, perimeter_contiguity,
#'   function_name, indicator_name.
#' @export
score_contiguity <- function(gis_data, function_name = "SLR",
                             indicator_name = "migration",
                             config = get_config()) {
  contiguity_lc <- unlist(config$scoring$contiguity_landcovers)

  gis_data |>
    dplyr::filter(.data$landcover %in% contiguity_lc) |>
    dplyr::select(estuaryname, siteid, landcover, rastercount) |>
    tidyr::pivot_wider(
      names_from  = landcover,
      values_from = rastercount
    ) |>
    dplyr::mutate(
      perimeter_contiguity = dplyr::if_else(
        `Total Open` > 0,
        round((`Largest Contiguous` / `Total Open`) * 100, 1),
        NA_real_
      ),
      function_name  = function_name,
      indicator_name = indicator_name
    )
}

#' Score Elevation Zones
#'
#' Computes current and future wetland extent percentages from habitat zone
#' data.
#'
#' @param wetland A data frame as returned by \code{\link{load_wetland_extents}}.
#' @param function_name Character. The function category label.
#' @param indicator_name Character. The indicator label.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A data frame with columns: estuaryname, siteid, current_extent,
#'   future_extent, function_name, indicator_name.
#' @export
score_elevation <- function(wetland, function_name = "SLR",
                            indicator_name = "future_areas",
                            config = get_config()) {
  elev_exclude   <- config$scoring$elevation_exclude_extent
  extent_map     <- unlist(config$scoring$elevation_extent_mapping)
  sum_zones      <- unlist(config$scoring$wetland_sum_zones)

  # Handle both capitalizations
  cover_num_col <- if ("cover_number" %in% names(wetland)) "cover_number" else "Cover_number"
  cover_col     <- if ("cover_class" %in% names(wetland)) "cover_class" else "Cover_class"
  pct_col       <- if ("percent_cover" %in% names(wetland)) "percent_cover" else "Percent_cover"
  extent_col    <- if ("extent" %in% names(wetland)) "extent" else "Extent"

  wetland |>
    dplyr::select(-dplyr::all_of(cover_num_col)) |>
    dplyr::filter(.data[[extent_col]] != elev_exclude) |>
    dplyr::group_by(estuaryname, siteid) |>
    tidyr::pivot_wider(
      names_from  = dplyr::all_of(cover_col),
      values_from = dplyr::all_of(pct_col),
      values_fill = 0
    ) |>
    dplyr::mutate(
      wetland_sums = rowSums(dplyr::across(dplyr::all_of(sum_zones)), na.rm = TRUE) * 100,
      extent_short = extent_map[.data[[extent_col]]]
    ) |>
    dplyr::select(estuaryname, siteid, extent_short, wetland_sums) |>
    tidyr::pivot_wider(
      names_from  = extent_short,
      values_from = wetland_sums,
      values_fill = 0
    ) |>
    dplyr::mutate(
      function_name  = function_name,
      indicator_name = indicator_name
    )
}
