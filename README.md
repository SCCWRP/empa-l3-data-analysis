# EMPAFunctionAnalysis

R package for the Estuary MPA (EMPA) Level 3 Dashboard data analysis.

---

## Metrics

All metric functions return a data frame with columns:
`estuaryname`, `siteid`, `year`, `function_name`, `indicator_name`, `metric_name`, `metric_score`

Static metrics (GIS/wetland inputs) do not include a `year` column, except `score_ruggedness()` which does.

| function_name | indicator_name | metric_name | R_function_name |
|---|---|---|---|
| Plant | alliances | plant_alliances | `metric-plant-alliances.R`<br>`score_plant_alliances()` |
| Plant | elevation | ruggedness | `metric-ruggedness.R`<br>`score_ruggedness()` |
| Plant | habitat | cram_index | `metric-cram-index.R`<br>`score_cram_index()` |
| Plant | inundation | marsh_plain_inundation | `metric-marsh-plain-inundation.R`<br>`score_marsh_plain_inundation()` |
| Plant | vegetation | invasive_severity | `metric-invasive-severity.R`<br>`score_invasive_severity()` |
| Plant | vegetation | native_cover | `metric-native-cover.R`<br>`score_native_cover()` |
| Plant | vegetation | veg_cover | `metric-veg-cover.R`<br>`score_veg_cover()` |
| SLR | accretion | sediment_supply | `metric-sediment-supply.R`<br>`score_sediment_supply()` |
| SLR | habitat | cram_index | `metric-cram-index.R`<br>`score_cram_index()` |
| SLR | resiliency | buffer_cover | `metric-buffer-cover.R`<br>`score_buffer_cover()` |
| SLR | resiliency | current_habitat_distribution | `metric-current-habitat-distribution.R`<br>`score_current_habitat_distribution()` |
| SLR | resiliency | future_habitat_distribution | `metric-future-habitat-distribution.R`<br>`score_future_habitat_distribution()` |
| SLR | resiliency | perimeter_contiguity | `metric-perimeter_contiguity.R`<br>`score_perimeter_contiguity()` |
| SLR | resiliency | perimeter_land_cover | `metric-perimeter-land-cover.R`<br>`score_perimeter_land_cover()` |
| SLR | vegetation | veg_cover | `metric-veg-cover.R`<br>`score_veg_cover()` |

---

## Plant

### habitat

#### cram_index

**Function:** `score_cram_index()`

**Calculation:** Filters vegetation data by year (from `samplecollectiondate`) or do all years. Filters CRAM data by year (from `Year_assessment`), groups by `Site`, and averages the `index` column to produce one site-level score per year. Left-joins averaged CRAM scores onto the vegetation site list. Sites with no CRAM data receive `NA`. Normalizes using `((empa_index - cram_min) / cram_range) * 100`, rounded to 1 decimal place.

**Inputs:**
- `cram`: CRAM data frame  columns `Site`, `Year_assessment`, `index`
- `vegetativecover_data`: Raw vegetation cover data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`

**Outputs:** One row per site per year. `metric_score` is `NA` for sites with no CRAM assessment in the selected year.

---

### elevation

#### ruggedness

**Function:** `score_ruggedness()`

**Calculation:** Passes the pre-computed surface ruggedness index directly through with no transformation. Higher values indicate greater topographic complexity.

**Inputs:**
- `rugged`: Ruggedness data frame  columns `estuaryname`, `siteid`, `Year`, `ruggedness`

**Outputs:** One row per site per year.

---

### inundation

#### marsh_plain_inundation

**Function:** `score_marsh_plain_inundation()`

**Calculation:** Details to be added.

**Inputs:**
- `vegetativecover_data`: Raw vegetation cover data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`

**Outputs:** One row per site per year. Currently returns `NA` for all sites.

---

### vegetation

#### invasive_severity

**Function:** `score_invasive_severity()`

**Calculation:** Extracts year from `samplecollectiondate` and filters to the requested year(s). Gets distinct invasive species per site and year using the Cal-IPC `rating` column. Starts at 100 and subtracts penalty points for each unique invasive species: Limited = 5 pts, Moderate = 10 pts, High = 15 pts. Score is floored at 0. Sites with no invasive species score 100.

**Inputs:**
- `vegetativecover_data`: Raw vegetation cover data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`, `scientificname`, `rating`

**Outputs:** One row per site per year.

---

#### native_cover

**Function:** `score_native_cover()`

**Calculation:** Extracts year from `samplecollectiondate` and filters to the requested year(s). Removes records with excluded statuses (`"Not recorded"`, `"naturalized"`), missing data sentinel (`-88`), and unknown species (scientificname starting with `"unknown"`). Sums `estimatedcover` by site, year, and status, then calculates native species as a percentage of total cover across all statuses. `metric_score` = percent native.

**Inputs:**
- `vegetativecover_data`: Raw vegetation cover data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`, `status`, `scientificname`, `estimatedcover`

**Outputs:** One row per site per year.

---

#### veg_cover

**Function:** `score_veg_cover()`

**Calculation:** Extracts year from `samplecollectiondate` and filters to the requested year(s). Removes missing data sentinel (`-88`). Sums `vegetated_cover` and `non_vegetated_cover` across all plots per site and year, then calculates vegetated cover as a percentage of total. `metric_score` = percent vegetated.

**Inputs:**
- `vegetation_sample_metadata`: Raw vegetation sample metadata data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`, `vegetated_cover`, `non_vegetated_cover`

**Outputs:** One row per site per year.

---

### alliances

#### plant_alliances

**Function:** `score_plant_alliances()`

**Calculation:** Details to be added.

**Inputs:**
- `vegetativecover_data`: Raw vegetation cover data frame  columns `estuaryname`, `siteid`, `samplecollectiondate`

**Outputs:** One row per site per year. Currently returns `NA` for all sites.

---

## SLR

### habitat

#### cram_index

Same function and calculation as [Plant > habitat > cram_index](#cram_index). Pass `function_name = "SLR"`.

---

### accretion

#### sediment_supply

**Function:** `score_sediment_supply()`

**Calculation:** Details to be added.

**Inputs:**
- `cram`: CRAM data frame  used only to obtain the site list

**Outputs:** One row per site. Static (no year variation). Currently returns `NA` for all sites.

---

### resiliency

#### buffer_cover

**Function:** `score_buffer_cover(buffer_size = "500 m", metric_name = "buffer_cover")`

**Calculation:** Filters GIS buffer data to the 500 m buffer. Groups landcover into "natural" (Ag + Natural) vs "Developed". Sums the `percent` column for natural classes per site. `metric_score` = percent natural landcover within the 500 m buffer.

**Inputs:**
- `gis_data`: GIS buffer land cover data frame  columns `estuaryname`, `siteid`, `buffer`, `landcover`, `percent`

**Outputs:** One row per site. Static (no year variation).

---

#### perimeter_land_cover

**Function:** `score_perimeter_land_cover()`

**Calculation:** Same as `buffer_cover` but using the 30 m buffer  captures the immediate perimeter of the site.

**Inputs:**
- `gis_data`: GIS buffer land cover data frame  columns `estuaryname`, `siteid`, `buffer`, `landcover`, `percent`

**Outputs:** One row per site. Static (no year variation).

---

#### perimeter_contiguity

**Function:** `score_perimeter_contiguity()`

**Calculation:** Filters GIS data to the "Largest Contiguous" and "Total Open" landcover rows, pivots to wide format, then computes `(Largest Contiguous / Total Open) * 100`. A higher score means the open space surrounding the site is less fragmented  better for wetland migration.

**Inputs:**
- `gis_data`: GIS buffer land cover data frame  columns `estuaryname`, `siteid`, `landcover`, `rastercount`

**Outputs:** One row per site. Static (no year variation).

---

#### current_habitat_distribution

**Function:** `score_current_habitat_distribution()`

**Calculation:** Filters wetland extents data to the `"Current Wetland Footprint"` extent. Pivots cover classes to wide format, sums the Low, Mid, and High marsh zone proportions, and multiplies by 100. `metric_score` = percent of current footprint that is vegetated marsh.

**Inputs:**
- `wetland`: Wetland extents data frame  columns `estuaryname`, `siteid`, `extent`, `cover_class`, `percent_cover`

**Outputs:** One row per site. Static (no year variation).

---

#### future_habitat_distribution

**Function:** `score_future_habitat_distribution()`

**Calculation:** Same as `current_habitat_distribution` but filtered to the `"Wetland Migration/Avoid Developed (1.2 ft)"` extent  a modeled scenario showing where the wetland could shift under 1.2 ft of sea level rise while avoiding developed land.

**Inputs:**
- `wetland`: Wetland extents data frame  columns `estuaryname`, `siteid`, `extent`, `cover_class`, `percent_cover`

**Outputs:** One row per site. Static (no year variation).

---

### vegetation

#### veg_cover

Same function and calculation as [Plant > vegetation > veg_cover](#veg_cover). Pass `function_name = "SLR"`.
