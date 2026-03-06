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

Each function is broken down into indicators, and each indicator has one or more metrics that produce a numeric score per site. The full structure is:

---

### Function 1: Plant (Vegetation Health)

#### Indicator: habitat

**Metric: index (CRAM)** : The CRAM (California Rapid Assessment Method) dataset contains a statewide index score for every wetland assessed in California between 2014 and 2024, plus each EMPA site's own index score. The raw EMPA index score is on a 25-100 scale. To normalize it to 0-100, the formula is: `((score - 25) / 75) * 100`, rounded to one decimal place. This gives a single number per site representing overall wetland condition as assessed by CRAM.

#### Indicator: vegetation

**Metric: native_cover** : Using the vegetation cover dataset (species-level plant cover estimates from field surveys), the code first removes records with status "Not recorded" or "naturalized", removes any records with the missing-data sentinel value (-88), and removes unknown species ("unknown plant", "unknown algae", etc.). It then groups all remaining plant cover by site and native status (native, non-native, invasive), sums the estimated cover for each group, and calculates the percentage that native species make up of the total. The result is a single "percent native cover" value per site.

**Metric: invasive_severity**: This measures how threatened the native plant community is by invasive species. For each site, the code identifies every unique invasive species present (using the Cal-IPC invasive rating). It starts with a perfect score of 100, then subtracts penalty points for each invasive species found: 5 points for "Limited" rating, 10 for "Moderate", 15 for "High". The score cannot go below 0. A site with no invasive species scores 100; a heavily invaded site scores lower.

**Metric: veg_cover** : Using the vegetation metadata dataset (which has plot-level summaries of vegetated vs. non-vegetated area), the code sums up total vegetated cover and total non-vegetated cover across all plots at each site, then calculates what percentage of the total is vegetated. This gives a single "percent vegetated" value per site.

#### Indicator: Elevation

**Metric: Ruggedness**: The ruggedness dataset contains pre-computed surface ruggedness index values for each site (measuring topographic complexity meaning higher values mean more microhabitat diversity). This value is taken directly from the dataset with no further calculation.

---

### Function 2: SLR (Sea Level Rise Vulnerability)

#### Indicator: Habitat

**Metric: index (CRAM)**: Same calculation as the Plant function (normalize EMPA index from 25-100 scale to 0-100), but labeled under the SLR function.

#### Indicator: vegetation

**Metric: veg_cover**: Same calculation as the Plant function (percent vegetated cover from metadata), but labeled under the SLR function with indicator "cover" instead of "vegetation".

#### Indicator: resiliency

**Metric: buffer_cover**: Using the buffer land cover dataset, the code filters to the 500m buffer around each site and groups land cover into "natural" (Agricultural + Natural) vs. "Developed". The natural percentage tells you how much undeveloped land surrounds the site more open land means more room for the wetland to migrate inland as sea levels rise.

**Metric: perimeter_land_cover**: Same calculation as the 500m buffer, but using the 30m buffer. This captures the immediate perimeter whether the wetland has open space right at its edges.

**Metric: perimeter_contiguity**: Using the buffer land cover dataset, the code looks at the "Largest Contiguous" open area and the "Total Open" area (from raster pixel counts). It divides the largest contiguous patch by the total open area and multiplies by 100. A high percentage means the open space around the site is one connected patch rather than fragmented pieces — better for wetland migration.

**Metric: current_habitat_distribution**: Using the habitat zones dataset, the code filters to the "Current Wetland Footprint" extent and sums the percent cover of the Low, Mid, and High marsh zones (multiplied by 100 to convert from proportion to percentage). This tells you how much of the current wetland footprint is vegetated marsh.

**Metric: future_habitat_distribution**: Same calculation, but using the "Wetland Migration/Avoid Developed (1.2 ft)" extent — a modeled scenario showing where the wetland could shift under 1.2 feet of sea level rise, avoiding developed areas. Comparing this to current extent shows whether the wetland has room to migrate upslope.

---

### Final Dashboard Tables

All the individual metric scores are assembled into long-format tables where every row has the same structure:

| Column | Description |
|---|---|
| `estuaryname` | Full estuary name (e.g., "Bolinas Lagoon") |
| `siteid` | Short site code (e.g., "NC-BOL") |
| `function_name` | Which function produced this row ("Plant" or "SLR") |
| `indicator_name` | Which indicator (e.g., "habitat", "vegetation", "migration") |
| `metric_name` | The specific metric (e.g., "index", "native_cover", "buffer_cover") |
| `metric_score` | The numeric score |

Three tables are produced: one for Plant, one for SLR, and a combined master table.

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
