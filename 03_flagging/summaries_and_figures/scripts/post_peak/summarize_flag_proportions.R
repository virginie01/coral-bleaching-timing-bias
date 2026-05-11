# Required libraries
library(here)
library(readxl)
library(writexl)
library(dplyr)

# ------------------------------------------------------------------------------
# Load flagged post-peak dataset
# ------------------------------------------------------------------------------

df_flagged_post_peak <- readxl::read_xlsx(
  here("03_flagging", "outputs", "df_flagged_post_peak.xlsx")
)

# ------------------------------------------------------------------------------
# Overall flag summaries
# ------------------------------------------------------------------------------

any_flagged <- with(
  df_flagged_post_peak,
  flag1 | flag2 | flag3 | flag4
)

all_flagged <- with(
  df_flagged_post_peak,
  flag1 & flag2 & flag3 & flag4
)

prop_any_flag <- mean(any_flagged, na.rm = TRUE)
prop_all_flag <- mean(all_flagged, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Major underestimation flags
# ------------------------------------------------------------------------------

mode_major_flag <- with(
  df_flagged_post_peak,
  (mode_cur == 0 & mode_max %in% c(2, 3)) |
    (mode_cur == 1 & mode_max %in% c(2, 3)) |
    (mode_cur == 2 & mode_max == 3)
)



median_major_flag <- with(
  df_flagged_post_peak,
  (median_cur == 0 & median_max %in% c(2, 3)) |
    (median_cur == 1 & median_max %in% c(2, 3)) |
    (median_cur == 2 & median_max == 3)
)


any_major_flag <- mode_major_flag |
  median_major_flag

all_major_flag <- mode_major_flag &
  median_major_flag

prop_any_major_flag <- mean(any_major_flag, na.rm = TRUE)
prop_all_major_flag <- mean(all_major_flag, na.rm = TRUE)

# ------------------------------------------------------------------------------
# Final summary table
# ------------------------------------------------------------------------------

flag_summary_table <- tibble::tibble(
  metric = c(
    "prop_any_flag",
    "prop_all_flag",
    "prop_any_major_flag",
    "prop_all_major_flag"
  ),
  value = c(
    prop_any_flag,
    prop_all_flag,
    prop_any_major_flag,
    prop_all_major_flag
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
    "prop_all_major_flag"
  ),
  description = c(
    "Proportion of reports flagged by at least one of the four flagging methods.",
    "Proportion of reports flagged simultaneously by all four flagging methods.",
    "Proportion of reports showing major predicted severity underestimation in at least one comparison.",
    "Proportion of reports showing major predicted severity underestimation in all comparisons."
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
  here("03_flagging", "summaries_and_figures", "tables", "post_peak_flag_summary_table.xlsx")
)
