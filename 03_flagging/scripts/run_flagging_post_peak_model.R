# Required libraries
library(here)      # For project-relative file paths
library(writexl)   # For writing Excel files
library(brms)      # For posterior_epred() with the fitted brms model

# Load post-screening dataset
df_post_screening <- read.csv(here("01_data_assembly","data","final","df_post_screening.csv"))

# Load helper function to fix column types
source(here("03_flagging","R","fix_types.R"))

# Apply type fixes before modeling/flagging
df_post_screening <- fix_types(df_post_screening)

# Load fitted post-peak brms model
fit <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","model_4.rds"))

# Load function used to compute post-peak flags
source(here("03_flagging", "R", "post_peak_flags_fn.R"))

# Compute flags and return a new data frame with added flagging columns
df_flagged_post_peak <- compute_flags_postpeak_from_brms_fast(
  fit_post = fit,
  df_post  = df_post_screening,
  day_col  = "DAYS_FROM_MAX_DHW",
  max_col  = "MAX_ANNUAL_DHW",
  prob_thresh = 0.75,
  ndraws = 2000,
  max_round = 0.1,     # OPTIONAL: bins MAX to 0.1 DHW increments (often huge speedup)
  verbose = TRUE
)

# Write flagged output to Excel
write_xlsx(
  df_flagged_post_peak,
  here("03_flagging", "outputs", "df_flagged_post_peak.xlsx")
)