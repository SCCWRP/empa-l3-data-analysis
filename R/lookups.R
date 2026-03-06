#' @title EMPA Lookup Tables
#' @description Reference data and lookup tables used across the EMPA dashboard.
#'   All values are read from the active configuration (see
#'   \code{\link{load_config}}).
#' @name lookups

#' Season Month Ranges
#'
#' Returns a named list mapping season labels to month numbers.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A named list (names = season, values = integer vectors of months).
#' @export
season_months <- function(config = get_config()) {
  lapply(config$season_months, as.integer)
}

#' Habitat Aliases
#'
#' Returns a named vector of non-obvious habitat name remappings.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A named character vector.
#' @export
habitat_aliases <- function(config = get_config()) {
  unlist(config$habitat_aliases)
}

#' Ordered Site ID Levels
#'
#' Returns the canonical ordering of site IDs for factor levels.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of site IDs in display order.
#' @export
site_levels <- function(config = get_config()) {
  unlist(config$site_levels)
}

#' Ordered Region Levels
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of regions in display order.
#' @export
region_levels <- function(config = get_config()) {
  unlist(config$region_levels)
}

#' Ordered Native Status Levels
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of vegetation status levels in display order.
#' @export
status_levels <- function(config = get_config()) {
  unlist(config$status_levels)
}

#' Ordered Habitat Levels
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of habitat zones in display order.
#' @export
habitat_levels <- function(config = get_config()) {
  unlist(config$habitat_levels)
}

#' Cover Class Levels for Wetland Extents
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of cover classes in display order.
#' @export
cover_class_levels <- function(config = get_config()) {
  unlist(config$cover_class_levels)
}

#' Wetland Extent Levels
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of extent labels in display order.
#' @export
extent_levels <- function(config = get_config()) {
  unlist(config$extent_levels)
}

#' Landcover Factor Levels
#'
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A character vector of landcover classes in display order.
#' @export
landcover_levels <- function(config = get_config()) {
  unlist(config$landcover_levels)
}

# --- Color Palettes ---

#' EMPA Color Palettes
#'
#' Named list of color palettes used in EMPA dashboard plots.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A named list of character vectors.
#' @export
empa_palettes <- function(config = get_config()) {
  lapply(config$palettes, unlist)
}

#' Invasive Severity Penalty Mapping
#'
#' Returns a named numeric vector mapping Cal-IPC ratings to penalty points.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A named numeric vector.
#' @export
invasive_penalty_mapping <- function(config = get_config()) {
  penalties <- unlist(config$scoring$invasive_penalties)
  as.numeric(setNames(penalties, names(penalties)))
}
