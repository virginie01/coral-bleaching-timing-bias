# Fast post-peak flags computation (population-level only, cached by MAX)
# - Uses draw-based decision probabilities (mode/median) from posterior_epred
# - Ignores random effects: re_formula = NA
# - Caches mode_max/median_max/day_at_* once per MAX_ANNUAL_DHW
# - Keeps flag1..flag4 identical to pre-peak function

compute_flags_postpeak_from_brms_fast <- function(
    fit_post,
    df_post,
    day_col = "DAYS_FROM_MAX_DHW",
    max_col = "MAX_ANNUAL_DHW",
    prob_thresh = 0.75,
    ndraws = 500,
    day_grid = NULL,         # optional override
    max_round = NULL,        # optional rounding for caching, e.g., 0.1 or 0.25
    verbose = TRUE
) {
  
  ## -----------------------------
  ## 0) Checks & setup
  ## -----------------------------
  stopifnot(day_col %in% names(df_post),
            max_col %in% names(df_post),
            "SEVERITY_CODE" %in% names(df_post))
  
  # Ensure observed severity is numeric 0..3
  if (!is.numeric(df_post$SEVERITY_CODE)) {
    sev_map <- c("None" = 0, "Mild" = 1, "Moderate" = 2, "Severe" = 3)
    df_post$SEVERITY_CODE <- unname(sev_map[df_post$SEVERITY_CODE])
  }
  obs <- as.integer(df_post$SEVERITY_CODE)
  
  # Day grid: post-peak only, from training data unless provided
  if (is.null(day_grid)) {
    day_grid <- sort(unique(fit_post$data[[day_col]]))
    day_grid <- day_grid[day_grid >= 0]
  } else {
    day_grid <- sort(unique(day_grid))
    day_grid <- day_grid[day_grid >= 0]
  }
  if (length(day_grid) == 0) stop("day_grid has length 0 after filtering >= 0.")
  
  # Optional rounding for caching MAX values (helps if MAX is continuous with many unique values)
  max_key <- df_post[[max_col]]
  if (!is.null(max_round)) {
    max_key <- round(max_key / max_round) * max_round
  }
  
  ## -----------------------------
  ## 1) Helpers (draw-based decision probabilities)
  ## -----------------------------
  
  decision_prob_matrix <- function(ep, type = c("mode", "median")) {
    type <- match.arg(type)
    
    if (length(dim(ep)) != 3L) {
      stop("ep is not 3D: dim(ep) = ", paste(dim(ep), collapse = " x "))
    }
    
    D <- dim(ep)[1]
    N <- dim(ep)[2]
    K <- dim(ep)[3]
    if (N == 0) stop("decision_prob_matrix(): N = 0 observations in ep")
    if (K != 4L) stop("Expected K=4 categories (0..3); got K=", K)
    
    decision_draw <- matrix(NA_integer_, nrow = D, ncol = N)
    
    for (d in seq_len(D)) {
      mat <- ep[d, , , drop = FALSE][1, , ]
      if (is.null(dim(mat))) mat <- matrix(mat, nrow = 1)  # N==1 safeguard
      
      if (type == "mode") {
        decision_draw[d, ] <- apply(mat, 1, which.max) - 1L
      } else {
        cum <- t(apply(mat, 1, cumsum))
        decision_draw[d, ] <- apply(cum, 1, function(x) which(x >= 0.5)[1]) - 1L
      }
    }
    
    prob_mat <- sapply(0:(K - 1), function(k) colMeans(decision_draw == k, na.rm = TRUE))
    prob_mat <- matrix(prob_mat, nrow = N, ncol = K)        # N×K even when N==1
    colnames(prob_mat) <- paste0("p", 0:(K - 1))
    
    chosen <- apply(prob_mat, 1, function(p) {
      mx <- max(p, na.rm = TRUE)
      which(p == mx)[1] - 1L  # tie-break to lowest category
    })
    
    out <- as.data.frame(prob_mat)
    out$chosen <- as.integer(chosen)
    out
  }
  
  pick_max_severity <- function(dec_df, day_vals) {
    # dec_df has columns p0..p3 and chosen, one row per day
    S_max <- max(dec_df$chosen, na.rm = TRUE)
    idx_attain <- which(dec_df$chosen == S_max)
    if (length(idx_attain) == 0) {
      # Should not happen, but be safe
      return(list(S = S_max, day_at = min(day_vals)))
    }
    
    pS <- dec_df[[paste0("p", S_max)]][idx_attain]
    days_attain <- day_vals[idx_attain]
    
    if (any(pS >= prob_thresh, na.rm = TRUE)) {
      idx_ok <- which(pS >= prob_thresh)
      j <- idx_ok[which.min(days_attain[idx_ok])]
      list(S = S_max, day_at = days_attain[j])
    } else {
      j <- which.max(pS)
      row_probs <- as.numeric(dec_df[idx_attain[j], paste0("p", 0:3)])
      top2 <- order(row_probs, decreasing = TRUE)[1:2] - 1L
      list(S = min(top2), day_at = days_attain[j])
    }
  }
  
  choose_current <- function(dec_row, conservative = FALSE) {
    probs <- as.numeric(dec_row[paste0("p", 0:3)])
    if (max(probs, na.rm = TRUE) >= prob_thresh) {
      which.max(probs) - 1L
    } else {
      top2 <- order(probs, decreasing = TRUE)[1:2] - 1L
      if (conservative) min(top2) else max(top2)
    }
  }
  
  ## -----------------------------
  ## 2) Precompute/cache max-envelope once per MAX (population-level)
  ## -----------------------------
  MAX_vals <- sort(unique(max_key))
  cache <- data.frame(
    MAX_key = MAX_vals,
    mode_max = integer(length(MAX_vals)),
    median_max = integer(length(MAX_vals)),
    day_at_mode_max = numeric(length(MAX_vals)),
    day_at_median_max = numeric(length(MAX_vals)),
    stringsAsFactors = FALSE
  )
  
  if (verbose) message("Precomputing post-peak envelopes for ", length(MAX_vals), " MAX values...")
  
  for (j in seq_along(MAX_vals)) {
    MAXj <- MAX_vals[j]
    
    newdata_grid <- data.frame(
      DAYS_FROM_MAX_DHW = day_grid,
      MAX_ANNUAL_DHW = MAXj
    )
    
    ep_grid <- brms::posterior_epred(
      fit_post,
      newdata = newdata_grid,
      re_formula = NA,      # population-level only
      ndraws = ndraws
    )
    
    dec_mode_grid   <- decision_prob_matrix(ep_grid, "mode")
    dec_median_grid <- decision_prob_matrix(ep_grid, "median")
    
    pick_mode   <- pick_max_severity(dec_mode_grid, day_grid)
    pick_median <- pick_max_severity(dec_median_grid, day_grid)
    
    cache$mode_max[j]         <- pick_mode$S
    cache$median_max[j]       <- pick_median$S
    cache$day_at_mode_max[j]  <- pick_mode$day_at
    cache$day_at_median_max[j]<- pick_median$day_at
    
    if (verbose && (j %% 10 == 0)) message("  ...done ", j, "/", length(MAX_vals))
  }
  
  # Fast lookup map
  idx_map <- setNames(seq_along(cache$MAX_key), as.character(cache$MAX_key))
  
  ## -----------------------------
  ## 3) Per-row current predictions + monotonicity + flags
  ## -----------------------------
  N <- nrow(df_post)
  mode_cur   <- integer(N)
  median_cur <- integer(N)
  mode_max   <- integer(N)
  median_max <- integer(N)
  
  # Populate max results from cache
  for (i in seq_len(N)) {
    key <- max_key[i]
    k <- idx_map[[as.character(key)]]
    mode_max[i]   <- cache$mode_max[k]
    median_max[i] <- cache$median_max[k]
  }
  
  if (verbose) message("Computing current predictions for ", N, " rows...")
  
  for (i in seq_len(N)) {
    key <- max_key[i]
    k <- idx_map[[as.character(key)]]
    
    day_at_mode_max   <- cache$day_at_mode_max[k]
    day_at_median_max <- cache$day_at_median_max[k]
    
    newdata_cur <- data.frame(
      DAYS_FROM_MAX_DHW = df_post[[day_col]][i],
      MAX_ANNUAL_DHW    = key
    )
    
    ep_cur <- brms::posterior_epred(
      fit_post,
      newdata = newdata_cur,
      re_formula = NA,
      ndraws = ndraws
    )
    
    dec_mode_cur   <- decision_prob_matrix(ep_cur, "mode")
    dec_median_cur <- decision_prob_matrix(ep_cur, "median")
    
    # As you specified: if uncertain (no >=0.75), choose higher severity for current
    mode_cur[i]   <- choose_current(dec_mode_cur[1, ], conservative = FALSE)
    median_cur[i] <- choose_current(dec_median_cur[1, ], conservative = FALSE)
    
    # Temporal monotonicity constraint (separately for mode and median)
    if (df_post[[day_col]][i] < day_at_mode_max) {
      mode_cur[i] <- mode_max[i]
    }
    if (df_post[[day_col]][i] < day_at_median_max) {
      median_cur[i] <- median_max[i]
    }
    
    if (verbose && (i %% 1000 == 0)) message("  ...done ", i, "/", N)
  }
  
  ## -----------------------------
  ## 4) Flags (IDENTICAL to pre-peak)
  ## -----------------------------
  flag1 <- (mode_max > mode_cur);     flag1[is.na(flag1)] <- FALSE
  flag2 <- (mode_max > obs);          flag2[is.na(flag2)] <- FALSE
  flag3 <- (median_max > median_cur); flag3[is.na(flag3)] <- FALSE
  flag4 <- (median_max > obs);        flag4[is.na(flag4)] <- FALSE
  
  ## -----------------------------
  ## 5) Output
  ## -----------------------------
  out <- df_post
  out$mode_cur   <- as.integer(mode_cur)
  out$median_cur <- as.integer(median_cur)
  out$mode_max   <- as.integer(mode_max)
  out$median_max <- as.integer(median_max)
  out$flag1 <- as.logical(flag1)
  out$flag2 <- as.logical(flag2)
  out$flag3 <- as.logical(flag3)
  out$flag4 <- as.logical(flag4)
  
  # Attach cache as attribute (handy for debugging / plotting)
  attr(out, "postpeak_cache") <- cache
  out
}