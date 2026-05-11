library(brms)
library(loo)
library(dplyr)
library(here)
library(patchwork)
library(ggplot2)

############################### MODEL DIAGNOSTICS ##############################

# ---- 1. Compare predictive accuracy across candidate models ----
# Load previously computed PSIS-LOO objects for the four pre-peak candidate models.
# loo_compare() ranks models by expected log predictive density (ELPD).
# The best predictive model should have the highest ELPD, shown at the top.

loo_1 <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","loo_model_1.rds"))
loo_2 <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","loo_model_2.rds"))
loo_3 <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","loo_model_3.rds"))
loo_4 <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","loo_model_4.rds"))

loo_compare(list(model1 = loo_1, model2 = loo_2, model3 = loo_3, model4 = loo_4))


# ---- 2. Load training data and selected fitted model ----
# Reload the training dataset and apply the same type-cleaning function used
# during model fitting. Then load the selected model for detailed diagnostics.

df_pre <- read.csv(here("02_model_fitting","01_hpc","data","df_pre.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_pre <- fix_types(df_pre)

fit <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","model_3.rds"))

# ---- 3. Check MCMC convergence and posterior sampling diagnostics ----
# summary(fit) reports R-hat, effective sample sizes, and parameter summaries.
# plot(fit) shows trace plots and posterior densities for visual convergence checks.

summary(fit)
plot(fit)

# ---- 4. Posterior predictive check: overall outcome distribution ----
# For ordinal severity outcomes, bar PPCs compare observed category frequencies
# against replicated datasets simulated from the fitted model.

pp_check(fit, type = "bars")  # For ordinal outcomes

# ---- 5. Posterior predictive check stratified by DHW exposure bin ----
# This checks whether the model reproduces the severity distribution across
# different DHW ranges, not just overall.

df_pre$DHW_bin <- cut(df_pre$DHW, breaks = c(0,2,4,6,8,10, Inf), include.lowest = TRUE)

bins <- levels(df_pre$DHW_bin)
p_list <- lapply(bins, function(b) {
  d <- subset(df_pre, DHW_bin == b)
  yrep <- posterior_predict(fit, newdata = d, re_formula = NA, ndraws = 400)
  bayesplot::ppc_bars(y = as.integer(d$SEVERITY_CODE), yrep = yrep) + ggtitle(paste("DHW:", b))
})
wrap_plots(p_list) + plot_annotation(title = "PPC by DHW bin (bars = observed, points = yrep)")

# ---- 6. Posterior predictive check stratified by major locations ----
# This checks whether the model reproduces severity patterns at the most
# frequently sampled locations.

topN <- 9
loc_top <- names(sort(table(df_pre$LOCATION), decreasing = TRUE))[1:topN]

p_loc <- lapply(loc_top, function(g) {
  d <- subset(df_pre, LOCATION == g)
  yrep <- posterior_predict(fit, newdata = d, re_formula = NA, ndraws = 400)
  bayesplot::ppc_bars(y = as.integer(d$SEVERITY_CODE), yrep = yrep) + ggtitle(g)
})

wrap_plots(p_loc) + plot_annotation(title = "PPC by LOCATION (top sites)")

# ---- 7. Load LOO results for selected model ----
# Useful for inspecting the selected model's predictive accuracy and Pareto-k diagnostics.

loo_3

# ---- 8. Check fitted smooth for overfitting or boundary wiggles ----
# conditional_smooths() visualizes the estimated smooth effect of DHW.
# Use this to look for unrealistic wiggliness, especially near boundaries.

cs <- conditional_smooths(fit)
plot(cs)