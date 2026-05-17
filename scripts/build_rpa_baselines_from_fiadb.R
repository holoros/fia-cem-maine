#!/usr/bin/env Rscript
# build_rpa_baselines_from_fiadb.R
# Compute per state harvest removals from the full FIADB using rFIA, then
# aggregate to RPA subregions. Produces ~/conus_hcs/config/rpa_baselines.csv
# in the format the RPA aggregation script expects.
#
# Approach: rFIA::vol(method = "annual", treeType = "all", landType = "forest",
#                     totals = FALSE) on each state's pre-built fia_db, then
# extract REMOVAL_VOL (the annual harvest removals per acre). Convert to
# annual per-hectare removals, multiply by state forest area to get totals,
# aggregate by RPA subregion (from conus_states.csv mapping).
#
# Run on Cardinal. Inputs: per-state fia_db_*.rds, ~/FIA/ENTIRE_*.csv, or
# raw ENTIRE_POP_*.csv tables. Output: ~/conus_hcs/config/rpa_baselines.csv

suppressPackageStartupMessages({
  library(rFIA)
  library(data.table)
  library(dplyr)
})

FIA_DIR        <- "/users/PUOM0008/crsfaaron/FIA"
CONUS_STATES   <- "/users/PUOM0008/crsfaaron/conus_hcs/config/conus_states.csv"
OUT_CSV        <- "/users/PUOM0008/crsfaaron/conus_hcs/config/rpa_baselines.csv"
OUT_DEBUG_CSV  <- "/users/PUOM0008/crsfaaron/conus_hcs/output/rpa_baselines_per_state_20260517.csv"

# Load RPA subregion mapping from cfg
states_cfg <- data.table::fread(CONUS_STATES, showProgress = FALSE)
data.table::setnames(states_cfg, "state_fips", "STATECD")
states_cfg[, STATECD := as.integer(STATECD)]
cat(sprintf("Loaded %d state entries from conus_states.csv\n", nrow(states_cfg)))

# Approach: use the existing pre-built fia_db_*.rds for GA, MN, WA, and use
# ENTIRE_*.csv tables for any other state we need. Start with the 4 states
# the multistate p1 set covers, then extend.

# rFIA::vol method with REMV component gives annual removal volume per acre.
compute_state_removals <- function(state_postal, statecd) {
  fp <- file.path(FIA_DIR, paste0("fia_db_", state_postal, ".rds"))
  if (!file.exists(fp)) {
    cat(sprintf("  No fia_db for %s (%d); skipping\n", state_postal, statecd))
    return(NULL)
  }
  cat(sprintf("  Reading %s rFIA DB...\n", state_postal))
  db <- readRDS(fp)
  # rFIA::vol with REMV computes Net annual removals volume per acre on forest
  # land. We want REMV_CF_AC (cubic feet per acre annual) and total
  removals <- try(rFIA::vol(db,
                              landType = "forest",
                              treeType = "all",
                              method   = "annual",
                              totals   = TRUE,
                              variance = FALSE,
                              tidy     = TRUE),
                   silent = TRUE)
  if (inherits(removals, "try-error")) {
    cat(sprintf("  rFIA::vol() failed for %s: %s\n", state_postal,
                attr(removals, "condition")$message))
    return(NULL)
  }
  # rFIA tidy output includes columns YEAR, BAA, NETVOL_AC, GROW_AC, REMV_AC, MORT_AC, etc.
  cat(sprintf("  %s columns: %s\n", state_postal,
              paste(head(colnames(removals), 20), collapse = ",")))
  cat(sprintf("  %s nrow: %d\n", state_postal, nrow(removals)))
  if (nrow(removals) == 0) return(NULL)
  # Take latest year per state
  removals <- as.data.table(removals)
  if ("YEAR" %in% names(removals)) {
    latest_year <- max(removals$YEAR, na.rm = TRUE)
    removals <- removals[YEAR == latest_year]
  }
  removals[, STATECD := statecd]
  removals[, state_postal := state_postal]
  removals
}

cat("\nComputing removals for the 3 states with pre-built fia_db RDS:\n")
results <- list()
for (st in c("GA", "MN", "WA")) {
  statecd <- states_cfg[state_postal == st, STATECD]
  if (length(statecd) == 0) next
  r <- compute_state_removals(st, statecd)
  if (!is.null(r)) results[[st]] <- r
}

if (length(results) > 0) {
  all_state <- data.table::rbindlist(results, fill = TRUE)
  cat("\nPer state removals output sample:\n")
  print(head(all_state))
  # Identify removal column. rFIA tidy output uses these:
  #   REMV_AC      annual harvest removals volume per acre, cuft/acre/yr
  #   REMV_TOTAL   annual harvest removals total, cuft/yr
  rem_col_per <- intersect(c("REMV_AC", "REMV_CF_AC", "REMV"), names(all_state))[1]
  rem_col_tot <- intersect(c("REMV_TOTAL", "REMV_CF_TOTAL", "REMV_TOT"), names(all_state))[1]
  cat(sprintf("\nUsing per-acre col: %s   total col: %s\n", rem_col_per, rem_col_tot))
  if (!is.na(rem_col_per)) {
    summary_dt <- all_state[, .(
      state_postal,
      STATECD,
      removal_per_ac = get(rem_col_per),
      removal_total  = if (!is.na(rem_col_tot)) get(rem_col_tot) else NA_real_
    )]
    fwrite(summary_dt, OUT_DEBUG_CSV)
    cat(sprintf("Per-state debug CSV written: %s\n", OUT_DEBUG_CSV))
    # Convert per-acre cuft to per-hectare cubic meters as conus_hcs uses metric:
    # 1 cuft = 0.02832 m^3; 1 acre = 0.4047 ha; per-ac cuft → per-ha m3:
    #   per_ha_m3 = per_ac_cuft * 0.02832 / 0.4047
    summary_dt[, removal_per_ha_m3 := removal_per_ac * 0.02832 / 0.4047]
    # Join to RPA subregion
    summary_dt <- merge(summary_dt, states_cfg, by = "STATECD", all.x = TRUE)
    cat("\nPer state per RPA subregion summary:\n")
    print(summary_dt[, .(state_postal, rpa_subregion, removal_per_ac,
                          removal_per_ha_m3, removal_total)])
    # Aggregate to RPA subregion (sum of state totals, area-weighted per-ha)
    rpa_baseline <- summary_dt[, .(
      n_states       = .N,
      total_removal  = sum(removal_total,    na.rm = TRUE),
      mean_per_ha_m3 = mean(removal_per_ha_m3, na.rm = TRUE)
    ), by = rpa_subregion]
    # The conus_hcs RPA aggregation expects rpa_baseline_removal in the same
    # units as its own removal_per_ha output, which is per-plot expected
    # removal * plot_area_ha. We provide per-ha m^3 as the comparable metric.
    out <- rpa_baseline[, .(rpa_subregion,
                              rpa_baseline_removal = mean_per_ha_m3,
                              n_states_in_baseline = n_states)]
    fwrite(out, OUT_CSV)
    cat(sprintf("\nrpa_baselines.csv written to: %s\n", OUT_CSV))
    print(out)
  } else {
    cat("Could not identify per-acre removal column; aborting.\n")
  }
} else {
  cat("No state results produced.\n")
}
