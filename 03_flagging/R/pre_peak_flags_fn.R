#' Compute flags by predicting per-row class probabilities with posterior_epred
#' using the fitted brms model (fit_pre) at DHW and MAX_ANNUAL_DHW.
#' Assumes 4 severity classes (0..3), and that posterior_epred returns per-class
#' probabilities (categorical or ordinal families).
#'
#' Output columns added to df_pre:
#'  - mode_cur      : most probable mode at DHW
#'  - median_cur    : most probable median at DHW
#'  - mode_max      : most probable mode at MAX_ANNUAL_DHW
#'  - median_max    : most probable median at MAX_ANNUAL_DHW
#'  - flag1, flag2, flag3, flag4  (see logic below)
#'
#' Notes:
#'  - re_formula = NULL includes group-level effects (random intercepts/slopes),
#'    so newdata must include the grouping identifiers (e.g., YEAR, spatial_cluster)
#'    at the values for the row being predicted.
compute_flags_from_brms <- function(
    fit_pre,
    df_pre,
    dhw_col = "DHW",
    max_col = "MAX_ANNUAL_DHW",
    # re_cols: columns needed so the model can apply the right random effects.
    # e.g., c("YEAR", "spatial_cluster") — adjust to match model's grouping vars.
    re_cols = character(0)
) {
  # ---- 0) Basic checks ----
  stopifnot(dhw_col %in% names(df_pre), max_col %in% names(df_pre))
  if (!all(re_cols %in% names(df_pre))) {
    stop("Some re_cols are missing from df_pre: ",
         paste(setdiff(re_cols, names(df_pre)), collapse = ", "))
  }
  
  # Ensure observed severity is numeric 0..3
  if (!is.numeric(df_pre$SEVERITY_CODE)) {
    sev_map <- c("None" = 0, "Mild" = 1, "Moderate" = 2, "Severe" = 3)
    df_pre$SEVERITY_CODE <- unname(sev_map[df_pre$SEVERITY_CODE])
  }
  obs <- as.integer(df_pre$SEVERITY_CODE)
  
  # ---- 1) Build two newdata frames (current DHW and MAX DHW), preserving RE cols ----
  newdata_cur <- df_pre[, unique(c(dhw_col, re_cols)), drop = FALSE]
  newdata_max <- newdata_cur
  newdata_cur[[dhw_col]] <- df_pre[[dhw_col]]
  newdata_max[[dhw_col]] <- df_pre[[max_col]]
  
  # ---- 2) CRITICAL FIX: align grouping variables to fitted model ----
  for (v in re_cols) {
    
    if (is.factor(fit_pre$data[[v]])) {
      # match factor levels EXACTLY
      newdata_cur[[v]] <- factor(
        as.character(newdata_cur[[v]]),
        levels = levels(fit_pre$data[[v]])
      )
      newdata_max[[v]] <- factor(
        as.character(newdata_max[[v]]),
        levels = levels(fit_pre$data[[v]])
      )
      
    } else {
      # keep numeric/integer grouping vars numeric
      newdata_cur[[v]] <- as.numeric(newdata_cur[[v]])
      newdata_max[[v]] <- as.numeric(newdata_max[[v]])
    }
  }
  
  # ---- 3) Posterior predictions (per-class probabilities) with RE included ----
  # posterior_epred returns: draws x N observations x K categories (K: number of classes)
  # We will average across draws to get posterior mean class probabilities.
  ep_cur <- brms::posterior_epred(fit_pre, newdata = newdata_cur, re_formula = NULL)
  ep_max <- brms::posterior_epred(fit_pre, newdata = newdata_max, re_formula = NULL)
  
  # Sanity shape check
  if (length(dim(ep_cur)) != 3L || length(dim(ep_max)) != 3L) {
    stop("posterior_epred did not return a 3D array (draws x N x K).")
  }
  draws_cur <- dim(ep_cur)[1]; N <- dim(ep_cur)[2]; K <- dim(ep_cur)[3]
  draws_max <- dim(ep_max)[1]
  if (N != nrow(df_pre)) {
    stop("Prediction count mismatch: N predictions != nrow(df_pre).")
  }
  if (K != 4L) {
    stop("Expected 4 severity classes (0..3), but posterior_epred returned K = ", K)
  }
  
  # ---- 4) Posterior mean probabilities per obs (N x K) ----
  # Average over draws (dimension 1)
  # Result: probs_cur[n, k] = mean posterior probability of class k at DHW for obs n
  probs_cur <- apply(ep_cur, c(2, 3), mean, na.rm = TRUE)
  probs_max <- apply(ep_max, c(2, 3), mean, na.rm = TRUE)
  # Ensure matrices, keep dimnames if present
  probs_cur <- as.matrix(probs_cur)
  probs_max <- as.matrix(probs_max)
  
  # ---- 5) Helpers to extract mode and "median class" from probabilities ----
  # Classes are assumed ordered 0 < 1 < 2 < 3
  get_mode_class <- function(p_row) {
    # returns 0..3
    which.max(p_row) - 1L
  }
  get_median_class <- function(p_row) {
    # cumulative median class: first index with cumprob >= 0.5
    cum <- cumsum(p_row)
    which(cum >= 0.5)[1] - 1L
  }
  
  # Vectorized application across rows: N x 1 vectors 
  mode_cur   <- apply(probs_cur, 1, get_mode_class)
  mode_max   <- apply(probs_max, 1, get_mode_class)
  median_cur <- apply(probs_cur, 1, get_median_class)
  median_max <- apply(probs_max, 1, get_median_class)
  
  # ---- 6) Apply "DHW > 10 => force class 3" rule to both mode and median ----
  #force_to_3 <- function(x, mask) { x[mask & (x < 3L | is.na(x))] <- 3L; x }
  #over10_cur <- df_pre[[dhw_col]] > 10
  #over10_max <- df_pre[[max_col]] > 10
  
  #mode_cur   <- force_to_3(mode_cur,   over10_cur)
  #median_cur <- force_to_3(median_cur, over10_cur)
  #mode_max   <- force_to_3(mode_max,   over10_max)
  #median_max <- force_to_3(median_max, over10_max)
  
  # ---- 7) Compute flags (no thresholds) ----
  # Flag 1: mode (max vs current)
  flag1 <- (mode_max > mode_cur)
  flag1[is.na(flag1)] <- FALSE
  
  # Flag 2: mode (max vs observed)
  flag2 <- (mode_max > obs)
  flag2[is.na(flag2)] <- FALSE
  
  # Flag 3: median (max vs current)
  flag3 <- (median_max > median_cur)
  flag3[is.na(flag3)] <- FALSE
  
  # Flag 4: median (max vs observed)
  flag4 <- (median_max > obs)
  flag4[is.na(flag4)] <- FALSE
  
  # ---- 8) Attach outputs and return ----
  out <- df_pre
  out$mode_cur   <- as.integer(mode_cur)
  out$median_cur <- as.integer(median_cur)
  out$mode_max   <- as.integer(mode_max)
  out$median_max <- as.integer(median_max)
  out$flag1 <- as.logical(flag1)
  out$flag2 <- as.logical(flag2)
  out$flag3 <- as.logical(flag3)
  out$flag4 <- as.logical(flag4)
  
  out
}