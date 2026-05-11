# Required libraries
library(here)      # Project-relative file paths
library(readxl)    # Import .xlsx files
library(ggplot2)   # Plotting
library(scales)    # Percent labels
library(grDevices) # Color utilities and cairo_pdf

# ------------------------------------------------------------------------------
# Load flagged post-peak dataset
# ------------------------------------------------------------------------------

df_flagged_post_peak <- readxl::read_xlsx(
  here("03_flagging", "outputs", "df_flagged_post_peak.xlsx")
)

# ------------------------------------------------------------------------------
# Create stacked proportion bar plot comparing predicted severity at survey time
# with model-predicted severity at peak heat stress
# ------------------------------------------------------------------------------

# Grayscale palette for severity classes
severity_colors <- c(
  "None"     = "grey85",
  "Mild"     = "grey65",
  "Moderate" = "grey45",
  "Severe"   = "grey20"
)

# Correct predicted peak severity so it is not lower than current severity
idx <- !is.na(df_flagged_post_peak$mode_cur) & 
  !is.na(df_flagged_post_peak$mode_max) & 
  df_flagged_post_peak$mode_cur > df_flagged_post_peak$mode_max

df_flagged_post_peak$mode_max[idx] <- df_flagged_post_peak$mode_cur[idx]

idx <- !is.na(df_flagged_post_peak$median_cur) & 
  !is.na(df_flagged_post_peak$median_max) & 
  df_flagged_post_peak$median_cur > df_flagged_post_peak$median_max

df_flagged_post_peak$median_max[idx] <- df_flagged_post_peak$median_cur[idx]

# Select current and peak severity columns
cols <- c("mode_cur", "mode_max", "median_cur", "median_max")
tmp  <- df_flagged_post_peak[, cols]
names(tmp) <- c("Mode (CUR)", "Mode (MAX)", "Median (CUR)", "Median (MAX)")

# Convert severity columns to long format
st <- stack(tmp)
names(st) <- c("severity", "source")
st <- st[!is.na(st$severity), ]

# Keep severity order and relabel legend entries
st$severity <- factor(
  st$severity,
  levels = 0:3,
  labels = c("None", "Mild", "Moderate", "Severe"),
  ordered = TRUE
)

# Keep source groups in desired plotting order
st$source <- factor(
  st$source,
  levels = c("Mode (CUR)", "Mode (MAX)", "Median (CUR)", "Median (MAX)")
)

# Calculate proportional severity distribution within each source
tab_counts <- xtabs(~ severity + source, data = st)
tab_prop   <- prop.table(tab_counts, 2)

dfp <- as.data.frame(as.table(tab_prop))
names(dfp) <- c("severity", "source", "prop")
dfp$label <- ifelse(dfp$prop > 0, percent(dfp$prop, 1), "")

# Ensure factor levels stay in desired order
dfp$severity <- factor(
  as.character(dfp$severity),
  levels = c("None", "Mild", "Moderate", "Severe"),
  ordered = TRUE
)

# Calculate relative luminance to choose contrasting text color
rel_lum <- function(col) {
  rgb <- col2rgb(col) / 255
  f <- function(x) ifelse(x <= 0.03928, x / 12.92, ((x + 0.055) / 1.055)^2.4)
  v <- f(rgb)
  0.2126 * v[1, ] + 0.7152 * v[2, ] + 0.0722 * v[3, ]
}

# Text color chosen for contrast against fill
lab_col_map <- ifelse(rel_lum(severity_colors) < 0.5, "white", "black")
names(lab_col_map) <- names(severity_colors)
dfp$lab_col <- unname(lab_col_map[as.character(dfp$severity)])

# Custom x positions with a gap between Mode and Median groups
pos_map <- c(
  "Mode (CUR)"   = 1,
  "Mode (MAX)"   = 2,
  "Median (CUR)" = 4,
  "Median (MAX)" = 5
)
dfp$x <- unname(pos_map[as.character(dfp$source)])

# Create stacked proportional bar plot
fig <- ggplot(dfp, aes(x = x, y = prop, fill = severity)) +
  geom_col(
    position = position_stack(reverse = TRUE),
    color = "white",
    width = 0.75
  ) +
  geom_text(
    aes(
      label = ifelse(prop >= 0.03, label, ""),
      colour = lab_col
    ),
    position = position_stack(vjust = 0.5, reverse = TRUE),
    size = 3.5,
    show.legend = FALSE
  ) +
  scale_fill_manual(
    values = severity_colors,
    name = "Severity",
    drop = FALSE,
    guide = guide_legend(reverse = TRUE)
  ) +
  scale_color_identity() +
  scale_x_continuous(
    breaks = unname(pos_map),
    labels = names(pos_map),
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  labs(x = NULL, y = "Proportion") +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank())

# Save figure
ggsave(
  filename = here(
    "03_flagging",
    "summaries_and_figures",
    "figures",
    "post_peak",
    "Figure_9.pdf"
  ),
  plot = fig,
  device = cairo_pdf,     # embeds fonts nicely
  width = 180,            # mm
  height = 90,           # adjust as needed
  units = "mm",
  dpi = 600
)

