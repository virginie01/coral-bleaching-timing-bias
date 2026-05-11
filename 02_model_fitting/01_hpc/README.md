# Hierarchical Bayesian Coral Bleaching Models (HPC Workflow)

## Overview

This repository contains scripts and submission workflows for fitting hierarchical Bayesian models of coral bleaching severity using `brms` in R on a High Performance Computing (HPC) system.

The project is organized into two modelling pipelines:

- **Pre-peak models** — modelling bleaching severity as a function of Degree Heating Weeks (DHW)
- **Post-peak models** — modelling bleaching severity as a function of thermal stress recovery metrics

The workflow is designed for batch execution on an HPC cluster using array jobs and includes:

- model fitting scripts
- Leave-One-Out (LOO) cross-validation scripts
- job submission scripts
- preprocessed datasets
- utility functions for data preparation

This subdirectory contains only the HPC model-fitting workflow.

---

## Scientific Context

These models evaluate coral bleaching severity using hierarchical cumulative logistic regression models implemented with `brms`.

The response variable is:

- `SEVERITY_CODE`

The modelling framework includes:

- smooth terms using `mgcv`
- hierarchical random effects
- spatial clustering structure
- temporal grouping by year
- Bayesian ordinal regression

---

## Pre-Peak Models

The pre-peak workflow models bleaching severity prior to peak thermal stress.

### Predictors

Primary predictor:

- `DHW` (Degree Heating Weeks)

### Candidate Models

The workflow evaluates increasingly complex hierarchical structures in the following order:

1. random intercept by spatial cluster
2. random intercept and slope for DHW by spatial cluster
3. additional random intercept by spatial cluster-year 
4. additional random intercept and slope for DHW by spatial cluster-year

### Input Dataset

```r
/data/df_pre.csv
```

### Main Script

```r
scripts/pre_peak_model/run_brms_model.R
```

---

## Post-Peak Models

The post-peak workflow models bleaching severity after maximum thermal stress conditions.

### Predictors

Primary predictors:

- `MAX_ANNUAL_DHW`
- `DAYS_FROM_MAX_DHW`

Tensor-product smooths (`t2`) are used to model nonlinear interactions.

### Candidate Models

The workflow evaluates increasingly complex hierarchical structures in the following order:

1. random intercept by spatial cluster
2. random intercept and slope for `MAX_ANNUAL_DHW` by spatial cluster
3. two random intercepts by spatial cluster and spatial cluster-year 
4. Configuration 2. and random intercept by spatial cluster-year

### Input Dataset

```r
/data/df_post.csv
```

### Main Script

```r
scripts/post_peak_model/run_brms_model.R
```

---

## Model Specification

Models are fit using:

```r
family = cumulative("logit")
```

with:

- 4 chains
- 6000 iterations
- 2000 warmup iterations
- `adapt_delta = 0.999`
- `max_treedepth = 15`

The backend used is:

```r
backend = "rstan"
```

---

## HPC Submission Workflow

This repository was developed for the Sockeye High Performance Computing (HPC) cluster at the University of British Columbia (UBC), which uses the SLURM scheduler.

The shell submission scripts included in this repository were configured specifically for the computational requirements of the fitted Bayesian hierarchical models.

These scripts define:

- memory requirements
- runtime limits
- CPU allocations
- SLURM array-job settings
- output and error log handling

Users adapting this workflow to another HPC environment should review and modify the SLURM resource specifications according to their local cluster configuration.

### Submission Scripts

#### Pre-peak models

```bash
sbatch submit/pre_peak_model/submit_brms_array.sh
```

#### Post-peak models

```bash
sbatch submit/post_peak_model/submit_brms_array.sh
```

#### LOO validation jobs

```bash
sbatch submit/pre_peak_model/submit_loo_array.sh
sbatch submit/post_peak_model/submit_loo_array.sh
```

The SLURM array indices correspond to candidate model specifications defined within the R scripts.

---

## Selected Models and Model Comparison

Multiple candidate hierarchical models were evaluated for both the pre-peak and post-peak analyses.

Model comparison and selection procedures are described in the associated manuscript currently under submission.

The selected models used in the final implementation are:

| Workflow | Selected Model |
|---|---|
| Pre-peak model | `model_3.rds` |
| Post-peak model | `model_4.rds` |

The candidate model set is considered fixed for the current implementation, and future analyses are expected to reuse these selected model structures rather than expand the comparison framework.

---

## Output Files

Model outputs are written automatically to:

```text
output/pre_peak_model/
output/post_peak_model/
```

Typical outputs include:

- fitted model `.rds` objects
- LOO validation objects
- diagnostic summaries

These outputs are excluded from this repository due to size constraints. These are archived separately with the paper release, on Zenodo.

Diagnostic scripts, figures, and manuscript-ready analyses are maintained elsewhere in the root repository. This HPC folder is limited to fitting models and generating output objects used by downstream workflows.

---

## Dependencies

### R Packages

Required packages include:

```r
brms
rstan
dplyr
readxl
mgcv
stringr
loo
```

### Suggested Installation

```r
install.packages(c(
  "brms",
  "rstan",
  "dplyr",
  "readxl",
  "mgcv",
  "stringr",
  "loo"
))
```

---


# Running a Model Manually

Example:

```bash
Rscript scripts/pre_peak_model/run_brms_model.R 1
```

where the numeric argument corresponds to a predefined model formula.

---

# Reproducibility Notes

- All models use a fixed random seed (`1234`)
- Parallel processing is enabled using:

```r
options(mc.cores = 4)
```

- Data preprocessing is centralized in:

```r
utility functions/fix_types.R
```

---

# Author

Virginie Bornarel

---

# Citation

If using or adapting this workflow, please cite the associated manuscript or project documentation.