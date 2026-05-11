# Required libraries
library(here)      # Project-relative file paths
library(readxl)    # Import .xlsx files
library(ggplot2)   # Plotting
library(scales)    # Percent labels
library(grDevices) # Color utilities and cairo_pdf

# ------------------------------------------------------------------------------
# Load flagged pre-peak dataset
# ------------------------------------------------------------------------------

df_flagged_pre_peak <- readxl::read_xlsx(
  here("03_flagging", "outputs", "df_flagged_pre_peak.xlsx")
)

#### STACKED PROPORTION BAR PLOT ###############################################
#### Compare observed severity with model-predicted maximum severity ############
###############################################################################

# Select observed and predicted severity columns
cols <- c("SEVERITY_CODE", "mode_max", "median_max")
tmp  <- df_flagged_pre_peak[, cols]
names(tmp) <- c("Observed", "Mode (MAX)", "Median (MAX)")

# Reshape from wide to long format for tabulation and plotting
st <- stack(tmp)
names(st) <- c("severity", "source")
st <- st[!is.na(st$severity), ]

# Ensure severity levels 0..3 exist and remain in the intended order
st$severity <- factor(st$severity, levels = 0:3, ordered = TRUE)
st$source   <- factor(st$source, levels = c("Observed", "Mode (MAX)", "Median (MAX)"))

# Compute column-wise proportions within each source
tab_counts <- xtabs(~ severity + source, data = st)   # 4 x 3
tab_prop   <- prop.table(tab_counts, 2)               # column-wise props

dfp <- as.data.frame(as.table(tab_prop))
names(dfp) <- c("severity", "source", "prop")

# Create percentage labels for non-zero proportions
dfp$label <- ifelse(dfp$prop > 0, scales::percent(dfp$prop, 1), "")

# Recode severity from numeric model labels to publication labels
dfp$severity <- factor(
  as.character(dfp$severity),
  levels = c("0", "1", "2", "3"),
  labels = c("None", "Mild", "Moderate", "Severe"),
  ordered = TRUE
)

# Grayscale palette for severity classes
severity_colors <- c(
  "None"     = "grey85",
  "Mild"     = "grey65",
  "Moderate" = "grey45",
  "Severe"   = "grey20"
)

# Choose black or white label text based on bar-segment brightness
rel_lum <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  f <- function(c) ifelse(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055)^2.4)
  v <- f(rgb)
  0.2126 * v[1, ] + 0.7152 * v[2, ] + 0.0722 * v[3, ]
}

lab_col_map <- ifelse(rel_lum(severity_colors) < 0.5, "white", "black")
names(lab_col_map) <- names(severity_colors)
dfp$lab_col <- unname(lab_col_map[as.character(dfp$severity)])

# Create stacked proportional bar plot
fig <- ggplot(dfp, aes(x = source, y = prop, fill = severity)) +
  geom_col(position = position_stack(reverse = TRUE), color = "white", width = 0.7) +
  geom_text(
    aes(label = ifelse(prop >= 0.03, label, ""), colour = lab_col),
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
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    limits = c(0, 1),
    expand = c(0, 0)
  ) +
  labs(x = NULL, y = "Proportion") +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank())

# Export figure
ggsave(
  filename = here(
    "03_flagging",
    "summaries_and_figures",
    "figures",
    "pre_peak",
    "Figure_6.pdf"
  ),
  plot = fig,
  device = cairo_pdf,     # embeds fonts nicely
  width = 180,            # mm
  height = 90,           # adjust as needed
  units = "mm",
  dpi = 600
)
