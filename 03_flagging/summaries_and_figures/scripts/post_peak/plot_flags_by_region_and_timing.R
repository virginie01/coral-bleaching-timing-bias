# Required libraries
library(here)
library(readxl)
library(dplyr)
library(ggplot2)
library(viridis)
library(grid)

# Import flagged post-peak dataset
df_flagged_post_peak <- read_xlsx(
  here("03_flagging", "outputs", "df_flagged_post_peak.xlsx")
)

# Recreate standalone flag vectors
any_flagged <- with(
  df_flagged_post_peak,
  flag1 | flag2 | flag3 | flag4
)

all_flagged <- with(
  df_flagged_post_peak,
  flag1 & flag2 & flag3 & flag4
)

#### PLOT PROPORTION FLAGGED + FLAGGED REPORTS #################################
#### BY REGION AND DAYS_FROM_MAX_DHW BIN       #################################

## At least 1 flag

# Create 10-day bins from 0 to the maximum DAYS_FROM_MAX_DHW value
max_val <- floor(max(df_flagged_post_peak$DAYS_FROM_MAX_DHW, na.rm = TRUE))
breaks <- seq(0, max_val, by = 10)
if (tail(breaks, 1) < max_val) {
  breaks <- c(breaks, max_val)
}

DAYS_BIN <- cut(
  df_flagged_post_peak$DAYS_FROM_MAX_DHW,
  breaks = breaks,
  include.lowest = TRUE,
  right = FALSE  # left-closed, right-open intervals
)

# Build temporary plotting dataset for reports flagged by at least one flag
temp_df <- data.frame(
  REGION    = df_flagged_post_peak$OCEAN_REGION,
  DAYS_BIN  = DAYS_BIN,
  any_flagged = any_flagged
) %>%
  mutate(
    REGION = recode(
      REGION,
      "Pacific Ocean"    = "Pacific Ocean",
      "NA Pacific Ocean" = "Pacific Ocean"
    )
  )

n_reports <- aggregate(any_flagged ~ REGION + DAYS_BIN, data = temp_df, FUN = length)
n_flagged <- aggregate(any_flagged ~ REGION + DAYS_BIN, data = temp_df, FUN = sum)

summary_df <- merge(n_reports, n_flagged, by = c("REGION", "DAYS_BIN"), suffixes = c("_total", "_flagged"))

names(summary_df)[names(summary_df) == "any_flagged_total"] <- "n_reports"
names(summary_df)[names(summary_df) == "any_flagged_flagged"] <- "n_flagged"

summary_df <- summary_df %>%
  mutate(prop_flagged = n_flagged/n_reports)

p <- ggplot(summary_df, aes(x = DAYS_BIN, y = n_reports, fill = prop_flagged)) +
  geom_col(color = "black", linewidth = 0.2) +
  facet_wrap(~ REGION, ncol = 1) +
  scale_fill_viridis_c(
    name = "Proportion\nflagged",
    limits = c(0, 1)
  ) +
  labs(
    x = expression(italic(tlag) ~ "(binned)"),
    y = "Number of reports"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold")
  )

p <- p +
  theme(
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    
    axis.text.x  = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y  = element_text(size = 11),
    
    strip.text   = element_text(size = 13, face = "bold"),  # ocean region titles
    
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 11),
    
    legend.key.height = unit(1.2, "cm"),
    
    plot.margin = margin(t = 1, r = 1, b = 3, l = 1, unit = "cm")
  )

ggsave(
  here("03_flagging", "summaries_and_figures", "figures", "pre_peak", "figure_8.tiff"),
  plot = p,
  device = "tiff",
  width = 180,
  height = 240,
  units = "mm",
  dpi = 300,
  compression = "lzw"
)


## all 4 flags

# Build temporary plotting dataset for reports flagged by all four flags
temp_df <- data.frame(
  REGION    = df_flagged_post_peak$OCEAN_REGION,
  DAYS_BIN  = DAYS_BIN,
  all_flagged = all_flagged
) %>%
  mutate(
    REGION = recode(
      REGION,
      "Pacific Ocean"    = "Pacific Ocean",
      "NA Pacific Ocean" = "Pacific Ocean"
    )
  )

n_reports <- aggregate(all_flagged ~ REGION + DAYS_BIN, data = temp_df, FUN = length)
n_flagged <- aggregate(all_flagged ~ REGION + DAYS_BIN, data = temp_df, FUN = sum)

summary_df <- merge(n_reports, n_flagged, by = c("REGION", "DAYS_BIN"), suffixes = c("_total", "_flagged"))

names(summary_df)[names(summary_df) == "all_flagged_total"] <- "n_reports"
names(summary_df)[names(summary_df) == "all_flagged_flagged"] <- "n_flagged"

summary_df <- summary_df %>%
  mutate(prop_flagged = n_flagged/n_reports)

p <- ggplot(summary_df, aes(x = DAYS_BIN, y = n_reports, fill = prop_flagged)) +
  geom_col(color = "black", linewidth = 0.2) +
  facet_wrap(~ REGION, ncol = 1) +
  scale_fill_viridis_c(
    name = "Proportion\nflagged",
    limits = c(0, 1)
  ) +
  labs(
    x = "DAYS_FROM_MAX_DHW (binned)",
    y = "Number of reports"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(face = "bold")
  )

p <- p +
  theme(
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    
    axis.text.x  = element_text(size = 11, angle = 45, hjust = 1),
    axis.text.y  = element_text(size = 11),
    
    strip.text   = element_text(size = 13, face = "bold"),  # ocean region titles
    
    legend.title = element_text(size = 12),
    legend.text  = element_text(size = 11),
    
    legend.key.height = unit(1.2, "cm"),
    
    plot.margin = margin(t = 1, r = 1, b = 3, l = 1, unit = "cm")
  )
