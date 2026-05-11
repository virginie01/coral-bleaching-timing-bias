library(brms)
library(loo)
library(dplyr)
library(here)
library(ggplot2)
library(bayesplot)
library(patchwork)

############################### MODEL DIAGNOSTICS ##############################

# ---- 1. Compare predictive accuracy across candidate models ----
# Load previously computed PSIS-LOO objects for the four post-peak candidate models.
# loo_compare() ranks models by expected log predictive density (ELPD).
# The best predictive model should have the highest ELPD, shown at the top.

loo_1 <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","loo_model_1.rds"))
loo_2 <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","loo_model_2.rds"))
loo_3 <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","loo_model_3_fast.rds"))
loo_4 <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","loo_model_4_fast.rds"))

loo_compare(list(model1 = loo_1, model2 = loo_2, model3 = loo_3, model4 = loo_4))

# ---- 2. Load training data and selected fitted model ----
# Reload the training dataset and apply the same type-cleaning function used
# during model fitting. Then load the selected model for detailed diagnostics.

df_post <- read.csv(here("02_model_fitting","01_hpc","data","df_post.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_post <- fix_types(df_post)

fit <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","model_4.rds"))

# ---- 3. Check MCMC convergence and posterior sampling diagnostics ----
# summary(fit) reports R-hat, effective sample sizes, and parameter summaries.
# plot(fit) shows trace plots and posterior densities for visual convergence checks.

summary(fit)
plot(fit)

# ---- 4. Posterior predictive check: overall outcome distribution ----
# For ordinal severity outcomes, bar PPCs compare observed category frequencies
# against replicated datasets simulated from the fitted model.

pp_check(fit, type = "bars")  # For ordinal outcomes

# ---- 5. Posterior predictive check stratified by DHW_MAX & DAYS_FROM_MAX_DHW bin ----
# This checks whether the model reproduces the severity distribution across
# different DHW_MAX & DAYS_FROM_MAX_DHW ranges, not just overall.

max_breaks <- c(0, 4, 8, Inf)
lag_breaks <- c(0, 30, 60, 90, Inf)

min_n   <- 40
ndraws  <- 400
n_cols  <- 3   # try 2 if you want larger panels

df_binned <- df_post %>%
  mutate(
    MAX_bin = cut(MAX_ANNUAL_DHW, breaks = max_breaks, include.lowest = TRUE),
    LAG_bin = cut(DAYS_FROM_MAX_DHW, breaks = lag_breaks, include.lowest = TRUE)
  ) %>%
  filter(!is.na(MAX_bin), !is.na(LAG_bin), !is.na(SEVERITY_CODE))

cells <- df_binned %>%
  count(MAX_bin, LAG_bin, name = "n") %>%
  filter(n >= min_n) %>%
  arrange(MAX_bin, LAG_bin)

ppc_theme <- theme_bw(base_size = 11) +
  theme(
    plot.title = element_text(size = 9, face = "bold"),
    axis.title = element_text(size = 8),
    axis.text  = element_text(size = 7),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position = "none"   # REMOVE legend in each subplot
  )

make_ppc_plot <- function(d, mb, lb) {
  
  yrep <- posterior_predict(
    fit,
    newdata    = d,
    re_formula = NA,
    ndraws     = ndraws
  )
  
  bayesplot::ppc_bars(
    y    = as.integer(d$SEVERITY_CODE),
    yrep = yrep
  ) +
    labs(
      title = paste0("DHW ", mb, " | Lag ", lb),
      x = NULL,
      y = NULL
    ) +
    annotate(
      "text",
      x = Inf,
      y = Inf,
      label = paste0("n = ", nrow(d)),
      hjust = 1.1,    # slight inward shift
      vjust = 1.2,
      size = 3
    ) +
    theme_bw(base_size = 11) +
    theme(
      plot.title = element_text(size = 9, face = "bold"),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank()
    )
}

plots <- lapply(seq_len(nrow(cells)), function(i) {
  mb <- cells$MAX_bin[i]
  lb <- cells$LAG_bin[i]
  d  <- df_binned %>% filter(MAX_bin == mb, LAG_bin == lb)
  make_ppc_plot(d, mb, lb)
})

legend_plot <- {
  d <- df_binned %>% slice(1:200)
  yrep <- posterior_predict(fit, newdata = d, re_formula = NA, ndraws = ndraws)
  
  bayesplot::ppc_bars(
    y    = as.integer(d$SEVERITY_CODE),
    yrep = yrep
  ) +
    theme(legend.position = "right")
}

ppc_plot <- wrap_plots(plots, ncol = n_cols) +
  plot_layout(guides = "collect") &
  theme(legend.position = "right")

ppc_plot

ggsave(
  filename = "PPC_post_peak_portrait.png",
  plot     = ppc_plot,
  width    = 6.5,
  height   = 8.5,
  units    = "in",
  dpi      = 600
)

# ---- 6. Load LOO results for selected model ----
# Useful for inspecting the selected model's predictive accuracy and Pareto-k diagnostics.
loo_4 

