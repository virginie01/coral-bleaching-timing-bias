# 03_flagging

## Overview

This folder contains the scripts, helper functions, outputs, and summary products used for the **flagging stage** of the coral bleaching severity workflow.

The purpose of the flagging workflow is to identify observations where modeled bleaching severity suggests:

- bleaching conditions may worsen beyond what was observed at sampling,
- peak bleaching severity is likely underestimated

The workflow applies fitted Bayesian ordinal regression (`brms`) models to estimate bleaching severity probabilities under both:

- **Pre-peak conditions** — observations collected before peak heat stress is reached.
- **Post-peak conditions** — observations collected after maximum heat stress has occurred.

For every observation, the workflow generates posterior predictions of bleaching severity and derives summary metrics describing:

- the most likely bleaching severity states at the survey date and at peak heat stress,
- median predicted bleaching severity states at the survey date and at peak heat stress,
- and a series of logical flags (`flag1`–`flag4`) used to identify observations that may underestimate peak bleaching severity.

The general workflow is:

1. Import pre-screened bleaching datasets.
2. Standardize data types and factor levels.
3. Load fitted `brms` severity models.
4. Generate posterior predictions for bleaching severity classes.
5. Derive prediction summary metrics for each bleaching report:
   - `mode_cur`
   - `median_cur`
   - `mode_max`
   - `median_max`
6. Compute logical flag variables (`flag1`–`flag4`) for each bleaching report.
7. Export flagged datasets.
8. Generate summary tables and publication-quality figures.

The resulting outputs are used to evaluate how observed bleaching compares with predicted peak bleaching severity across regions, years, and thermal stress conditions.

---

## Subfolders

### outputs/

Contains the final flagged datasets produced by the flagging pipeline.

- `df_flagged_post_peak.xlsx`
  - Flagged dataset generated from the post-peak bleaching severity model.

- `df_flagged_pre_peak.xlsx`
  - Flagged dataset generated from the pre-peak bleaching severity model.

These files are used downstream for summary statistics, visualization, and interpretation.

---

### R/

Contains reusable helper functions used throughout the flagging workflow.

#### `fix_types.R`

Utility function that standardizes column types before modeling.

Key operations include:

- Replacing blank strings with `NA`
- Converting `YEAR` to a factor
- Converting `SEVERITY_CODE` into an ordered factor
- Converting `spatial_cluster` to a factor
- Parsing date-time columns into POSIXct format

This ensures compatibility with the fitted `brms` models.

#### `pre_peak_flags_fn.R`

Core function for computing bleaching severity flags under **pre-peak** conditions.

Main features:

- Uses `posterior_epred()` from `brms`
- Generates per-row posterior class probabilities
- Computes predicted current and peak severity states
- Produces:
  - `mode_cur`
  - `median_cur`
  - `mode_max`
  - `median_max`
  - `flag1`–`flag4`
- Includes group-level effects (`re_formula = NULL`)


**`mode_cur`**

The most probable bleaching severity class for the observation under current thermal conditions.

This represents the posterior modal prediction for present-day severity.

**`median_cur`**

The posterior median bleaching severity class for current conditions.

This metric summarizes the central tendency of predicted current severity across posterior draws.

**`mode_max`**

The most probable predicted maximum bleaching severity class expected if thermal stress continues to increase toward peak conditions.

This metric is used to estimate likely future or peak bleaching severity.

**`median_max`**

The posterior median predicted maximum bleaching severity class.

This provides a more distributionally robust summary of expected peak severity.

**Flag Variables**

The workflow generates a set of logical flag variables (`flag1`–`flag4`) that identify observations where predicted bleaching severity differs meaningfully from observed or current predicted severity.

The flags are generally intended to identify:

- observations likely to worsen,
- potentially underestimated bleaching severity,

The function assumes four ordered severity classes:

1. None
2. Mild
3. Moderate
4. Severe

---

#### `post_peak_flags_fn.R`

Optimized flagging function for **post-peak** analyses.

Main features:

- Faster computation using cached predictions
- Population-level predictions only (`re_formula = NA`)
- Uses posterior draw probabilities from `posterior_epred()`
- Supports optional caching and rounding for repeated DHW maxima
- Produces the same derived metrics and flags as the pre-peak function:
  - `mode_cur`
  - `median_cur`
  - `mode_max`
  - `median_max`
  - `flag1`–`flag4`

Designed for computational efficiency during post-peak processing.

---

### scripts/

Contains executable scripts used to run the pre-peak and post-peak flagging workflows.


#### `run_flagging_pre_peak_model.R`

Main execution script for pre-peak flagging.

Workflow:

1. Loads required libraries
2. Imports the pre-screening dataset
3. Applies `fix_types()`
4. Loads the fitted pre-peak `brms` model
5. Computes flags using `pre_peak_flags_fn.R`
6. Writes the flagged dataset to `outputs/`


#### `run_flagging_post_peak_model.R`

Main execution script for post-peak flagging.

Workflow:

1. Loads required libraries
2. Imports the post-screening dataset
3. Applies `fix_types()`
4. Loads the fitted post-peak `brms` model
5. Computes flags using `post_peak_flags_fn.R`
6. Writes the flagged dataset to `outputs/`

---

### summaries_and_figures/

Contains all downstream analytical summaries, visualization scripts, and exported publication products.


#### summaries_and_figures/figures/

Stores exported figure files.


#### summaries_and_figures/scripts/

Contains plotting and summarization scripts.

##### post_peak/

Scripts related to post-peak flagged data.

`plot_current_vs_peak_predicted_severity.R`
Creates visual comparisons between current predicted severity and peak predicted severity.

`plot_flags_by_region_and_timing.R`
Generates regional and temporal summaries of flag occurrence.

Includes:

- Spatial grouping
- Timing comparisons
- Visualization of flagged proportions

`summarize_flag_proportions.R`

Produces summary tables describing:

- Overall flag prevalence
- Relative proportions of flagged observations
- Aggregated statistics for reporting

##### pre_peak/

Scripts related to pre-peak flagged data.

`plot_observed_vs_peak_predicted_severity.R`

Creates comparisons between observed bleaching severity and predicted peak severity.

`plot_flags_by_region_and_timing.R`

Generates regional and temporal summaries of pre-peak flags.

`summarize_flag_proportions.R`

Produces summary tables for pre-peak flag prevalence and distributions.

#### summaries_and_figures/tables/

Contains exported summary tables used for reporting and manuscript preparation.

- `post_peak_flag_summary_table.xlsx`
  - Summary statistics for post-peak flagging results.

- `pre_peak_flag_summary_table.xlsx`
  - Summary statistics for pre-peak flagging results.

- `pre_peak_occurrence_summary_by_region_year.xlsx`
  - Regional and yearly summaries of pre-peak flagged observations.


## Dependencies

The scripts in this folder primarily rely on the following R packages:

- `brms`
- `dplyr`
- `ggplot2`
- `grid`
- `here`
- `readxl`
- `scales`
- `viridis`
- `writexl`

---

## Typical Workflow

### 1. Generate Flagged Datasets

Run:

- `scripts/run_flagging_pre_peak_model.R`
- `scripts/run_flagging_post_peak_model.R`

Outputs are written to:

```text
03_flagging/outputs/
```

---

### 2. Generate Summaries and Figures

Run scripts in:

```text
03_flagging/summaries_and_figures/scripts/
```

Outputs are written to:

- `summaries_and_figures/figures/`
- `summaries_and_figures/tables/`

---

## Notes

- The workflow assumes fitted `brms` models already exist and are accessible through project-relative paths.
- File paths are managed using the `here` package.
- Pre-peak and post-peak analyses are intentionally separated to support different prediction assumptions and computational strategies.
- Exported figures correspond to manuscript-ready outputs.