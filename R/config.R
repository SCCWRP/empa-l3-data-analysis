#' @title EMPA Configuration Management
#' @description Functions to load and access the YAML configuration file that
#'   centralizes all hard-coded values for the package.
#' @name config

# Package-level environment to cache the active configuration
.empa_env <- new.env(parent = emptyenv())

#' Load Configuration
#'
#' Reads a YAML configuration file and caches it for use by all package
#' functions. If no path is provided, loads the default config bundled with the
#' package. Call this once at the start of an analysis, or pass a custom config
#' path to override any default values.
#'
#' @param path Character. Path to a YAML configuration file. If \code{NULL}
#'   (default), uses \code{inst/config/default_config.yaml} bundled with the
#'   package.
#' @return The parsed configuration as a named list (invisibly).
#' @export
load_config <- function(path = NULL) {
  if (is.null(path)) {
    path <- system.file(
      "config", "default_config.yaml",
      package = "EMPAFunctionAnalysis"
    )
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
