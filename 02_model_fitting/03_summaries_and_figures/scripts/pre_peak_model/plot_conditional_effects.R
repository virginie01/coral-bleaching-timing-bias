# Required libraries
library(here)
library(brms)
library(dplyr)
library(ggplot2)
library(tibble)
library(tidyr)
library(ggnewscale)
library(ggtext)

# Load fitted model and pre-peak dataset

fit <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","model_3.rds"))

df_pre <- read.csv(here("02_model_fitting","01_hpc","data","df_pre.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_pre <- fix_types(df_pre)

# Estimate conditional effects of DHW on bleaching severity
# First line estimates population-level effects only.
# Second line estimates effects for a specific spatial cluster and year,
# including group-level/random effects.

cond_eff <- conditional_effects(fit, effects = "DHW", categorical = TRUE, resolution = 250) #population-level effect only
cond_eff <- conditional_effects(fit, effects = "DHW", conditions = data.frame(spatial_cluster = "Malaysia", YEAR = 2014), re_formula = NULL, categorical = TRUE, resolution = 250) # includes random effects too

# Convert conditional effects output into a data frame and ensure
# bleaching severity categories are ordered consistently.

cond_df <- cond_eff[[1]] %>%
  mutate(
    cats__ = factor(cats__, levels = c("None", "Mild", "Moderate", "Severe"))
  )

# Identify the most likely bleaching severity category at each DHW value.
# Convert ordered categories to numeric values so transitions between
# dominant categories can be detected.

mode_df <- cond_df %>%
  group_by(DHW) %>%
  slice_max(order_by = estimate__, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    Mode = factor(cats__, levels = c("None", "Mild", "Moderate", "Severe")),
    Mode_num = case_when(
      Mode == "None"     ~ 0,
      Mode == "Mild"     ~ 1,
      Mode == "Moderate" ~ 2,
      Mode == "Severe"   ~ 3
    ),
    prev = lag(Mode_num)
  )

# Extract DHW thresholds where the most likely severity category changes.

thresholds <- mode_df %>%
  filter(Mode_num != prev) %>%
  pull(DHW)

# Define regular x-axis tick marks.

regular_ticks <- c(0, 5, 10, 15, 20, 25)

# Create a data frame for threshold tick labels.
# Threshold labels are shown on a lower line beneath the regular ticks.

th_df <- tibble(
  x     = thresholds,
  lab_x = thresholds,
  lab   = sprintf("%.1f", thresholds)
)

# Slightly shift the first two threshold labels if they overlap.

if (nrow(th_df) >= 2) {
  th_df$lab_x[1] <- th_df$lab_x[1] - 0.3
  th_df$lab_x[2] <- th_df$lab_x[2] + 0.3
}

# Combine regular tick marks and threshold labels for the final x-axis.

x_breaks <- c(regular_ticks, th_df$lab_x)
x_labels <- c(
  paste0("<b>", regular_ticks, "</b><br>"),
  paste0(
    "<br><span style='font-size:8pt; color:#444444;'>",
    th_df$lab,
    "</span>"
  )
)

# Build a DHW density strip showing how much observed data supports
# each portion of the DHW range.

d_hw_breaks <- seq(
  floor(min(cond_df$DHW)),
  ceiling(max(cond_df$DHW)),
  by = 0.5
)

d_hw_density <- df_pre %>%
  mutate(DHW_bin = cut(DHW, breaks = d_hw_breaks, include.lowest = TRUE)) %>%
  count(DHW_bin, name = "n_bin") %>%
  tidyr::complete(DHW_bin, fill = list(n_bin = 0)) %>%
  mutate(
    DHW  = (d_hw_breaks[-1] + d_hw_breaks[-length(d_hw_breaks)]) / 2,
    freq = n_bin / sum(n_bin)
  )

# Rescale density values for plotting.
# The highest-density bin is excluded from the scaling range so that
# one extreme peak does not compress variation among the other bins.

idx_max <- which.max(d_hw_density$freq)

logf <- log1p(d_hw_density$freq)
logf_peakless <- logf[-idx_max]
rng <- range(logf_peakless)

d_hw_density <- d_hw_density %>%
  mutate(
    freq_vis_raw = (log1p(freq) - rng[1]) / (rng[2] - rng[1]),
    freq_vis     = pmin(freq_vis_raw, 1)
  )

# Plot predicted bleaching severity probabilities across DHW.
# The plot includes:
# - regular DHW grid lines,
# - a density strip showing observed DHW data coverage,
# - predicted category probabilities,
# - uncertainty ribbons,
# - dashed threshold lines where the modal severity category changes.

p <- ggplot() +
  
  # vertical grid lines only at the regular x ticks
  geom_vline(
    xintercept = regular_ticks,
    color = "grey85",
    linewidth = 0.4
  ) +
  
  geom_tile(
    data = d_hw_density,
    aes(x = DHW, y = -0.02, fill = freq_vis),
    height = 0.02
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    name = "Relative data density"
  ) +
  ggnewscale::new_scale_fill() +
  geom_line(
    data = cond_df,
    aes(x = DHW, y = estimate__, color = cats__),
    linewidth = 0.8
  ) +
  geom_ribbon(
    data = cond_df,
    aes(x = DHW, ymin = lower__, ymax = upper__, fill = cats__),
    alpha = 0.2,
    color = NA
  ) +
  geom_vline(
    xintercept = thresholds,
    linetype = "dashed",
    color = "grey40",
    linewidth = 0.4
  ) +
  scale_y_continuous(
    name = "Probability",
    limits = c(-0.05, 1)
  ) +
  scale_x_continuous(
    name = "DHW",
    breaks = x_breaks,
    labels = x_labels
  ) +
  scale_fill_brewer(
    palette = "Set2",
    name = "Severity"
  ) +
  scale_color_brewer(
    palette = "Set2",
    name = "Severity"
  ) +
  guides(
    fill = guide_legend(reverse = TRUE),
    color = guide_legend(reverse = TRUE)
  ) +
  theme_minimal() +
  theme(
    axis.text.x = ggtext::element_markdown(size = 9, margin = margin(t = 8)),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.minor.y = element_blank(),
    legend.position = "right"
  )

p

# Save the final figure as a high-resolution TIFF.

ggsave(
  "Figure_2.tiff",
  width = 180,
  height = 100,   # adjust based on your layout
  units = "mm",
  dpi = 300,
  compression = "lzw"
)
