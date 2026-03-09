# EMPAFunctionAnalysis

R package for the Estuary MPA (EMPA) Level 3 Dashboard data analysis. Produces condition scores and visualizations for California estuary sites, evaluating both current vegetation health and vulnerability to sea level rise.

## Installation

```r
devtools::install()
library(EMPAFunctionAnalysis)
```

## Quick Start

```r
# Run everything with all years and seasons
run_all()

# Run with a custom config file (e.g. to filter to specific years)
run_all(config_path = "path/to/my_config.yaml")
```

## What This Package Does

This package evaluates each estuary site along two dimensions:

1. **How healthy is the vegetation right now?** (the "Plant" function)
2. **How vulnerable is the site to sea level rise?** (the "SLR" function)

Each function is broken down into indicators, and each indicator has one or more metrics that produce a numeric score per site.

---

## Metrics

All metric functions return a data frame with columns:
`estuaryname`, `siteid`, `year`, `function_name`, `indicator_name`, `metric_name`, `metric_score`

---

### Metric: cram_index

**Function:** `score_cram_index()`

**Calculation:** Filters vegetation data by year (from `samplecollectiondate`) to get the list of surveyed sites. Filters CRAM data by year (from `Year_assessment`), then groups by `Site` and averages the `index` column to produce one site-level score per year. Left-joins the averaged CRAM scores onto the vegetation site list — sites with no CRAM data receive `NA`. Normalizes using `((empa_index - cram_min) / cram_range) * 100`, rounded to 1 decimal place.

**Inputs:**
- `cram`: CRAM data frame — columns `Site`, `Year_assessment`, `index`
- `vegetativecover_data`: Vegetation cover data frame — columns `estuaryname`, `siteid`, `samplecollectiondate`

**Outputs:** One row per site per year per `function_name` value. `metric_score` is `NA` for sites with no CRAM assessment in the selected year.

---

### Metric: ruggedness

**Function:** `score_ruggedness()`

**Calculation:** Passes the pre-computed surface ruggedness index directly through with no transformation. Higher values indicate greater topographic complexity.

**Inputs:**
- `rugged`: Ruggedness data frame — columns `estuaryname`, `siteid`, `ruggedness`

**Outputs:** One row per site. Static (no year variation).

---

### Metric: native_cover

**Function:** `score_native_cover()`

**Calculation:** Filters to the requested year/season. Removes records with excluded statuses (`"Not recorded"`, `"naturalized"`) and missing data sentinel (`-88`). Sums `estimatedcover` by site and native status, then calculates native species as a percentage of total cover across all statuses. `metric_score` = percent native.

**Inputs:**
- `vegetativecover_data`: Cleaned vegetation cover data frame — columns `estuaryname`, `siteid`, `calendar_year`, `Season`, `status`, `estimatedcover`

**Outputs:** One row per site per year/season combination.

---

### Metric: invasive_severity

**Function:** `score_invasive_severity()`

**Calculation:** Filters to the requested year/season. Gets distinct species per site. Starts at `base_score` (100) and subtracts penalty points for each unique invasive species based on Cal-IPC rating: Limited = 5 pts, Moderate = 10 pts, High = 15 pts. Score is floored at 0.

**Inputs:**
- `vegetativecover_data`: Cleaned vegetation cover data frame — columns `estuaryname`, `siteid`, `calendar_year`, `Season`, `scientificname`, `rating`

**Outputs:** One row per site per year/season combination.

---

### Metric: veg_cover

**Function:** `score_veg_cover()`

**Calculation:** Filters to the requested year/season and removes missing data sentinel (`-88`). Sums `vegetated_cover` and `non_vegetated_cover` across all plots per site, then calculates vegetated cover as a percentage of total. `metric_score` = percent vegetated.

**Inputs:**
- `vegetation_sample_metadata`: Cleaned metadata data frame in long format — columns `estuaryname`, `siteid`, `calendar_year`, `Season`, `cover_type`, `cover_value`

**Outputs:** One row per site per year/season combination.

---

### Metric: buffer_cover

**Function:** `score_buffer_cover()`

**Calculation:** Filters GIS buffer data to the specified buffer distance (`buffer_size`). Groups landcover classes into "natural" (Ag + Natural) vs. "Developed". Sums the `percent` column for natural classes per site. `metric_score` = percent natural landcover within the buffer.

**Inputs:**
- `gis_data`: GIS buffer land cover data frame — columns `estuaryname`, `siteid`, `buffer`, `landcover`, `percent`

**Outputs:** One row per site. Static (no year variation). Called twice: once for the 500 m buffer (`metric_name = "buffer_cover"`) and once for the 30 m buffer (`metric_name = "perimeter_land_cover"`).

---

### Metric: perimeter_contiguity

**Function:** `score_perimeter_contiguity()`

**Calculation:** Filters GIS data to the "Largest Contiguous" and "Total Open" landcover rows, pivots to wide format, then computes `(Largest Contiguous / Total Open) * 100`. A higher score means the open space surrounding the site is less fragmented.

**Inputs:**
- `gis_data`: GIS buffer land cover data frame — columns `estuaryname`, `siteid`, `landcover`, `rastercount`

**Outputs:** One row per site. Static (no year variation).

---

### Metric: current_habitat_distribution

**Function:** `score_current_extent()`

**Calculation:** Filters wetland extents data to the `"Current Wetland Footprint"` extent. Pivots cover classes to wide format, sums the Low, Mid, and High marsh zone proportions, and multiplies by 100. `metric_score` = percent of current footprint that is vegetated marsh.

**Inputs:**
- `wetland`: Wetland extents data frame — columns `estuaryname`, `siteid`, `extent`, `cover_class`, `percent_cover`

**Outputs:** One row per site. Static (no year variation).

---

### Metric: future_habitat_distribution

**Function:** `score_future_extent()`

**Calculation:** Same as `current_habitat_distribution` but filtered to the `"Wetland Migration/Avoid Developed (1.2 ft)"` extent — a modeled scenario showing where the wetland could shift under 1.2 ft of sea level rise while avoiding developed land.

**Inputs:**
- `wetland`: Wetland extents data frame — columns `estuaryname`, `siteid`, `extent`, `cover_class`, `percent_cover`

**Outputs:** One row per site. Static (no year variation).

---

### Metric: sediment_supply

**Function:** `score_sediment_supply()`

**Calculation:** Placeholder — returns `NA` for all sites. Calculation not yet implemented.

**Inputs:**
- `cram`: CRAM data frame (used only to obtain the site list)

**Outputs:** One row per site. Static (no year variation).

---

### Metric: marsh_plain_inundation

**Function:** `score_marsh_plain_inundation()`

**Calculation:** Placeholder — returns `NA` for all sites. Calculation not yet implemented.

**Inputs:**
- `vegetativecover_data`: Cleaned vegetation cover data frame (used only to obtain the site list for the requested year/season)

**Outputs:** One row per site per year/season combination.

---

### Metric: plant_alliances

**Function:** `score_plant_alliances()`

**Calculation:** Placeholder — returns `NA` for all sites. Calculation not yet implemented.

**Inputs:**
- `vegetativecover_data`: Cleaned vegetation cover data frame (used only to obtain the site list for the requested year/season)

**Outputs:** One row per site per year/season combination.

### Plots

The package produces 10 plots that visualize the underlying data (not the scores):

| Plot | What it shows |
|---|---|
| **CRAM CDFs** (3 plots) | Cumulative distribution of all statewide CRAM scores (index, biotic structure, physical structure) with each EMPA site's score overlaid as a labeled point. Shows where each site falls relative to all California wetlands. |
| **Vegetation Abundance** | Horizontal stacked bars showing the relative proportion of native, non-native, and invasive plant cover at each site. |
| **Vegetated Cover** | Horizontal stacked bars showing vegetated vs. non-vegetated cover in upper marsh habitats (mid + high marsh) at each site. |
| **Buffer Land Cover** (2 plots) | Stacked bars showing the proportion of developed, agricultural, and natural land in the 500m and 30m buffers around each site. |
| **Wetland Habitat by Region** (3 plots) | Faceted bar charts comparing habitat zone distributions (low/mid/high marsh) between the current footprint and the projected sea level rise scenario, for each site within a region (North, Central, South). |

### Outputs

`run_all()` writes everything to the `output/` directory:

- **`output/tables/`** — 14 CSV files: the 3 dashboard tables plus each individual scoring table
- **`output/plots/`** — 10 PNG files

## Configuration

Every value that could change between analyses lives in a single YAML config file. This includes season definitions (which months are Spring vs Fall), habitat name aliases, site orderings, color palettes, scoring parameters, plot styling, and which years/seasons to include.

### Filtering by year and season

The `years` and `seasons` settings in the config control which data is included in scoring and plots. By default both are `"all"` (no filtering). To analyze only 2023 Fall data, set:

```yaml
run_all:
  years: [2023]
  seasons: ["Fall"]
```

To analyze multiple years together:

```yaml
run_all:
  years: [2021, 2023]
  seasons: "all"
```

### Customizing the config

```r
# Copy the default config
file.copy(
  system.file("config", "default_config.yaml", package = "EMPAFunctionAnalysis"),
  "my_config.yaml"
)

# Edit my_config.yaml as needed, then run with it
run_all(config_path = "my_config.yaml")
```

See `inst/config/default_config.yaml` for the full list of configurable values with comments.

## Project Structure

```
EMPAFunctionAnalysis/
  R/
    config.R               Config loading (load_config, get_config)
    lookups.R              Lookup tables (read from config)
    data-loading.R         6 data loader functions
    data-cleaning.R        Cleaning and factor ordering
    scoring.R              8 scoring functions (Plant + SLR)
    plotting.R             6 plot functions + shared theme
    dashboard.R            Dashboard table assembly
    run-all.R              run_all() entry point
  inst/
    config/
      default_config.yaml  All configurable values
    extdata/               Bundled CSV data files
  vignettes/
    veg-analysis.Rmd       Vegetation pipeline walkthrough
    slr-analysis.Rmd       SLR pipeline walkthrough
```

## Using Individual Functions

You don't have to use `run_all()`. Each function works independently:

```r
library(EMPAFunctionAnalysis)

# Optionally load a custom config
load_config("my_config.yaml")

# Load and clean one dataset
Veg <- load_veg_data() |> clean_veg() |> order_veg()

# Score using only 2023 data
invasive <- score_invasive_severity(Veg, year = "2023")

# Score using all years (default)
invasive_all <- score_invasive_severity(Veg)

# Plot for 2023 Fall only
plot_veg_abundance(Veg, year = "2023", season = "Fall")

# Plot for all years and seasons
plot_veg_abundance(Veg)
```
