library(dplyr)
library(tibble)
library(ggplot2)
library(patchwork)
library(brms)
library(gtable)
library(grid)      # for unit()
library(tidyverse)
library(readxl)
library(tidyr)
library(ggtext)
library(purrr)
library(viridis)
library(bayesplot)
library(ggnewscale)

# ---- loading required data and model outputs ----

# Load data
df_post <- read.csv(here("02_model_fitting", "01_hpc", "data", "df_post.csv"))
source(here("02_model_fitting","01_hpc","utility functions","fix_types.R"))
df_post <- fix_types(df_post)

fit <- readRDS(here("02_model_fitting","01_hpc","output","post_peak_model","model_4.rds"))

# ==== Controls you can tweak quickly ==== 
LEGEND_X_NUDGE <- 0.50
LEGEND_Y_NUDGE <- 0.50

ROW_WIDTHS <- c(1, 0.32)

TAG_STYLE <- theme(
  plot.tag = element_text(size = 12, face = "bold"),
  plot.tag.position = c(0.05, 0.98)
)

severity_levels <- c("None", "Mild", "Moderate", "Severe")

severity_colors <- c(
  "None" = "grey85",
  "Mild" = "grey65",
  "Moderate" = "grey45",
  "Severe" = "grey20"
)

get_legend_grob <- function(p) {
  g <- ggplotGrob(p)
  idx <- which(sapply(g$grobs, function(x) x$name) == "guide-box")
  if (length(idx) == 0) return(NULL)
  g$grobs[[idx[1]]]
}

nudge_legend <- function(leg, x_nudge = 0.5, y_nudge = 0.5) {
  patchwork::wrap_elements(
    full = grobTree(
      leg,
      vp = viewport(
        x = unit(x_nudge, "npc"),
        y = unit(y_nudge, "npc")
      )
    )
  )
}

base_theme <- theme_minimal(base_size = 11) +
  theme(
    plot.margin = margin(5.5, 12, 5.5, 5.5),
    aspect.ratio = 0.9,
    legend.key.height = unit(16, "pt"),
    legend.key.width  = unit(16, "pt"),
    legend.text = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    legend.background = element_rect(fill = "white", colour = "grey80"),
    legend.box.margin = margin(8, 8, 8, 8)
  )

# ===================== MODE (top row, panel a) =====================
max_dhw_seq <- seq(0, max(df_post$MAX_ANNUAL_DHW), by = 1)
days_seq <- seq(0, max(df_post$DAYS_FROM_MAX_DHW), by = 7)

grid_mode <- expand.grid(
  MAX_ANNUAL_DHW = max_dhw_seq,
  DAYS_FROM_MAX_DHW = days_seq
)

epred_mode <- posterior_epred(
  fit,
  newdata = grid_mode,
  re_formula = NA,
  ndraws = 12000
)

mode_per_draw <- apply(epred_mode, c(1, 2), which.max)

mode_summary <- apply(mode_per_draw, 2, function(x) {
  tbl <- table(factor(x, levels = 1:4))
  prop <- prop.table(tbl)
  as.data.frame(as.list(setNames(prop, severity_levels)))
})

mode_df_stats <- bind_rows(mode_summary)

Mode_num  <- apply(mode_df_stats, 1, which.max)
Mode_prob <- apply(mode_df_stats, 1, max)

mode_df <- bind_cols(
  grid_mode,
  mode_df_stats,
  tibble(
    Mode = factor(severity_levels[Mode_num], levels = severity_levels),
    Prob_Mode = Mode_prob
  )
)

x_breaks <- seq(1, max(mode_df$MAX_ANNUAL_DHW), by = 1)

p_mode_full <- ggplot(mode_df, aes(MAX_ANNUAL_DHW, DAYS_FROM_MAX_DHW)) +
  geom_tile(aes(fill = Mode, alpha = Prob_Mode)) +
  scale_fill_manual(
    name = "Severity",
    values = severity_colors,
    breaks = rev(severity_levels),                 # reverse legend order
    guide = guide_legend(reverse = FALSE)         # breaks already control order
  ) +
  scale_alpha_continuous(range = c(0.25, 1), guide = "none") +
  scale_x_continuous(
    limits = c(0.5, NA),
    breaks = x_breaks,
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    title = NULL,
    x = expression(italic(DHWmax)),
    y = expression(italic(tlag)),
    tag = "a)"
  ) +
  base_theme + TAG_STYLE +
  theme(legend.position = "right")

leg_mode <- nudge_legend(
  get_legend_grob(p_mode_full),
  LEGEND_X_NUDGE, LEGEND_Y_NUDGE
)

top_row <- (p_mode_full + theme(legend.position = "none")) +
  leg_mode +
  plot_layout(ncol = 2, widths = ROW_WIDTHS)

# ===================== MEDIAN (bottom row, panel b) =====================

epred_med <- posterior_epred(
  fit,
  newdata = grid_mode,
  re_formula = NA,
  ndraws = 12000
)

cum_probs <- apply(epred_med, c(1, 2), cumsum)
cum_probs <- aperm(cum_probs, c(2, 3, 1))

ordinal_medians <- apply(cum_probs, c(1, 2), function(p) {
  idx <- which(p >= 0.5)
  if (length(idx) == 0) NA else idx[1] - 1
})

median_summary <- apply(ordinal_medians, 2, function(x) {
  tbl <- table(factor(x, levels = 0:3))
  prop <- prop.table(tbl)
  as.data.frame(as.list(setNames(prop, severity_levels)))
})

median_df_stats <- bind_rows(median_summary)

Median_num  <- apply(median_df_stats, 1, which.max) - 1
Median_prob <- apply(median_df_stats, 1, max)

median_df <- bind_cols(
  grid_mode,
  median_df_stats,
  tibble(
    Median = factor(severity_levels[Median_num + 1], levels = severity_levels),
    Prob_Median = Median_prob
  )
)

p_median_full <- ggplot(median_df, aes(MAX_ANNUAL_DHW, DAYS_FROM_MAX_DHW)) +
  geom_tile(aes(fill = Median, alpha = Prob_Median)) +
  scale_fill_manual(
    name = "Severity",
    values = severity_colors,
    breaks = rev(severity_levels),                 # reverse legend order
    guide = guide_legend(reverse = FALSE)
  ) +
  scale_alpha_continuous(range = c(0.25, 1), guide = "none") +
  scale_x_continuous(
    limits = c(0.5, NA),
    breaks = x_breaks,
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    title = NULL,
    x = expression(italic(DHWmax)),
    y = expression(italic(tlag)),
    tag = "b)"
  ) +
  base_theme + TAG_STYLE +
  theme(legend.position = "right")

leg_med <- nudge_legend(
  get_legend_grob(p_median_full),
  LEGEND_X_NUDGE, LEGEND_Y_NUDGE
)

bottom_row <- (p_median_full + theme(legend.position = "none")) +
  leg_med +
  plot_layout(ncol = 2, widths = ROW_WIDTHS)

# ===================== FINAL FIGURE =====================
final_figure <- top_row / bottom_row +
  plot_layout(heights = c(1, 1))

final_figure

ggsave(
  filename = "Figure_7.tiff",
  plot = final_figure,
  device = "tiff",
  width = 180 / 25.4,   # mm → inches
  height = 240 / 25.4,  # adjust if needed
  units = "in",
  dpi = 300,
  compression = "lzw"
)

