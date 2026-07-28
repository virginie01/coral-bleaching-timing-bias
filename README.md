# Coral Bleaching Timing Bias

## Overview

This project investigates survey timing bias in global coral bleaching observations.

Bleaching surveys conducted too early during marine heat stress events may underestimate peak bleaching severity because thermal stress has not yet peaked. Conversely, surveys conducted long after peak heat stress may underestimate bleaching severity due to coral recovery or mortality dynamics.

This repository develops a workflow to:

1. assemble an expanded bleaching database with thermal stress metrics,
2. fit Bayesian ordinal bleaching severity models,
3. identify potentially underestimated bleaching reports,
4. generate screening flags for timing-related bias,
5. quantify the prevalence and spatial distribution of potentially biased bleaching observations.

The project combines:
- NOAA Coral Reef Watch Degree Heating Week (DHW) data,
- global coral bleaching observations,
- Bayesian ordinal regression models (`brms`),
- spatio-temporal random effects,
- screening and flagging algorithms for bleaching-report evaluation.

---

# Repository Structure

```text
.
├── 01_data_assembly/
├── 02_model_fitting/
├── 03_flagging/
├── manuscript and communication/
├── environment.yml
└── renv.lock
```

---

# Workflow Overview

```text
Raw bleaching database
        ↓
01_filter_exact_dates.ipynb
        ↓
02_extract_dhw_at_survey.ipynb
        ↓
df_exact_dhw.xlsx
        ↓
03_extract_peak_dhw_within_6mo.ipynb
        ↓
df_exact_with_dhw_and_max.xlsx
        ↓
05_prepare_data_for_models.ipynb
        ↓
Pre-peak datasets
Post-peak datasets
        ↓
Bayesian ordinal models (brms)
        ↓
Flagging workflow
        ↓
Summary statistics and figures
```

---

# 01_data_assembly

This stage assembles the analytical datasets used throughout the project.

Key tasks:
- filter bleaching reports with exact survey dates,
- extract DHW values at survey time,
- extract peak DHW values within a 6-month window,
- compute survey timing relative to peak heat stress,
- generate datasets used for model fitting and screening.

## Main outputs

### Intermediate datasets
- `df_exact_dhw.xlsx`
- `df_exact_with_dhw_and_max.xlsx`

### Final datasets
- `df_pre.csv`
- `df_pre_screening.csv`
- `df_post.csv`
- `df_post_screening.csv`

See:
- `01_data_assembly/README.md`

---

# 02_model_fitting

This stage fits and validates Bayesian ordinal bleaching severity models using `brms`.

Two model classes are considered:
- pre-peak bleaching models,
- post-peak bleaching models.

The workflow includes:
- HPC execution on Sockeye (UBC),
- model fitting,
- Leave-One-Out Cross Validation (LOO-CV),
- model diagnostics,
- conditional effects,
- random effects visualization,
- severity prediction summaries.

## Structure

### `01_hpc/`
Contains:
- HPC submission scripts,
- brms model scripts,
- LOO-CV scripts,
- utility functions.

### `02_diagnostics/`
Contains model comparison and validation diagnostics.

### `03_summaries_and_figures/`
Contains scripts and figures for:
- conditional effects,
- random effects,
- predicted severity summaries,
- probability heatmaps.

See:
- `02_model_fitting/README.md`

---

# 03_flagging

This stage applies the validated models to identify bleaching reports potentially affected by timing-related underestimation bias.

The workflow:
1. imports validated models,
2. computes predicted bleaching severity,
3. applies rule-based screening criteria,
4. flags potentially underestimated bleaching reports,
5. summarizes spatial and temporal patterns of flagged reports.

Separate workflows are implemented for:
- pre-peak screening,
- post-peak screening.

## Main outputs

### Flagged datasets
- `df_flagged_pre_peak.xlsx`
- `df_flagged_post_peak.xlsx`

### Summary products
- regional summaries,
- timing summaries,
- predicted severity distributions,
- manuscript figures and tables.

See:
- `03_flagging/README.md`

---

# Computational Environment

## Python

The data assembly workflow uses Python/Jupyter notebooks.

Environment:
- `environment.yml`

## R

Model fitting, diagnostics, and flagging workflows use R.

Dependency management:
- `renv.lock`

---

# Key Methods

## Environmental Predictors
- Degree Heating Weeks (DHW)
- Maximum annual DHW
- Timing relative to peak DHW

## Statistical Modeling
- Bayesian ordinal regression (`brms`)
- Spatio-temporal random intercepts and slopes
- Leave-One-Out Cross Validation (LOO-CV)

## Flagging Framework
Bleaching reports are screened using:
- model predictions,
- survey timing,
- predicted peak severity,
- multiple rule-based flagging criteria.

---

# Citation

If you use this repository or any part of its workflow in academic research, please cite the archived software release corresponding to the version used in your work.

**Current archived release**

Bornarel, V. (2026). *coral-bleaching-timing-bias: Version 1.0.0 — Initial reproducible workflow release* (Version 1.0.0). Zenodo. https://doi.org/10.5281/zenodo.20116631

This repository accompanies a manuscript currently under peer review at *PLOS ONE*. Once the manuscript is published, please cite both:

- the published journal article; and
- the specific software release used in your analyses.

If you use only a particular dataset or a future standalone data release, please cite the corresponding dataset DOI instead.

---

# Collaboration

I welcome discussions and potential collaborations involving methodological developments, substantial extensions of this workflow, or integration with new large-scale datasets.

If this repository plays a central role in a planned research project or forms the basis for substantial methodological developments, I would be pleased to discuss opportunities for collaboration.

Please note that use of this repository under the MIT License does not imply scientific endorsement of derived work. Users remain responsible for validating and interpreting their own analyses.

---

# Repository status

This repository accompanies a manuscript currently under peer review at *PLOS ONE*.

The archived Version 1.0.0 release represents the complete computational workflow used for the submitted manuscript and serves as the reference version for reproducibility.

Development of this repository will continue during peer review. Future releases may include improvements to documentation, bug fixes, additional functionality, and revisions arising from the review process while preserving the archived reference release.

# Author

Developed by:
Virginie C. Bornarel

Affiliation:
Department of Geography, University of British Columbia, Vancouver, BC, Canada