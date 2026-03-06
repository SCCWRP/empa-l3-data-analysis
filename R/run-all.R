#' @title Run All Analyses
#' @description Single entry point that runs the full Vegetation and SLR
#'   analysis pipelines, saving all tables as CSVs and all plots as PNGs to
#'   an output directory. All parameters are read from the active configuration
#'   (see \code{\link{load_config}}).
#' @name run-all

#' Run All EMPA Analyses
#'
#' Loads all data, runs cleaning, scoring, and plotting for both the Vegetation
#' and SLR pipelines, then writes every output to disk.
#'
#' @param output_dir Character. Path to the output directory. Created if it
#'   does not exist. Defaults to \code{"output"} in the current working
#'   directory.
#' @param config_path Character or NULL. Path to a custom YAML configuration
#'   file. If \code{NULL} (default), uses the default config bundled with the
#'   package. Pass a custom path to override any hard-coded values.
#' @return Invisibly returns a named list with all tables and plots.
#' @export
run_all <- function(output_dir = "output", config_path = NULL) {

  # Load configuration
  config <- load_config(config_path)
  ra_cfg <- config$run_all

  plot_width  <- ra_cfg$plot_width
  plot_height <- ra_cfg$plot_height
  plot_dpi    <- ra_cfg$plot_dpi

  # Year and season filters — convert numeric years to character for matching
  years   <- ra_cfg$years
  seasons <- ra_cfg$seasons
  if (!identical(years, "all")) {
    years <- as.character(unlist(years))
  }
  if (!identical(seasons, "all")) {
    seasons <- as.character(unlist(seasons))
  }

  # Create output subdirectories
  tables_dir <- file.path(output_dir, "tables")
  plots_dir  <- file.path(output_dir, "plots")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(plots_dir,  recursive = TRUE, showWarnings = FALSE)

  message("Loading data...")

  # -- Load all data --
  Veg             <- load_veg_data()
  Veg_metadata    <- load_veg_metadata()
  CRAM            <- load_cram_data()
  Rugged          <- load_ruggedness_data()
  wetland_extents <- load_wetland_extents()
  GIS_data        <- load_gis_data()

  message("Cleaning data...")

  # -- Clean all data --
  Veg                <- Veg |> clean_veg() |> order_veg()
  veg_metadata_clean <- Veg_metadata |> clean_veg_metadata() |> order_veg_metadata()
  wetland_extents    <- order_wetland_extents(wetland_extents)
  GIS_data           <- order_gis_data(GIS_data)

  # ===================================================================
  # VEGETATION PIPELINE
  # ===================================================================
  message("Running Vegetation scoring...")

  cram_veg_summary <- score_cram(CRAM, function_name = "Plant", config = config)
  veg_rel_summary  <- score_veg_relative(Veg, year = years, season = seasons,
                                          config = config)
  invasive_summary <- score_invasive_severity(Veg, year = years, season = seasons,
                                               config = config)
  veg_cov_summary  <- score_veg_cover(veg_metadata_clean, year = years,
                                       season = seasons, config = config)
  rugged_summary   <- score_ruggedness(Rugged)

  dashboard_table_veg <- build_veg_dashboard(
    cram_veg_summary, veg_rel_summary, veg_cov_summary,
    rugged_summary, invasive_summary
  )

  # ===================================================================
  # SLR PIPELINE
  # ===================================================================
  message("Running SLR scoring...")

  cram_slr_summary       <- score_cram(CRAM, function_name = "SLR", config = config)
  veg_cov_slr_summary    <- score_veg_cover(veg_metadata_clean, "SLR", "cover",
                                             year = years, season = seasons,
                                             config = config)
  buffer_500_summary     <- score_buffer(GIS_data, "500 m", config = config)
  buffer_30_summary      <- score_buffer(GIS_data, "30 m",
                                          cover_name = "perimeter_land_cover",
                                          config = config)
  contiguity_summary     <- score_contiguity(GIS_data, config = config)
  elevation_summary      <- score_elevation(wetland_extents, config = config)

  dashboard_table_slr <- build_slr_dashboard(
    cram_slr_summary, veg_cov_slr_summary,
    buffer_500_summary, buffer_30_summary,
    contiguity_summary, elevation_summary
  )

  # Combined master table
  dashboard_full <- dplyr::bind_rows(dashboard_table_veg, dashboard_table_slr)

  # ===================================================================
  # SAVE TABLES
  # ===================================================================
  message("Saving tables to ", tables_dir, "...")

  tables <- list(
    dashboard_veg             = dashboard_table_veg,
    dashboard_slr             = dashboard_table_slr,
    dashboard_full            = dashboard_full,
    cram_veg_summary          = cram_veg_summary,
    veg_relative_summary      = veg_rel_summary,
    invasive_severity_summary = invasive_summary,
    veg_cover_summary         = veg_cov_summary,
    ruggedness_summary        = rugged_summary,
    cram_slr_summary          = cram_slr_summary,
    veg_cover_slr_summary     = veg_cov_slr_summary,
    buffer_500_summary        = buffer_500_summary,
    buffer_30_summary         = buffer_30_summary,
    contiguity_summary        = contiguity_summary,
    elevation_summary         = elevation_summary
  )

  for (name in names(tables)) {
    utils::write.csv(tables[[name]],
                     file.path(tables_dir, paste0(name, ".csv")),
                     row.names = FALSE)
  }

  # ===================================================================
  # SAVE PLOTS
  # ===================================================================
  message("Saving plots to ", plots_dir, "...")

  save_plot <- function(plot, filename) {
    ggplot2::ggsave(
      filename = file.path(plots_dir, filename),
      plot     = plot,
      width    = plot_width,
      height   = plot_height,
      dpi      = plot_dpi
    )
  }

  # CRAM CDFs (driven by config)
  for (cram_plot in ra_cfg$cram_plots) {
    save_plot(
      plot_cram_cdf(CRAM,
                    state_col = cram_plot$state_col,
                    empa_col  = cram_plot$empa_col,
                    title     = cram_plot$title,
                    x_label   = cram_plot$x_label,
                    config    = config),
      cram_plot$filename
    )
  }

  # Vegetation abundance
  save_plot(
    plot_veg_abundance(Veg,
                       year   = years,
                       season = seasons,
                       config = config),
    "veg_abundance_native_status.png"
  )

  # Vegetated cover
  save_plot(
    plot_veg_cover(veg_metadata_clean,
                   year   = years,
                   config = config),
    "veg_cover_upper_marsh.png"
  )

  # Buffer land cover (driven by config)
  for (buf_plot in ra_cfg$buffer_plots) {
    save_plot(
      plot_buffer_landcover(GIS_data,
                            buffer_size = buf_plot$buffer_size,
                            config      = config),
      buf_plot$filename
    )
  }

  # Wetland habitat by region (driven by config)
  for (wl_plot in ra_cfg$wetland_regions) {
    save_plot(
      plot_wetland_habitat(wetland_extents,
                           region = wl_plot$region,
                           config = config),
      wl_plot$filename
    )
  }

  message("Done! All outputs saved to: ", normalizePath(output_dir))

  invisible(list(tables = tables))
}
