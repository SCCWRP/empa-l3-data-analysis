#' @title EMPA Plot Functions
#' @description Reusable plotting functions for the EMPA dashboard, built on
#'   ggplot2. All functions return ggplot objects that can be further customized.
#'   Hard-coded parameters are read from the active configuration (see
#'   \code{\link{load_config}}).
#' @name plotting
#' @importFrom ggplot2 ggplot aes stat_ecdf geom_point geom_bar theme_bw theme
#'   element_text element_blank scale_y_continuous scale_x_discrete
#'   scale_fill_manual coord_flip xlab ylab ggtitle facet_wrap
#' @importFrom ggrepel geom_text_repel
#' @importFrom stringr str_wrap

#' EMPA Standard Theme
#'
#' Returns a list of ggplot2 theme elements used across all EMPA dashboard
#' plots for consistent styling.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A list of ggplot2 theme objects (add to a plot with \code{+}).
#' @export
empa_theme <- function(config = get_config()) {
  th <- config$theme
  list(
    ggplot2::theme_bw(),
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold", size = th$title_size, hjust = 0.5
      ),
      axis.title.x = ggplot2::element_text(
        face = "bold", size = th$axis_title_size
      ),
      axis.text.x = ggplot2::element_text(size = th$axis_text_size),
      axis.title.y = ggplot2::element_text(
        angle = 90, face = "bold", size = th$axis_title_size, vjust = 1.5
      ),
      axis.text.y = ggplot2::element_text(size = th$axis_text_size),
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = th$legend_text_size)
    )
  )
}

#' Plot CRAM CDF
#'
#' Plots an empirical CDF of statewide CRAM scores with EMPA site points
#' overlaid and labeled.
#'
#' @param cram A data frame containing CRAM data (must have columns specified
#'   by \code{state_col}, \code{empa_col}, \code{mpa_col}, and \code{id_col}).
#' @param state_col Character. Column name for the statewide score distribution
#'   (x-axis of the CDF).
#' @param empa_col Character. Column name for the EMPA site-specific score
#'   (plotted as points on the CDF).
#' @param mpa_col Character. Column name for the MPA status fill aesthetic.
#' @param id_col Character. Column name for site ID labels.
#' @param title Character. Plot title.
#' @param x_label Character. X-axis label.
#' @param colors Character vector of length 2. Fill colors for MPA categories.
#'   Defaults to the MPA palette from \code{\link{empa_palettes}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A ggplot object.
#' @export
plot_cram_cdf <- function(
  cram,
  state_col,
  empa_col,
  mpa_col = "EMPA_MPA",
  id_col = "siteid",
  title = "Statewide CRAM Scores",
  x_label = "CRAM Score",
  colors = empa_palettes()$mpa,
  config = get_config()
) {
  cdf_cfg <- config$plots$cram_cdf

  cdf_fn <- stats::ecdf(cram[[state_col]])
  cram[["..cdf_y"]] <- cdf_fn(cram[[empa_col]])

  ggplot2::ggplot(cram, ggplot2::aes(x = .data[[state_col]])) +
    ggplot2::stat_ecdf(geom = "step", color = "black", linewidth = 1) +
    empa_theme(config) +
    ggplot2::xlab(x_label) +
    ggplot2::ylab("% of Population") +
    ggplot2::ggtitle(title) +
    ggplot2::scale_y_continuous(
      breaks = seq(0, 1, cdf_cfg$y_breaks_by),
      labels = seq(0, 100, cdf_cfg$y_labels_by)
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = .data[[empa_col]],
        y = .data[["..cdf_y"]],
        fill = .data[[mpa_col]]
      ),
      size = cdf_cfg$point_size,
      shape = 21
    ) +
    ggplot2::scale_fill_manual(values = colors, na.translate = FALSE) +
    ggrepel::geom_text_repel(
      ggplot2::aes(
        x = .data[[empa_col]],
        y = .data[["..cdf_y"]],
        label = .data[[id_col]]
      ),
      size = cdf_cfg$label_size,
      nudge_y = cdf_cfg$nudge_y,
      hjust = 1,
      direction = "y",
      force = 2
    )
}

#' Plot Vegetation Relative Abundance by Native Status
#'
#' Horizontal stacked bar chart showing relative proportions of native,
#' non-native, and invasive cover across sites.
#'
#' @param veg A cleaned vegetation data frame (output of \code{\link{clean_veg}}
#'   and \code{\link{order_veg}}).
#' @param year Character vector of calendar years to include (e.g.
#'   \code{"2023"} or \code{c("2021", "2023")}), or \code{"all"} for all years.
#' @param season Character vector of seasons to include (e.g. \code{"Fall"}),
#'   or \code{"all"} for all seasons.
#' @param title Character. Plot title.
#' @param colors Character vector. Fill colors for native status categories.
#'   Defaults to the vegetation palette from \code{\link{empa_palettes}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A ggplot object.
#' @export
plot_veg_abundance <- function(
  veg,
  year = "all",
  season = "all",
  title = "Vegetation - Native vs Non-Native by Site",
  colors = empa_palettes()$vegetation,
  config = get_config()
) {
  va_cfg <- config$plots$veg_abundance
  exclude_names    <- unlist(va_cfg$exclude_commonnames)
  exclude_statuses <- unlist(va_cfg$exclude_statuses)
  legend_labels    <- unlist(va_cfg$legend_labels)

  filtered <- veg |>
    dplyr::filter(
      .data$covertype == "vegetation",
      !.data$commonname %in% exclude_names,
      !.data$status %in% exclude_statuses
    )

  if (!identical(year, "all")) {
    filtered <- dplyr::filter(filtered, .data$calendar_year %in% year)
  }
  if (!identical(season, "all")) {
    filtered <- dplyr::filter(filtered, .data$Season %in% season)
  }

  filtered |>
    ggplot2::ggplot(ggplot2::aes(
      y = .data$estimatedcover,
      x = .data$siteid,
      fill = .data$status
    )) +
    empa_theme(config) +
    ggplot2::scale_fill_manual(
      values = colors,
      labels = stringr::str_wrap(legend_labels, width = 14)
    ) +
    ggplot2::scale_x_discrete(limits = rev) +
    ggplot2::coord_flip() +
    ggplot2::theme(
      strip.text.x = ggplot2::element_text(face = "bold", size = 16)
    ) +
    ggplot2::geom_bar(position = "fill", stat = "identity") +
    ggplot2::xlab("Site ID") +
    ggplot2::ylab("Relative Abundance") +
    ggplot2::ggtitle(title) +
    ggplot2::theme(legend.position = "bottom")
}

#' Plot Percent Vegetated Cover in Upper Marsh
#'
#' Horizontal stacked bar chart of vegetated vs non-vegetated cover for
#' upper marsh habitats.
#'
#' @param metadata A cleaned veg metadata data frame (output of
#'   \code{\link{clean_veg_metadata}} and \code{\link{order_veg_metadata}}).
#' @param year Character vector of calendar years to include (e.g.
#'   \code{"2023"} or \code{c("2021", "2023")}), or \code{"all"} for all years.
#' @param exclude_habitats Character vector. Habitats to exclude from the plot.
#'   Defaults to values from config.
#' @param title Character. Plot title.
#' @param colors Character vector of length 2. Fill colors for cover types.
#'   Defaults to the veg_open palette from \code{\link{empa_palettes}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A ggplot object.
#' @export
plot_veg_cover <- function(
  metadata,
  year = "all",
  exclude_habitats = NULL,
  title = "Percent Vegetated Cover in Upper Marsh Habitats",
  colors = empa_palettes()$veg_open,
  config = get_config()
) {
  vc_cfg <- config$plots$veg_cover
  if (is.null(exclude_habitats)) {
    exclude_habitats <- unlist(vc_cfg$exclude_habitats)
  }
  legend_labels <- unlist(vc_cfg$legend_labels)

  filtered <- metadata |>
    dplyr::filter(
      !.data$habitat %in% exclude_habitats,
      .data$siteid != "NA"
    )

  if (!identical(year, "all")) {
    filtered <- dplyr::filter(filtered, .data$calendar_year %in% year)
  }

  filtered |>
    ggplot2::ggplot(ggplot2::aes(
      y = .data$cover_value,
      x = .data$siteid,
      fill = .data$cover_type
    )) +
    empa_theme(config) +
    ggplot2::scale_fill_manual(
      values = colors,
      labels = stringr::str_wrap(legend_labels, width = 14)
    ) +
    ggplot2::scale_x_discrete(limits = rev) +
    ggplot2::coord_flip() +
    ggplot2::geom_bar(position = "fill", stat = "identity") +
    ggplot2::ylab("Percent Cover") +
    ggplot2::xlab("Site ID") +
    ggplot2::ggtitle(title) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(scale = 100))
}

#' Plot Buffer Land Cover Distribution
#'
#' Stacked bar chart showing land cover class proportions by site for a
#' given buffer distance.
#'
#' @param gis_data A cleaned GIS data frame (output of
#'   \code{\link{order_gis_data}}).
#' @param buffer_size Character. Buffer distance to filter (e.g. "500 m", "30 m").
#' @param title Character. Plot title. If NULL, a default title is generated.
#' @param colors Character vector. Fill colors for land cover classes.
#'   Defaults to the landcover palette from \code{\link{empa_palettes}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A ggplot object.
#' @export
plot_buffer_landcover <- function(
  gis_data,
  buffer_size,
  title = NULL,
  colors = empa_palettes()$landcover,
  config = get_config()
) {
  if (is.null(title)) {
    title <- paste0("Buffer Land Cover Class Distribution (", buffer_size, ")")
  }

  gis_data |>
    dplyr::filter(.data$buffer == buffer_size) |>
    ggplot2::ggplot(ggplot2::aes(
      x = .data$siteid,
      y = .data$percent,
      fill = .data$landcover
    )) +
    empa_theme(config) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::geom_bar(position = "fill", stat = "identity") +
    ggplot2::scale_y_continuous(labels = scales::percent_format(scale = 100)) +
    ggplot2::xlab("Site ID") +
    ggplot2::ylab("Percent Cover") +
    ggplot2::ggtitle(title) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 8, angle = 45, hjust = 1),
      axis.text.y = ggplot2::element_text(size = 12),
      strip.text = ggplot2::element_text(face = "bold", size = 10)
    )
}

#' Plot Wetland Habitat Distribution by Region
#'
#' Faceted stacked bar chart comparing habitat zone distributions across
#' sea level rise extents for a single region.
#'
#' @param wetland A cleaned wetland extents data frame (output of
#'   \code{\link{order_wetland_extents}}).
#' @param region Character. Region to filter (e.g. "North", "Central", "South").
#' @param exclude_classes Character vector. Cover classes to exclude.
#'   Defaults to values from config.
#' @param title Character. Plot title.
#' @param colors Character vector. Fill colors for cover classes.
#'   Defaults to the elevation palette from \code{\link{empa_palettes}}.
#' @param config A configuration list. Defaults to \code{\link{get_config}()}.
#' @return A ggplot object.
#' @export
plot_wetland_habitat <- function(
  wetland,
  region,
  exclude_classes = NULL,
  title = "Habitat Distribution Comparison",
  colors = empa_palettes()$elevation,
  config = get_config()
) {
  wh_cfg <- config$plots$wetland_habitat
  if (is.null(exclude_classes)) {
    exclude_classes <- unlist(wh_cfg$exclude_classes)
  }
  bar_width  <- wh_cfg$bar_width
  wrap_width <- wh_cfg$x_label_wrap_width

  # Accommodate both capitalization variants from the raw data
  region_col <- if ("Region" %in% names(wetland)) "Region" else "region"
  cover_col <- if ("Cover_class" %in% names(wetland)) {
    "Cover_class"
  } else {
    "cover_class"
  }
  pct_col <- if ("Percent_cover" %in% names(wetland)) {
    "Percent_cover"
  } else {
    "percent_cover"
  }
  extent_col <- if ("Extent" %in% names(wetland)) "Extent" else "extent"
  site_col <- if ("Site_ID" %in% names(wetland)) "Site_ID" else "siteid"

  wetland |>
    dplyr::filter(
      .data[[region_col]] == region,
      !.data[[cover_col]] %in% exclude_classes
    ) |>
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[extent_col]],
      y = .data[[pct_col]],
      fill = .data[[cover_col]]
    )) +
    empa_theme(config) +
    ggplot2::geom_bar(
      position = "fill", stat = "identity", width = bar_width
    ) +
    ggplot2::facet_wrap(stats::as.formula(paste("~", site_col)), ncol = 2) +
    ggplot2::xlab("Sea Level Rise") +
    ggplot2::ylab("Relative Cover") +
    ggplot2::ggtitle(title) +
    ggplot2::scale_fill_manual(values = colors) +
    ggplot2::scale_x_discrete(labels = function(x) {
      stringr::str_wrap(x, width = wrap_width)
    }) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(size = 8),
      axis.text.y = ggplot2::element_text(size = 12),
      strip.text = ggplot2::element_text(face = "bold", size = 10)
    )
}
