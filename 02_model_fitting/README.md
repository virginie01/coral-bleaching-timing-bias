# 02_model_fitting

This directory contains the full workflow for Bayesian model fitting, diagnostics, and figure generation for both the **pre-peak** and **post-peak** analyses.

The project is organized into three major components:

1. `01_hpc/` — scripts and submission files for high-performance computing (HPC) model fitting.
2. `02_diagnostics/` — model comparison and diagnostic workflows.
3. `03_summaries_and_figures/` — scripts and exported figures used for interpretation and reporting.

---

## 1. HPC Model Fitting (`01_hpc/`)

The `01_hpc/` directory contains all files required to fit Bayesian models using `brms` on an HPC cluster.

### Data

#### `01_hpc/data/`

| File | Description |
|---|---|
| `df_pre.csv` | Input dataset for pre-peak model fitting. |
| `df_post.csv` | Input dataset for post-peak model fitting. |

---

### Model Scripts

#### `01_hpc/scripts/pre_peak_model/`

| Script | Purpose |
|---|---|
| `run_brms_model.R` | Fits the full pre-peak Bayesian model. |
| `run_one_brms_model.R` | Runs a single model instance for testing/debugging. |
| `run_loo_checks.R` | Performs leave-one-out (LOO) diagnostics for model evaluation. |
| `run_one_loo_checks.R` | Runs LOO diagnostics for a single model instance. |

#### `01_hpc/scripts/post_peak_model/`

| Script | Purpose |
|---|---|
| `run_brms_model.R` | Fits the full post-peak Bayesian model. |
| `run_one_brms_model.R` | Runs a single model instance for testing/debugging. |
| `run_loo_checks.R` | Performs leave-one-out (LOO) diagnostics for model evaluation. |
| `run_one_loo_checks.R` | Runs LOO diagnostics for a single model instance. |

---

### HPC Submission Scripts

#### `01_hpc/submit/pre_peak_model/`

| Script | Purpose |
|---|---|
| `submit_brms_array.sh` | Submits array jobs for pre-peak model fitting. |
| `submit_one_brms.sh` | Submits a single pre-peak model job. |
| `submit_loo_array.sh` | Submits array jobs for LOO diagnostics. |
| `submit_one_loo.sh` | Submits a single LOO diagnostic job. |

#### `01_hpc/submit/post_peak_model/`

| Script | Purpose |
|---|---|
| `submit_brms_array.sh` | Submits array jobs for post-peak model fitting. |
| `submit_one_brms.sh` | Submits a single post-peak model job. |
| `submit_loo_array.sh` | Submits array jobs for LOO diagnostics. |
| `submit_one_loo.sh` | Submits a single LOO diagnostic job. |

---

### Utility Functions

#### `01_hpc/utility functions/`

| File | Description |
|---|---|
| `fix_types.R` | Helper function for correcting or standardizing variable types prior to modeling. |

---

## 2. Diagnostics (`02_diagnostics/`)

This directory contains scripts used to compare model structures and evaluate model quality.

| Script | Purpose |
|---|---|
| `comparison_diagnostic_pre_peak_model.R` | Diagnostic comparisons for pre-peak models. |
| `comparison_diagnostic_post_peak_model.R` | Diagnostic comparisons for post-peak models. |
| `README.md` | Additional documentation for diagnostic workflows. |

These scripts are typically used after model fitting and LOO evaluation are complete.

---

## 3. Summaries and Figures (`03_summaries_and_figures/`)

This directory contains scripts for generating publication-ready summaries and figures from fitted model outputs.

### Figure and Summary Scripts

#### `03_summaries_and_figures/scripts/pre_peak_model/`

| Script | Purpose |
|---|---|
| `plot_conditional_effects.R` | Generates conditional effects plots. |
| `plot_mode_median_outputs.R` | Creates mode and median output summaries. |
| `plot_random_effects.R` | Visualizes model random effects. |

#### `03_summaries_and_figures/scripts/post_peak_model/`

| Script | Purpose |
|---|---|
| `plot_mode_median_outputs.R` | Creates mode and median output summaries. |
| `plot_random_effects.R` | Visualizes model random effects. |
| `post_peak_probability_heatmap.R` | Generates post-peak probability heatmaps. |

---

## Typical Workflow

The analysis pipeline is organized into three sequential stages:

```text
01_hpc/  →  02_diagnostics/  →  03_summaries_and_figures/
```

Each directory contains a dedicated `README.md` with detailed instructions and execution examples. The overview below summarizes the role of each stage in the workflow.

---

### 1. `01_hpc/`

This directory contains all scripts required for large-scale Bayesian model fitting on the HPC cluster.

#### High-level workflow

1. Load and prepare the pre-peak and post-peak datasets.
2. Run Bayesian model fitting using `brms`.
3. Submit parallel jobs through SLURM submission scripts.
4. Run leave-one-out (LOO) validation and model checks.
5. Save fitted model objects and diagnostic outputs.

Separate workflows are maintained for:

- `pre_peak_model/`
- `post_peak_model/`

Detailed HPC execution instructions, submission examples, and model workflow descriptions are provided in:

```text
01_hpc/README.md
```

---

### 2. `02_diagnostics/`

This directory contains scripts used to evaluate model performance and compare fitted model structures.

#### High-level workflow

1. Load fitted model outputs from the HPC stage.
2. Run comparison and diagnostic scripts.
3. Evaluate LOO metrics and model fit quality.
4. Identify preferred models for interpretation and visualization.

Additional diagnostic details are documented in:

```text
02_diagnostics/README.md
```

---

### 3. `03_summaries_and_figures/`

This directory generates summary outputs and publication-ready visualizations from finalized model results.

#### High-level workflow

1. Load finalized fitted models.
2. Generate conditional effects and random-effects summaries.
3. Create manuscript-quality figures and heatmaps.
4. Export TIFF figures for reporting and publication.

Additional figure-generation details are documented in:

```text
03_summaries_and_figures/README.md
```

---

## Software Requirements

The workflow is implemented primarily in **R** and depends on packages commonly used for Bayesian hierarchical modeling and visualization.

Likely required packages include:

- `brms`
- `rstan`
- `loo`
- `tidyverse`
- `ggplot2`
- `posterior`
- `bayesplot`

HPC submission scripts assume access to a SLURM-compatible cluster environment.

---

## Notes

- Separate workflows are maintained for pre-peak and post-peak analyses to simplify model management.
- Array submission scripts are intended for large-scale parallel model execution.
- TIFF figures are stored as publication-quality outputs.
- Additional documentation is available in subdirectory-specific `README.md` files.