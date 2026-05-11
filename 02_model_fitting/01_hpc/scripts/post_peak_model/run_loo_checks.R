#!/usr/bin/env Rscript

# -------------------------------
# run_loo_checks.R
# Virginie Bornarel – Sockeye version
# -------------------------------

library(brms)
library(loo)
library(dplyr)
library(future)

# ---- 1. Parse input argument ----
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("No model ID provided. Usage: Rscript run_loo_checks.R <model_id>")
}
model_id <- as.integer(args[1])
cat("Processing LOO for model ID:", model_id, "\n")

# ---- 2. Locate and load model ----
model_path <- file.path("output/post_peak_model", paste0("model_", model_id, ".rds"))
if (!file.exists(model_path)) stop("Model file not found: ", model_path)
cat("Loading model:", model_path, "\n")
fit <- readRDS(model_path)

# ---- 3. Compute LOO ----

cat("Applying moment_match = TRUE and reloo = TRUE if needed...\n")

n_cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1"))
cat("Using cores:", n_cores, "\n")

options(future.globals.maxSize = 5120 * 1024^2) # Setting in bytes for maximum compatibility
options(mc.cores = n_cores) 
plan(multicore, workers = n_cores)

loo_result <- loo(fit, reloo = TRUE, moment_match = TRUE, reloo_args = list(cores = n_cores))

# ---- 7. Save results ----
out_file <- file.path("output/post_peak_model", paste0("loo_model_", model_id, ".rds"))
saveRDS(loo_result, out_file)
cat("Saved LOO results to:", out_file, "\n")
cat("Done.\n")
