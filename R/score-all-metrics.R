#' @title Score All Metrics
#' @description Runs all metric functions and returns a single combined table.
#' @name score-all-metrics
NULL

#' Score All Metrics
#'
#' Calls every metric function and row-binds the results into one long-format
#' table. Static metrics (GIS/wetland inputs) produce rows with \code{year = NA}.
#'
#' @param cram CRAM data frame — columns \code{siteid}, \code{MPA},
#'   \code{stationno}, \code{year}, \code{index}, \code{biotic},
#'   \code{physical}.
#' @param vegetativecover_data Raw vegetation cover data frame — columns
#'   \code{estuaryname}, \code{siteid}, \code{samplecollectiondate},
#'   \code{status}, \code{scientificname}, \code{estimatedcover}, \code{rating}.
#' @param vegetation_sample_metadata Raw vegetation sample metadata data frame —
#'   columns \code{estuaryname}, \code{siteid}, \code{samplecollectiondate},
#'   \code{vegetated_cover}, \code{non_vegetated_cover}.
#' @param gis_data GIS buffer land cover data frame — columns \code{estuaryname},
#'   \code{siteid}, \code{buffer}, \code{landcover}, \code{percent},
#'   \code{rastercount}.
#' @param wetland Wetland extents data frame — columns \code{estuaryname},
#'   \code{siteid}, \code{extent}, \code{cover_class}, \code{percent_cover}.
#' @param rugged Ruggedness data frame — columns \code{estuaryname},
#'   \code{siteid}, \code{ruggedness}.
#' @param year Numeric or character vector of years to include, or \code{"all"}.
#'   Default \code{"all"}.
#' @return A long-format data frame with columns: estuaryname, siteid, year,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
score_all_metrics <- function(
  vegetation_sample_metadata,
  vegetativecover_data,
  cram,
  gis_data,
  wetland,
  rugged,
  year = "all"
) {
  dplyr::bind_rows(
    ## Plant
    # CRAM index (habitat)
    score_cram_index(
      cram = cram,
      vegetativecover_data = vegetativecover_data,
      function_name = "Plant",
      year = year
    ),
    # Ruggedness (elevation)
    score_ruggedness(rugged),
    # Marsh plain inundation (inundation)
    score_marsh_plain_inundation(
      vegetativecover_data = vegetativecover_data,
      year = year
    ),
    # Invasive severity (vegetation)
    score_invasive_severity(
      vegetativecover_data = vegetativecover_data,
      year = year
    ),
    # Native cover (vegetation)
    score_native_cover(
      vegetativecover_data = vegetativecover_data,
      year = year
    ),
    # Vegetated cover (vegetation)
    score_veg_cover(
      vegetation_sample_metadata = vegetation_sample_metadata,
      function_name = "Plant",
      year = year
    ),
    # Plant alliances (alliances)
    score_plant_alliances(
      vegetativecover_data = vegetativecover_data,
      year = year
    ),

    ## SLR
    # CRAM index (habitat)
    score_cram_index(
      cram = cram,
      vegetativecover_data = vegetativecover_data,
      function_name = "SLR",
      year = year
    ),
    # Sediment supply (accretion)
    score_sediment_supply(vegetativecover_data),
    # Buffer cover 500m (resiliency)
    score_buffer_cover(
      gis_data = gis_data,
      buffer_size = "500 m",
      metric_name = "buffer_cover"
    ),
    # Perimeter land cover 30m (resiliency)
    score_perimeter_land_cover(gis_data = gis_data),
    # Perimeter contiguity (resiliency)
    score_perimeter_contiguity(gis_data),
    # Current habitat distribution (resiliency)
    score_current_habitat_distribution(wetland),
    # Future habitat distribution (resiliency)
    score_future_habitat_distribution(wetland),
    # Vegetated cover (vegetation)
    score_veg_cover(
      vegetation_sample_metadata = vegetation_sample_metadata,
      function_name = "SLR",
      year = year
    )
  )
}
