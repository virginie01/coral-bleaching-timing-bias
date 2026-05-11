#!/usr/bin/env Rscript

# -------------------------------
# run_brms_model.R
# Virginie Bornarel – Sockeye version
# -------------------------------

library(brms)
library(rstan)
library(dplyr)
library(readxl)
library(mgcv)      # for smoother syntax checking
library(stringr)

# ---- 1. Parse input arguments ----
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("No model ID provided. Usage: Rscript run_brms_model.R <1–4>")
}
task_id <- as.integer(args[1])

cat("Running model ID:", task_id, "\n")

# ---- 2. Load data and prepare data ----

data <- read.csv("data/df_pre.csv")

source("utility functions/fix_types.R")
data <- fix_types(data)

# ---- 3. Define model formulas ----
formulas <- list(
  bf(SEVERITY_CODE ~ s(DHW, k = 6) + (1 | spatial_cluster)),
  bf(SEVERITY_CODE ~ s(DHW, k = 6) + (1 + DHW | spatial_cluster)),
  bf(SEVERITY_CODE ~ s(DHW, k = 6) + (1 + DHW | spatial_cluster) + (1 | spatial_cluster:YEAR)),
  bf(SEVERITY_CODE ~ s(DHW, k = 6) + (1 + DHW | spatial_cluster) + (1 + DHW | spatial_cluster:YEAR))
)
  # ---- 4. Map task_id to formula ----
  formula_id <- task_id
  
  formula <- formulas[[formula_id]]
  
  cat("Selected formula index:", formula_id, "\n")
  
  # ---- 5. Model fitting parameters ----
  options(mc.cores = 4)
  
  fit <- tryCatch({
    brm(
      formula = formula,
      data = data,
      family = cumulative("logit"),
      chains = 4,
      cores = 4,
      iter = 6000,
      warmup = 2000,
      control = list(
        adapt_delta   = 0.999,
        max_treedepth = 15
      ),
      save_pars = save_pars(all = TRUE),
      seed = 1234,
      verbose = TRUE,
      refresh = 200,
      backend = "rstan"
    )
  }, error = function(e) {
    message("Model fitting failed for model ", task_id, ": ", e$message)
    NULL
  })
  
  # ---- 6. Save results ----
  out_dir <- "output/pre_peak_model"
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  if (!is.null(fit)) {
    saveRDS(fit, file.path(out_dir, paste0("model_", task_id, ".rds")))
    cat("Model", task_id, "saved to", file.path(out_dir, paste0("model_", task_id, ".rds")), "\n")
  } else {
    cat("Model", task_id, "failed and was not saved.\n")
  }
  
  cat("Job complete for model ID:", task_id, "\n")
