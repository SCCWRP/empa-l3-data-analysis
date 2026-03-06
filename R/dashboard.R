#' @title EMPA Dashboard Table Assembly
#' @description Functions to combine individual scoring tables into the final
#'   long-format dashboard tables.
#' @name dashboard
#' @importFrom dplyr bind_rows select
#' @importFrom tidyr pivot_longer

#' Build Vegetation Dashboard Table
#'
#' Combines CRAM, native cover, veg cover, ruggedness, and invasive severity
#' summary tables into a single long-format dashboard table.
#'
#' @param cram_summary Output of \code{score_cram(cram, "Plant")}.
#' @param veg_rel_summary Output of \code{\link{score_veg_relative}}.
#' @param veg_cov_summary Output of \code{\link{score_veg_cover}}.
#' @param rugged_summary Output of \code{\link{score_ruggedness}}.
#' @param invasive_summary Output of \code{\link{score_invasive_severity}}.
#' @return A long-format data frame with columns: estuaryname, siteid,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
build_veg_dashboard <- function(
  cram_summary,
  veg_rel_summary,
  veg_cov_summary,
  rugged_summary,
  invasive_summary
) {
  combined <- dplyr::bind_rows(
    cram_summary,
    veg_rel_summary,
    veg_cov_summary,
    rugged_summary,
    invasive_summary
  )

  combined |>
    tidyr::pivot_longer(
      cols = c(index, native_cover, native_resiliency, veg_cover, ruggedness),
      names_to = "metric_name",
      values_to = "metric_score",
      values_drop_na = TRUE
    )
}

#' Build SLR Dashboard Table
#'
#' Combines CRAM, veg cover, buffer, contiguity, and elevation summary tables
#' into a single long-format dashboard table.
#'
#' @param cram_summary Output of \code{score_cram(cram, "SLR")}.
#' @param veg_cov_summary Output of \code{score_veg_cover(metadata, "SLR", "cover")}.
#' @param buffer_500_summary Output of \code{score_buffer(gis, "500 m")}.
#' @param buffer_30_summary Output of \code{score_buffer(gis, "30 m", "perimeter_land_cover")}.
#' @param contiguity_summary Output of \code{\link{score_contiguity}}.
#' @param elevation_summary Output of \code{\link{score_elevation}}.
#' @return A long-format data frame with columns: estuaryname, siteid,
#'   function_name, indicator_name, metric_name, metric_score.
#' @export
build_slr_dashboard <- function(
  cram_summary,
  veg_cov_summary,
  buffer_500_summary,
  buffer_30_summary,
  contiguity_summary,
  elevation_summary
) {
  combined <- dplyr::bind_rows(
    cram_summary,
    veg_cov_summary,
    buffer_500_summary,
    buffer_30_summary,
    contiguity_summary,
    elevation_summary
  )

  combined |>
    dplyr::select(
      -dplyr::any_of(c("Developed", "Total Open", "Largest Contiguous"))
    ) |>
    tidyr::pivot_longer(
      cols = c(
        index,
        veg_cover,
        buffer_cover,
        perimeter_land_cover,
        perimeter_contiguity,
        current_extent,
        future_extent
      ),
      names_to = "metric_name",
      values_to = "metric_score",
      values_drop_na = TRUE
    )
}
