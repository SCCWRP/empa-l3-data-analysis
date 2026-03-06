#' @title EMPA Data Loading Functions
#' @description Functions to load data from remote URLs and local CSV files.
#' @name data-loading

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
