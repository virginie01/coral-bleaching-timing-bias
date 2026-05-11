# Summaries and Figures for Hierarchical Bayesian Coral Bleaching Models

## Overview

This directory contains scripts and figure outputs used to summarize, visualize, and interpret the hierarchical Bayesian coral bleaching models fitted through the HPC workflow.

The scripts generate:

- posterior predictive visualizations
- conditional effects plots
- random effects summaries
- probability heatmaps
- manuscript-ready figures

This directory operates downstream of both:

1. the HPC model-fitting workflow
2. the diagnostics and model-comparison workflows

It assumes that fitted model objects and processed outputs already exist.

---

## Scientific Context

The visualizations summarize cumulative ordinal Bayesian models implemented with `brms` for coral bleaching severity analyses.

The workflows support both:

- pre-peak bleaching models
- post-peak bleaching models

The figures are intended to:

- interpret model predictions
- visualize nonlinear effects
- summarize hierarchical random effects
- illustrate posterior uncertainty
- support manuscript preparation and scientific communication

---

## Pre-Peak Model Visualizations

Scripts for pre-peak models are located in:

```text
scripts/pre_peak_model/
```

### Included Scripts

#### Conditional effects plot

```r
plot_conditional_effects.R
```

Generates conditional effects visualizations for the selected pre-peak model, illustrating the relationship between bleaching severity and thermal stress predictors.

#### Mode and Median Summaries

```r
plot_mode_median_outputs.R
```

Produces summary visualizations of posterior predictions using mode- and median-based summaries.

#### Random Effects Visualization

```r
plot_random_effects.R
```

Visualizes hierarchical random effects and spatial variation included in the selected model structure.

---

## Post-Peak Model Visualizations

Scripts for post-peak models are located in:

```text
scripts/post_peak_model/
```

### Included Scripts

#### Mode and Median Summaries

```r
plot_mode_median_outputs.R
```

Generates posterior summary visualizations for post-peak model outputs.

#### Random Effects Visualization

```r
plot_random_effects.R
```

Visualizes hierarchical random effects and variation structures included in the post-peak model.

#### Probability Heatmaps

```r
post_peak_probability_heatmap.R
```

Generates probability heatmaps illustrating predicted bleaching severity responses across combinations of post-peak thermal stress predictors.

These visualizations are particularly useful for interpreting nonlinear interaction surfaces and temporal recovery dynamics.

---

## Selected Models

The visualizations are based on the selected models identified through the model comparison workflow:

| Workflow | Selected Model |
|---|---|
| Pre-peak model | `model_3.rds` |
| Post-peak model | `model_4.rds` |

Model comparison and selection procedures are described in the associated manuscript currently under submission.

---

## Figure Outputs

Generated figure outputs are stored in:

```text
figures/pre_peak_model/
figures/post_peak_model/
```

Example manuscript figures currently included:

### Pre-Peak Figures

- `Figure_2.tiff`
- `Figure_4.tiff`

### Post-Peak Figures

- `Figure_3.tiff`
- `Figure_7.tiff`

These figures are intended for manuscript preparation, supplementary material, and scientific communication.

---

## Dependency on Other Workflows

This directory depends on outputs generated elsewhere in the repository, including:

- fitted model `.rds` objects
- processed datasets
- diagnostics outputs
- posterior prediction objects

The scripts assume that repository-relative file paths remain unchanged.

---

## Dependencies

### Required R Packages

```r
brms
ggplot2
patchwork
dplyr
tidybayes
here
```

### Suggested Installation

```r
install.packages(c(
  "brms",
  "ggplot2",
  "patchwork",
  "dplyr",
  "tidybayes",
  "here"
))
```

---


# Author

Virginie Bornarel

---

# Citation

If using or adapting this workflow, please cite the associated manuscript or project documentation.