# 01_data_assembly

## Overview

This stage assembles the analytical datasets used throughout the project.

Starting from the global coral bleaching database, the workflow:

- filters reports with exact survey dates,
- extracts Degree Heating Week (DHW) values at the survey date,
- extracts peak DHW values within a 6-month window after each survey,
- computes timing-related variables,
- generates final datasets used for model fitting and bleaching-report screening.

## Workflow

Raw bleaching database
        ↓
01_filter_exact_dates.ipynb
        ↓
df_exact
        ↓
02_extract_dhw.ipynb
        ↓
df_exact_dhw.xlsx
        ↓
03_extract_max_dhw.ipynb
        ↓
df_exact_with_dhw_and_max.xlsx
        ↓
04_exploratory_analysis.ipynb
        ↓
05_create_model_datasets.ipynb
        ↓
df_pre.csv
df_pre_screening.csv
df_post.csv
df_post_screening.csv

## Notebooks


### 01_filter_exact_dates.ipynb
Filters the bleaching database to retain only reports with exact survey dates (day, month, year).

---

### 02_extract_dhw_at_survey.ipynb
Extracts NOAA Coral Reef Watch DHW values at the survey date for each bleaching report.

Output:
- df_exact_dhw.xlsx

---

### 03_extract_peak_dhw_within_6mo.ipynb
Extracts the maximum DHW reached within +/- 6 months of each bleaching report and computes timing offsets relative to the survey date.

Output:
- df_exact_with_dhw_and_max.xlsx

---

### 04_explore_expanded_database.ipynb
Performs exploratory analysis and validation checks on the expanded bleaching database.

---

### 05_prepare_data_for_models.ipynb
Creates the final datasets used for:
- pre-peak model training,
- post-peak model training,
- pre-peak screening,
- post-peak screening.

Outputs:
- df_pre.csv
- df_pre_screening.csv
- df_post.csv
- df_post_screening.csv

## Data structure

### raw/
Original bleaching database.

Files:
- Bleaching Database V2 - Urcelay and Donner.xlsx

### intermediate/
Intermediate datasets generated during the assembly process.

Files:
- df_exact_dhw.xlsx
- df_exact_with_dhw_and_max.xlsx

### final/
Final datasets used in downstream modeling and screening stages.

Files:
- df_pre.csv
- df_pre_screening.csv
- df_post.csv
- df_post_screening.csv