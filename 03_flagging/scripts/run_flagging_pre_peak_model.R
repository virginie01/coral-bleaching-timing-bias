# Required libraries
library(here)      # For project-relative file paths
library(writexl)   # For writing Excel files
library(brms)      # For posterior_epred() with the fitted brms model

# Load pre-screening dataset
df_pre_screening <- read.csv(here("01_data_assembly","data","final","df_pre_screening.csv"))

# Load helper function to fix column types
source(here("03_flagging","R","fix_types.R"))

# Apply type fixes before modeling/flagging
df_pre_screening <- fix_types(df_pre_screening)

# Load fitted pre-peak brms model
fit <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","model_3.rds"))

# Load function used to compute pre-peak flags
source(here("03_flagging", "R", "pre_peak_flags_fn.R"))

# Compute flags and return a new data frame with added flagging columns
df_flagged_pre_peak <- compute_flags_from_brms(fit_pre = fit,
                                  df_pre = df_pre_screening,
                                  dhw_col = "DHW",
                                  max_col = "MAX_ANNUAL_DHW",
                                  # re_cols: columns needed so the model can apply the right random effects.
                                  # e.g., c("YEAR", "spatial_cluster") — adjust to match model's grouping vars.
                                  re_cols = c("spatial_cluster", "YEAR"))



# Write flagged output to Excel
write_xlsx(
  df_flagged_pre_peak,
  here("03_flagging", "outputs", "df_flagged_pre_peak.xlsx")
)