#' @title EMPA Data Preprocessing
#' @description Configuration management, data loading, and preprocessing
#'   for the EMPA dashboard package.
#' @name data-preprocessing
#' @importFrom dplyr mutate filter select case_when
#' @importFrom tidyr pivot_longer

# =============================================================================
# Configuration
# =============================================================================

# Package-level environment to cache the active configuration
.empa_env <- new.env(parent = emptyenv())

#' Load Configuration
#'
#' Reads a YAML configuration file and caches it for use by all package
#' functions. If no path is provided, loads the default config bundled with the
#' package.
#'
#' @param path Character. Path to a YAML configuration file. If \code{NULL}
#'   (default), uses the bundled default config.
#' @return The parsed configuration as a named list (invisibly).
#' @export
load_config <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "config",
      "constants.yaml",
      package = "EMPAFunctionAnalysis"
    )
    # Fallback for development: look relative to working directory
    if (path == "") {
      local_path <- file.path("inst", "config", "constants.yaml")
      if (file.exists(local_path)) path <- local_path
    }
    if (path == "") {
      path <- "constants.yaml"
    }
    if (!file.exists(path)) {
      stop("Cannot find constants.yaml. ",
           "Pass an explicit path or run devtools::load_all('.').")
    }
  }
  cfg <- yaml::read_yaml(path)
  .empa_env$config <- cfg
  invisible(cfg)
}

#' Get Active Configuration
#'
#' Returns the currently loaded configuration. If no configuration has been
#' loaded yet, automatically loads the default config.
#'
#' @return A named list with all configuration values.
#' @export
get_config <- function() {
  if (is.null(.empa_env$config)) {
    load_config()
  }
  .empa_env$config
}

# =============================================================================
# Lookup Tables (read from config)
# =============================================================================

#' Ordered Site ID Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of site IDs in display order.
#' @export
site_levels <- function(config = get_config()) {
  unlist(config$site_levels)
}

#' Ordered Region Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of regions in display order.
#' @export
region_levels <- function(config = get_config()) {
  unlist(config$region_levels)
}

#' Ordered Native Status Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of vegetation status levels in display order.
#' @export
status_levels <- function(config = get_config()) {
  unlist(config$status_levels)
}

#' Ordered Habitat Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of habitat zones in display order.
#' @export
habitat_levels <- function(config = get_config()) {
  unlist(config$habitat_levels)
}

#' Cover Class Levels for Wetland Extents
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of cover classes in display order.
#' @export
cover_class_levels <- function(config = get_config()) {
  unlist(config$cover_class_levels)
}

#' Wetland Extent Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of extent labels in display order.
#' @export
extent_levels <- function(config = get_config()) {
  unlist(config$extent_levels)
}

#' Landcover Factor Levels
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of landcover classes in display order.
#' @export
landcover_levels <- function(config = get_config()) {
  unlist(config$landcover_levels)
}

#' Invasive Severity Penalty Mapping
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A named numeric vector mapping Cal-IPC ratings to penalty points.
#' @export
invasive_penalty_mapping <- function(config = get_config()) {
  penalties <- unlist(config$scoring$invasive_penalties)
  as.numeric(setNames(penalties, names(penalties)))
}

# =============================================================================
# Data Loading
# =============================================================================

#' Load Vegetative Cover Data
#'
#' Loads the vegetation cover data from the SCCWRP EMPA checker API.
#' @param url Character string. URL to the vegetative cover data export.
#' @return A data frame of vegetative cover records.
#' @export
load_veg_data <- function(
  url = "https://nexus.sccwrp.org/empachecker/export?tablename=tbl_vegetativecover_data"
) {
  utils::read.csv(url)
}

#' Load Vegetation Sample Metadata
#'
#' Loads the vegetation sample metadata from the SCCWRP EMPA checker API.
#' @param url Character string. URL to the vegetation metadata export.
#' @return A data frame of vegetation sample metadata.
#' @export
load_veg_metadata <- function(
  url = "https://nexus.sccwrp.org/empachecker/export?tablename=tbl_vegetation_sample_metadata"
) {
  utils::read.csv(url)
}

#' Load CRAM Data
#'
#' Loads CRAM (California Rapid Assessment Method) data from a local CSV.
#' @param path Character string. Path to the CRAM CSV file. If NULL, uses the
#'   bundled file in inst/extdata.
#' @return A data frame of CRAM scores.
#' @export
load_cram_data <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "extdata",
      "EMPA_CRAM_2014-2024.csv",
      package = "EMPAFunctionAnalysis"
    )
  }
  utils::read.csv(path)
}

#' Load Ruggedness Data
#'
#' @param path Character string. Path to the ruggedness CSV file. If NULL, uses
#'   the bundled file in inst/extdata.
#' @return A data frame of ruggedness values.
#' @export
load_ruggedness_data <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "extdata",
      "Ruggedness_250702.csv",
      package = "EMPAFunctionAnalysis"
    )
  }
  utils::read.csv(path)
}

#' Load Wetland Extents / Habitat Zones Data
#'
#' @param path Character string. Path to the habitat zones CSV file. If NULL,
#'   uses the bundled file in inst/extdata.
#' @return A data frame of wetland extent records.
#' @export
load_wetland_extents <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "extdata",
      "HabitatZones_260224.csv",
      package = "EMPAFunctionAnalysis"
    )
  }
  utils::read.csv(path)
}

#' Load GIS Buffer Land Cover Data
#'
#' @param path Character string. Path to the buffer land cover CSV file. If
#'   NULL, uses the bundled file in inst/extdata.
#' @return A data frame of buffer land cover records.
#' @export
load_gis_data <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "extdata",
      "BufferLandCover_251203.csv",
      package = "EMPAFunctionAnalysis"
    )
  }
  utils::read.csv(path)
}

# =============================================================================
# Data Preprocessing
# =============================================================================

# Internal helper: assign Season based on samplecollectiondate
assign_season <- function(date_col, config = get_config()) {
  month_num <- as.integer(substr(date_col, 6, 7))
  sm <- config$season_months
  dplyr::case_when(
    month_num %in% sm$Spring ~ "Spring",
    month_num %in% sm$Fall ~ "Fall",
    TRUE ~ NA_character_
  )
}

#' Clean Vegetation Cover Data
#'
#' Appends \code{calendar_year} and \code{Season} from
#' \code{samplecollectiondate}, and removes rows with invalid site IDs
#' (global filter).
#'
#' @param veg A data frame as returned by \code{\link{load_veg_data}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A cleaned data frame with \code{calendar_year} and \code{Season}
#'   columns added.
#' @export
clean_veg <- function(veg, config = get_config()) {
  veg |>
    dplyr::filter(.data$siteid != "NA") |>
    dplyr::mutate(
      calendar_year = substr(samplecollectiondate, 1, 4),
      Season = assign_season(samplecollectiondate, config)
    )
}

#' Clean Vegetation Metadata
#'
#' Pivots metadata to long format, appends \code{calendar_year} and
#' \code{Season}, and removes rows with invalid site or estuary IDs
#' (global filter).
#'
#' @param metadata A data frame as returned by \code{\link{load_veg_metadata}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A cleaned long-format data frame.
#' @export
clean_veg_metadata <- function(metadata, config = get_config()) {
  metadata |>
    dplyr::filter(
      .data$siteid != "NA",
      .data$estuaryname != "NA"
    ) |>
    dplyr::select(
      siteid,
      estuaryname,
      samplecollectiondate,
      vegetated_cover,
      non_vegetated_cover
    ) |>
    tidyr::pivot_longer(
      cols = c(vegetated_cover, non_vegetated_cover),
      names_to = "cover_type",
      values_to = "cover_value"
    ) |>
    dplyr::mutate(
      calendar_year = substr(samplecollectiondate, 1, 4),
      Season = assign_season(samplecollectiondate, config)
    )
}

# =============================================================================
# Factor Ordering
# =============================================================================

#' Set Factor Levels on Vegetation Data
#'
#' Converts siteid, Region, and status to ordered factors.
#' @param veg A data frame as returned by \code{\link{clean_veg}}.
#' @return The same data frame with factor columns.
#' @export
order_veg <- function(veg) {
  veg$siteid <- factor(veg$siteid, levels = site_levels(), ordered = TRUE)
  veg$Region <- factor(veg$Region, levels = region_levels(), ordered = TRUE)
  veg$status <- factor(veg$status, levels = status_levels(), ordered = TRUE)
  veg
}

#' Set Factor Levels on Vegetation Metadata
#'
#' Converts siteid to an ordered factor.
#' @param metadata A data frame as returned by \code{\link{clean_veg_metadata}}.
#' @return The same data frame with siteid as an ordered factor.
#' @export
order_veg_metadata <- function(metadata) {
  metadata$siteid <- factor(
    metadata$siteid,
    levels = site_levels(),
    ordered = TRUE
  )
  metadata
}

#' Set Factor Levels on Wetland Extents Data
#'
#' Converts cover_class, siteid, region, and extent to ordered factors.
#' @param data A data frame as returned by \code{\link{load_wetland_extents}}.
#' @return The same data frame with factor columns.
#' @export
order_wetland_extents <- function(data) {
  data$cover_class <- factor(
    data$cover_class,
    levels = cover_class_levels(),
    ordered = TRUE
  )
  data$siteid <- factor(data$siteid, levels = site_levels(), ordered = TRUE)
  data$region <- factor(data$region, levels = region_levels(), ordered = TRUE)
  data$extent <- factor(data$extent, levels = extent_levels(), ordered = TRUE)
  data
}

#' Set Factor Levels on GIS Buffer Data
#'
#' Converts siteid and landcover to ordered factors.
#' @param data A data frame as returned by \code{\link{load_gis_data}}.
#' @return The same data frame with factor columns.
#' @export
order_gis_data <- function(data) {
  data$siteid <- factor(data$siteid, levels = site_levels(), ordered = TRUE)
  data$landcover <- factor(
    data$landcover,
    levels = landcover_levels(),
    ordered = TRUE
  )
  data
}
