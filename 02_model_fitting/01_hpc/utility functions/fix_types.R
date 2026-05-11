fix_types <- function(df) {
  df[df == ""] <- NA
  
  df$YEAR <- factor(df$YEAR)
  
  df$SEVERITY_CODE <- factor(
    df$SEVERITY_CODE,
    levels = c("None", "Mild", "Moderate", "Severe"),
    ordered = TRUE
  )
  
  df$spatial_cluster <- factor(df$spatial_cluster)
  
  df$DATETIME <- as.POSIXct(df$DATETIME, tz = "UTC")
  df$DATE_OF_MAX_DHW <- as.POSIXct(df$DATE_OF_MAX_DHW, tz = "UTC")
  
  df$IS_BEST_REPORT <- as.logical(df$IS_BEST_REPORT)
  
  return(df)
}