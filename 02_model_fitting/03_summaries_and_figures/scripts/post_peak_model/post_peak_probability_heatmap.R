# Required libraries
library(here)
library(brms)
library(dplyr)
library(tibble)
library(ggplot2)
library(viridis)
 
##################### FACETED 2D HEATMAPS ######################################
########## P(SEVERITY LEVEL = x) ~ f(MAX_ANNUAL_DHW, DAYS_FROM_MAX_DHW) ########

# Load post-peak dataset and apply project-specific type formatting

df_post <- read.csv(here("02_model_fitting","01_hpc","data","df_post.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_post <- fix_types(df_post)

# Load fitted post-peak Bayesian model

fit <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","model_4.rds"))

# Create prediction sequences across the observed ranges of maximum annual DHW
# and days from maximum DHW

max_dhw_seq <- seq(min(df_post$MAX_ANNUAL_DHW), max(df_post$MAX_ANNUAL_DHW), length.out = 50)
days_seq <- seq(min(df_post$DAYS_FROM_MAX_DHW), max(df_post$DAYS_FROM_MAX_DHW), length.out = 50)

# Optional values for cluster/year-specific predictions.
# These are only used if group-level effects are included in posterior_epred()
# by setting re_formula = NULL

cluster_val <- "French Polynesia"
year_val    <- "2016" 

# Prediction grid for group-level effects.
# Includes spatial_cluster and YEAR so predictions can be made for one
# cluster-year combination

grid <- expand.grid(
  MAX_ANNUAL_DHW    = max_dhw_seq,
  DAYS_FROM_MAX_DHW = days_seq
) %>%
  mutate(
    spatial_cluster = cluster_val,
    YEAR = year_val
  )

# Prediction grid for population-level effects only.
# This version excludes grouping variables and is used with re_formula = NA

grid <- expand.grid(
  MAX_ANNUAL_DHW = max_dhw_seq,
  DAYS_FROM_MAX_DHW = days_seq
)

# Generate posterior predicted probabilities for each grid cell and severity level.
# Use re_formula = NA for population-level effects only.
# Use re_formula = NULL to include group-level/random effects

epred <- posterior_epred(
  fit,
  newdata = grid,
  #re_formula = NULL # if group-level effects
  re_formula = NA #if population-level effect only
) # Shape: [draws, grid cells, severity levels]

# Summarize posterior predictions into mean probabilities and 95% credible bounds

mean_probs <- apply(epred, c(2, 3), mean)
lower_probs <- apply(epred, c(2, 3), quantile, probs = 0.025)
upper_probs <- apply(epred, c(2, 3), quantile, probs = 0.975)

# Convert prediction arrays into a tidy plotting data frame.
# Each row represents one severity level, statistic type, and grid-cell location

plot_df <- bind_rows(
  tibble(
    MAX_ANNUAL_DHW = rep(grid$MAX_ANNUAL_DHW, times = 4),
    DAYS_FROM_MAX_DHW = rep(grid$DAYS_FROM_MAX_DHW, times = 4),
    Severity = rep(c("None", "Mild", "Moderate", "Severe"), each = nrow(grid)),
    Value = as.vector(mean_probs),
    Statistic = "Mean"
  ),
  tibble(
    MAX_ANNUAL_DHW = rep(grid$MAX_ANNUAL_DHW, times = 4),
    DAYS_FROM_MAX_DHW = rep(grid$DAYS_FROM_MAX_DHW, times = 4),
    Severity = rep(c("None", "Mild", "Moderate", "Severe"), each = nrow(grid)),
    Value = as.vector(lower_probs),
    Statistic = "Lower Bound"
  ),
  tibble(
    MAX_ANNUAL_DHW = rep(grid$MAX_ANNUAL_DHW, times = 4),
    DAYS_FROM_MAX_DHW = rep(grid$DAYS_FROM_MAX_DHW, times = 4),
    Severity = rep(c("None", "Mild", "Moderate", "Severe"), each = nrow(grid)),
    Value = as.vector(upper_probs),
    Statistic = "Upper Bound"
  )
)

# Ensure severity panels appear in the intended order

plot_df$Severity <- factor(
  plot_df$Severity,
  levels = c("None", "Mild", "Moderate", "Severe")
)

# Plot predicted probability surfaces.
# Rows show bleaching severity categories; columns show posterior summaries

ggplot(plot_df, aes(x = MAX_ANNUAL_DHW, y = DAYS_FROM_MAX_DHW, fill = Value)) +
  geom_tile() +
  facet_grid(Severity ~ Statistic) +
  scale_fill_viridis_c(name = "Probability", limits = c(0, 1)) +
  labs(
    x = expression(italic("DHWmax")),
    y = expression(italic("tlag"))
    #title = "Predicted probability surface: mean & credible bounds"
  ) +
  theme_minimal()

# Save final figure as a high-resolution TIFF

ggsave(
  filename = "Figure_3.tiff",
  plot = last_plot(),   # or assign your plot to an object and use that
  device = "tiff",
  width = 180,
  height = 120,         # adjust as needed for your aspect ratio
  units = "mm",
  dpi = 300,
  compression = "lzw"   # optional but recommended for TIFF
)
