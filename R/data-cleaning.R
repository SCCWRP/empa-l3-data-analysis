#' @title EMPA Data Cleaning Functions
#' @description Functions to clean, standardize, and set factor levels on raw
#'   EMPA data frames.
#' @name data-cleaning
#' @importFrom dplyr mutate rename case_when filter select group_by summarise
#' @importFrom tidyr pivot_longer pivot_wider
#' @importFrom stringr str_detect str_sub

# ---------------------------------------------------------------------------
# Internal helper: assign Season based on samplecollectiondate
# ---------------------------------------------------------------------------
assign_season <- function(date_col, config = get_config()) {
  month_num <- as.integer(substr(date_col, 6, 7))
  sm <- config$season_months
  dplyr::case_when(
    month_num %in% sm$Spring ~ "Spring",
    month_num %in% sm$Fall   ~ "Fall",
    TRUE                     ~ NA_character_
  )
}

# ---------------------------------------------------------------------------
# Internal helper: standardize habitat names
# Uses aliases for non-obvious remappings, title-cases everything else.
# ---------------------------------------------------------------------------
standardize_habitat <- function(habitat_col) {
  aliases <- habitat_aliases()
  title_case <- function(x) {
    gsub("(^|\\s)(\\w)", "\\1\\U\\2", x, perl = TRUE)
  }
  dplyr::if_else(
    habitat_col %in% names(aliases),
    unname(aliases[habitat_col]),
    title_case(habitat_col)
  )
}

#' Clean Vegetation Cover Data
#'
#' Adds Season and Habitat_final columns; renames region to Region;
#' adds a count column.
#' @param veg A data frame as returned by \code{\link{load_veg_data}}.
#' @return A cleaned data frame with additional columns.
#' @export
clean_veg <- function(veg) {
  veg |>
    dplyr::mutate(
      calendar_year = substr(samplecollectiondate, 1, 4),
      Season = assign_season(samplecollectiondate),
      Habitat_final = standardize_habitat(habitat),
      count = 1L
    ) |>
    dplyr::rename(Region = region)
}

#' Set Factor Levels on Vegetation Data
#'
#' Converts siteid, Region, status, and Habitat_final to ordered factors using
#' the canonical level orderings from the lookups module.
#' @param veg A data frame as returned by \code{\link{clean_veg}}.
#' @return The same data frame with factor columns.
#' @export
order_veg <- function(veg) {
  veg$siteid <- factor(veg$siteid, levels = site_levels(), ordered = TRUE)
  veg$Region <- factor(veg$Region, levels = region_levels(), ordered = TRUE)
  veg$status <- factor(veg$status, levels = status_levels(), ordered = TRUE)
  veg$Habitat_final <- factor(
    veg$Habitat_final,
    levels = habitat_levels(),
    ordered = TRUE
  )
  veg
}

#' Clean Vegetation Metadata
#'
#' Converts metadata to long format, then adds Season and Habitat_final columns.
#' @param metadata A data frame as returned by \code{\link{load_veg_metadata}}.
#' @return A cleaned long-format data frame.
#' @export
clean_veg_metadata <- function(metadata) {
  long <- metadata |>
    dplyr::select(
      siteid,
      estuaryname,
      habitat,
      samplecollectiondate,
      vegetated_cover,
      non_vegetated_cover
    ) |>
    tidyr::pivot_longer(
      cols = c(vegetated_cover, non_vegetated_cover),
      names_to = "cover_type",
      values_to = "cover_value"
    )

  long |>
    dplyr::mutate(
      calendar_year = substr(samplecollectiondate, 1, 4),
      Season = assign_season(samplecollectiondate),
      Habitat_final = standardize_habitat(habitat)
    )
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
