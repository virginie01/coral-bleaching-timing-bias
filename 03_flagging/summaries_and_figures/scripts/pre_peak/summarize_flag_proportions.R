# Required libraries
library(here)
library(readxl)
library(writexl)
library(dplyr)

# ------------------------------------------------------------------------------
# Load flagged pre-peak dataset
# ------------------------------------------------------------------------------

df_flagged_pre_peak <- readxl::read_xlsx(
  here("03_flagging", "outputs", "df_flagged_pre_peak.xlsx")
)

# ------------------------------------------------------------------------------
# Overall flag summaries
# ------------------------------------------------------------------------------

any_flagged <- with(
  df_flagged_pre_peak,
  flag1 | flag2 | flag3 | flag4
)

all_flagged <- with(
  df_flagged_pre_peak,
  flag1 & flag2 & flag3 & flag4
)

prop_any_flag <- mean(any_flagged, na.rm = TRUE)
prop_all_flag <- mean(all_flagged, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Major underestimation flags
# ------------------------------------------------------------------------------

mode_major_flag <- with(
  df_flagged_pre_peak,
  (mode_cur == 0 & mode_max %in% c(2, 3)) |
    (mode_cur == 1 & mode_max %in% c(2, 3)) |
    (mode_cur == 2 & mode_max == 3)
)

observed_mode_major_flag <- with(
  df_flagged_pre_peak,
  (SEVERITY_CODE == 0 & mode_max %in% c(2, 3)) |
    (SEVERITY_CODE == 1 & mode_max %in% c(2, 3)) |
    (SEVERITY_CODE == 2 & mode_max == 3)
)

median_major_flag <- with(
  df_flagged_pre_peak,
  (median_cur == 0 & median_max %in% c(2, 3)) |
    (median_cur == 1 & median_max %in% c(2, 3)) |
    (median_cur == 2 & median_max == 3)
)

observed_median_major_flag <- with(
  df_flagged_pre_peak,
  (SEVERITY_CODE == 0 & median_max %in% c(2, 3)) |
    (SEVERITY_CODE == 1 & median_max %in% c(2, 3)) |
    (SEVERITY_CODE == 2 & median_max == 3)
)

any_major_flag <- mode_major_flag |
  observed_mode_major_flag |
  median_major_flag |
  observed_median_major_flag

all_major_flag <- mode_major_flag &
  observed_mode_major_flag &
  median_major_flag &
  observed_median_major_flag

prop_any_major_flag <- mean(any_major_flag, na.rm = TRUE)
prop_all_major_flag <- mean(all_major_flag, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Occurrence threshold flags
# ------------------------------------------------------------------------------

mode_occurrence_flag <- with(
  df_flagged_pre_peak,
  SEVERITY_CODE %in% c(0, 1) & mode_max %in% c(2, 3)
)

median_occurrence_flag <- with(
  df_flagged_pre_peak,
  SEVERITY_CODE %in% c(0, 1) & median_max %in% c(2, 3)
)

any_occurrence_flag <- mode_occurrence_flag | median_occurrence_flag
all_occurrence_flag <- mode_occurrence_flag & median_occurrence_flag

prop_any_occurrence_flag <- mean(any_occurrence_flag, na.rm = TRUE)
prop_all_occurrence_flag <- mean(all_occurrence_flag, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Final summary table
# ------------------------------------------------------------------------------

flag_summary_table <- tibble::tibble(
  metric = c(
    "prop_any_flag",
    "prop_all_flag",
    "prop_any_major_flag",
    "prop_all_major_flag",
    "prop_any_occurrence_flag",
    "prop_all_occurrence_flag"
  ),
  value = c(
    prop_any_flag,
    prop_all_flag,
    prop_any_major_flag,
    prop_all_major_flag,
    prop_any_occurrence_flag,
    prop_all_occurrence_flag
  )
)

# ------------------------------------------------------------------------------
# Variable descriptions / metadata table
# ------------------------------------------------------------------------------

flag_summary_metadata <- tibble::tibble(
  metric = c(
    "prop_any_flag",
    "prop_all_flag",
    "prop_any_major_flag",
    "prop_all_major_flag",
    "prop_any_occurrence_flag",
    "prop_all_occurrence_flag"
  ),
  description = c(
    "Proportion of reports flagged by at least one of the four flagging methods.",
    "Proportion of reports flagged simultaneously by all four flagging methods.",
    "Proportion of reports showing major predicted severity underestimation in at least one comparison.",
    "Proportion of reports showing major predicted severity underestimation in all comparisons.",
    "Proportion of reports where predicted maximum severity crossed the occurrence threshold (Moderate/Severe) in at least one comparison.",
    "Proportion of reports where predicted maximum severity crossed the occurrence threshold (Moderate/Severe) in all comparisons."
  )
)

# ------------------------------------------------------------------------------
# Export summary tables
# ------------------------------------------------------------------------------

write_xlsx(
  list(
    summary = flag_summary_table,
    metadata = flag_summary_metadata
  ),
  here("03_flagging", "summaries_and_figures", "tables", "pre_peak_flag_summary_table.xlsx")
)

# ------------------------------------------------------------------------------
# Regional/year occurrence summary
# ------------------------------------------------------------------------------

occurrence_summary_by_region_year <- df_flagged_pre_peak %>%
  mutate(
    any_occurrence_flag = any_occurrence_flag,
    all_occurrence_flag = all_occurrence_flag,
    OCEAN_REGION = case_when(
      OCEAN_REGION %in% c("NA Pacific Ocean", "Pacific Ocean") ~ "Pacific Ocean",
      TRUE ~ OCEAN_REGION
    )
  ) %>%
  group_by(OCEAN_REGION, YEAR) %>%
  summarise(
    prop_any = mean(any_occurrence_flag, na.rm = TRUE),
    prop_all = mean(all_occurrence_flag, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

# ------------------------------------------------------------------------------
# Metadata for grouped table
# ------------------------------------------------------------------------------

occurrence_summary_metadata <- tibble::tibble(
  variable = c(
    "OCEAN_REGION",
    "YEAR",
    "prop_any",
    "prop_all",
    "n"
  ),
  description = c(
    "Ocean region associated with the bleaching report.",
    "Year of the bleaching report.",
    "Proportion of reports flagged by at least one occurrence-threshold comparison.",
    "Proportion of reports flagged by all occurrence-threshold comparisons.",
    "Number of reports within the region-year group."
  )
)

# ------------------------------------------------------------------------------
# Export grouped table
# ------------------------------------------------------------------------------

write_xlsx(
  list(
    summary = occurrence_summary_by_region_year,
    metadata = occurrence_summary_metadata
  ),
  here("03_flagging", "summaries_and_figures", "tables", "pre_peak_occurrence_summary_by_region_year.xlsx")
)