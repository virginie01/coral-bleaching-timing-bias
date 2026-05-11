# ---- Packages ----
library(brms)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggtext)
library(here)
library(patchwork)
library(readxl)

# ---- loading required data and model outputs ----

# Load data
df_pre_screening <- read.csv(here("01_data_assembly","data","final","df_pre_screening.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_pre_screening <- fix_types(df_pre_screening)

fit <- readRDS(here("02_model_fitting","01_hpc","output","pre_peak_model","model_3.rds"))

# ---- Shared constants/helpers ----
severity_levels <- 0:3
severity_labels <- c("None", "Mild", "Moderate", "Severe")
severity_labels_rev <- rev(severity_labels)

level_map <- setNames(severity_labels, paste0("S", severity_levels))

severity_colors <- c(
  "None" = "grey85",
  "Mild" = "grey65",
  "Moderate" = "grey45",
  "Severe" = "grey20"
)

mk_thresholds <- function(main_df, col_name) {
  # Find DHW where the most-likely category changes
  main_df %>%
    mutate(prev = dplyr::lag(.data[[col_name]])) %>%
    filter(.data[[col_name]] != .data$prev) %>%
    pull(DHW)
}

mk_ticks_regular <- function(dhw_seq) {
  max_x <- max(dhw_seq, na.rm = TRUE)
  regular_ticks <- seq(0, ceiling(max_x / 5) * 5, by = 5)
  
  list(breaks = regular_ticks, labels = regular_ticks)
}

# A small common theme for both panels
theme_common <- theme_minimal() +
  theme(
    axis.text.x = ggtext::element_markdown(size = 10),
    legend.position = "right"
  )

# ---- Shared predictions (done once) ----
dhw_seq <- seq(0, max(df_pre_screening$MAX_ANNUAL_DHW, na.rm = TRUE), by = 0.1)
newdata <- data.frame(DHW = dhw_seq, spatial_cluster = NA, YEAR = NA)  # population-level only if LOCATION and YEAR are set to NA

# epred: draws x DHW x severity
epred <- posterior_epred(
  fit,
  newdata = newdata,
  re_formula = NA # exclude random effects - otherwise set to NULL
)

# ---- Panel a) MOST LIKELY CATEGORY ~ DHW (mode) ----

# mode per draw for each DHW (returns 0..3)
mode_per_draw <- apply(epred, c(1, 2), function(p) {
  severity_levels[which.max(p)]
})  # matrix: draws x DHW

# Probability that a given severity level is the mode at each DHW
mode_probs <- apply(mode_per_draw, 2, function(x) {
  tab <- table(factor(x, levels = severity_levels))
  prop.table(tab)
})  # severity x DHW

mode_df <- as.data.frame(t(mode_probs))
colnames(mode_df) <- paste0("S", severity_levels)
mode_df$DHW <- dhw_seq
mode_df$Mode <- severity_levels[apply(mode_probs, 2, which.max)] # gives the most probable mode at each DHW

mode_df_long <- mode_df %>%
  pivot_longer(starts_with("S"), names_to = "Severity", values_to = "Prob") %>%
  mutate(
    Severity = factor(
      recode(Severity, !!!level_map),
      levels = severity_labels_rev
    )
  )

mode_thresholds <- mk_thresholds(mode_df, "Mode")
mode_ticks <- mk_ticks_regular(dhw_seq)

threshold_labels_df <- data.frame(
  DHW = mode_thresholds,
  label = round(mode_thresholds, 1)
)

p_mode <- ggplot(mode_df_long, aes(x = DHW)) +
  geom_col(aes(y = Prob, fill = Severity), position = "stack", width = 0.1) +
  geom_step(
    data = mode_df,
    aes(x = DHW, y = Mode / 3),    # scale 0..3 to 0..1 primary axis
    color = "white",
    linewidth = 2.2
  ) +
  geom_step(
    data = mode_df,
    aes(x = DHW, y = Mode / 3),
    color = "black",
    linewidth = 1
  ) +
  geom_segment(
    data = data.frame(x = mode_thresholds),
    aes(x = x, xend = x, y = 1, yend = -0.05),
    linetype = "dashed",
    color = "grey40"
  ) +
  geom_text(
    data = threshold_labels_df,
    aes(x = DHW, y = -0.06, label = label),
    inherit.aes = FALSE,
    size = 2.5,
    color = "grey40",
    vjust = 1
  ) +
  scale_fill_manual(
    values = severity_colors,
    breaks = severity_labels_rev
  ) +
  scale_y_continuous(
    name = "Probability of being mode",
    sec.axis = sec_axis(~ . * 3, name = "Severity mode")
  ) +
  scale_x_continuous(
    name = "DHW",
    breaks = mode_ticks$breaks,
    labels = mode_ticks$labels
  ) +
  labs(fill = "Severity") +
  theme_common

# ---- Panel b) MEDIAN SEVERITY ~ DHW ----

# Ordinal median per draw for each DHW (returns 0..3)
ordinal_medians <- apply(epred, c(1, 2), function(p) {
  cum_probs <- cumsum(p)
  idx <- which(cum_probs >= 0.5)
  if (length(idx) == 0) NA_integer_ else severity_levels[idx[1]]
})  # draws x DHW

median_probs <- apply(ordinal_medians, 2, function(x) {
  tab <- table(factor(x, levels = severity_levels))
  prop.table(tab)
})  # severity x DHW

median_df <- as.data.frame(t(median_probs))
colnames(median_df) <- paste0("S", severity_levels)
median_df$DHW <- dhw_seq
median_df$Median <- severity_levels[apply(median_probs, 2, which.max)]

median_df_long <- median_df %>%
  pivot_longer(starts_with("S"), names_to = "Severity", values_to = "Prob") %>%
  mutate(
    Severity = factor(
      recode(Severity, !!!level_map),
      levels = severity_labels_rev
    )
  )

median_thresholds <- mk_thresholds(median_df, "Median")
median_ticks <- mk_ticks_regular(dhw_seq)

threshold_labels_df <- data.frame(
  DHW = median_thresholds,
  label = round(median_thresholds, 1)
)

p_median <- ggplot(median_df_long, aes(x = DHW)) +
  geom_col(aes(y = Prob, fill = Severity), position = "stack", width = 0.1) +
  geom_step(
    data = median_df,
    aes(x = DHW, y = Median / 3),  # rescale 0..3 to 0..1
    color = "white",
    linewidth = 2.2
  ) +
  geom_step(
    data = median_df,
    aes(x = DHW, y = Median / 3),
    color = "black",
    linewidth = 1
  ) +
  geom_segment(
    data = data.frame(x = median_thresholds),
    aes(x = x, xend = x, y = 1, yend = -0.05),
    linetype = "dashed",
    color = "grey40"
  ) +
  geom_text(
    data = threshold_labels_df,
    aes(x = DHW, y = -0.06, label = label),
    inherit.aes = FALSE,
    size = 2.5,
    color = "grey40",
    vjust = 1
  ) +
  scale_fill_manual(
    values = severity_colors,
    breaks = severity_labels_rev
  ) +
  scale_y_continuous(
    name = "Probability of being ordinal median",
    sec.axis = sec_axis(~ . * 3, name = "Median severity")
  ) +
  scale_x_continuous(
    name = "DHW",
    breaks = median_ticks$breaks,
    labels = median_ticks$labels
  ) +
  labs(fill = "Severity") +
  theme_common

# ---- Compose side-by-side with a single legend on the right ----
# Use guides='collect' to merge legends, and set legend.position at the layout level.
final_plot <- (p_mode / p_median) +
  plot_layout(guides = "collect", heights = c(1, 1)) +
  plot_annotation(tag_levels = "a", tag_suffix = ")") &
  theme(
    plot.tag = element_text(face = "bold"),
    legend.position = "right"
  )

print(final_plot)

ggsave(
  filename = "Figure_4.tiff",
  plot = final_plot,
  width = 180,    
  height = 210,  
  units = "mm",
  dpi = 300
)