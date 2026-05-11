#!/usr/bin/env Rscript

# -------------------------------
# run_loo_checks.R
# Virginie Bornarel – Sockeye version
# -------------------------------

library(brms)
library(loo)
library(dplyr)
library(future)

# ---- 2. Locate and load model ----
model_path <- "output/post_peak_model/single_model.rds"
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

# ---- 6. Save results ----
out_file <- "output/post_peak_model/loo_single_model.rds"
saveRDS(loo_result, out_file)
cat("Saved LOO results to:", out_file, "\n")
cat("Done.\n")
