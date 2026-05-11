#!/usr/bin/env Rscript

# -------------------------------
# run_one_brms_model.R
# Fit a single brms model on Sockeye
# -------------------------------

library(brms)
library(rstan)
library(dplyr)
library(readxl)
library(mgcv)
library(stringr)

cat("=== Starting single BRMS model ===\n")

# ---- Load full dataset ----

data <- read.csv("data/df_post.csv")

source("utility functions/fix_types.R")
data <- fix_types(data)

# ---- Define model ----
formula_single <- bf(
  (SEVERITY_CODE ~ t2(MAX_ANNUAL_DHW, DAYS_FROM_MAX_DHW, k = c(8, 8)) + (1 + MAX_ANNUAL_DHW | spatial_cluster) + (1 | spatial_cluster:YEAR))
)

# ---- Fit model ----
cat("=== Fitting model ===\n")
options(mc.cores = 4)

ctrl <- list(
  adapt_delta   = 0.999,
  max_treedepth = 15
)

fit <- tryCatch({
  brm(
    formula = formula_single,
    data = data,
    family = cumulative("logit"),
    chains = 4,
    cores = 4,
    iter = 6000,
    warmup = 2000,
    control = ctrl,
    save_pars = save_pars(all = TRUE),
    seed = 1234,
    backend = "rstan",
    verbose = TRUE,
    refresh = 200
  )
}, error = function(e) {
  message("Model fitting failed: ", e$message)
  NULL
})

# ---- Save output ----
out_dir <- "output/post_peak_model"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

if (!is.null(fit)) {
  save_path <- file.path(out_dir, "single_model.rds")
  saveRDS(fit, save_path)
  cat("Saved model to:", save_path, "\n")
} else {
  cat("Model did not finish; no file saved.\n")
}

cat("=== Done ===\n")