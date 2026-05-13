#!/usr/bin/env Rscript
# =============================================================================
# scripts/validate_wa_rcp45_r21.R
#
# Pre staged validation of the WA RCP 4.5 production run (SLURM job 9327153,
# expected to land ~7:00 EDT 11 May 2026). Reads outputs from the canonical
# production directory, computes headline totals, compares against EVALIDator
# sanity bounds in docs/SMOKE_SANITY_20260510.md and against the ME r21 RCP 4.5
# baseline for cross state pattern consistency, then writes a one page memo to
# docs/VALIDATION_WA_R21_RCP45.md.
#
# Designed to be run on Cardinal once the job lands:
#   Rscript scripts/validate_wa_rcp45_r21.R
#
# Or locally after pulling the WA output dir under output/.
#
# Author: A. Weiskittel (pre staged by CRSF Cowork session 10 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Resolve roots. FIA_CEM_DIR points to ~/fia_cem_projections on Cardinal; on
# the workstation, fall back to the local repo output/ tree.
fia_root <- Sys.getenv("FIA_CEM_DIR", "")
if (!nzchar(fia_root)) {
  fia_root <- if (dir.exists("~/fia_cem_projections")) {
    path.expand("~/fia_cem_projections")
  } else {
    # Local repo fallback
    here::here()
  }
}

WA_DIR     <- file.path(fia_root, "output", "WA_20260510_rcp45_wear_p1")
ME_REF_DIR <- file.path(fia_root, "output", "ME_20260505_rcp45_hadgem2_wear_r21")
MEMO_PATH  <- here::here("docs", "VALIDATION_WA_R21_RCP45.md")

# EVALIDator sanity bounds for WA. Bounds drawn from SMOKE_SANITY_20260510.md
# and the HANDOFF doc. Each entry: c(lower, upper) acceptable range.
WA_BOUNDS <- list(
  forest_area_mac      = c(20, 24),       # M ac, EVALIDator ~22.0
  total_vol_bcuft      = c(55, 80),       # B cuft, EVALIDator ~70
  total_carbon_tgc     = c(900, 1300),    # TgC, EVALIDator ~1100
  per_ac_vol_cuft      = c(2700, 3300),   # cuft/ac, smoke 3004
  per_ac_ba_sqft       = c(95, 115),      # sqft/ac, smoke 106
  per_ac_carbon_kgac   = c(55000, 65000), # kg/ac, smoke 59693
  per_ac_tpa           = c(280, 380),     # smoke 326
  harvest_rate_pct     = c(13, 20),       # %, smoke 16.7
  gr_ratio_cycle1      = c(0.003, 0.010), # post Layer 1, pre Layer 2
  per_owner_classes_n  = c(4, 8)          # HCB classes 1 through 6 plus residual
)

WA_FOREST_AREA_MAC <- 22.0  # M ac (EVALIDator headline)
ME_FOREST_AREA_MAC <- 17.6
WA_STATE_NAME <- "Washington"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

fmt_num <- function(x, d = 1) {
  if (is.na(x) || is.null(x)) return("NA")
  formatC(x, format = "f", digits = d, big.mark = ",")
}

check_bound <- function(value, bounds, label) {
  if (is.na(value) || is.null(value)) {
    return(list(pass = NA, status = "MISSING", value = NA_real_, label = label,
                bounds = bounds))
  }
  pass <- value >= bounds[1] && value <= bounds[2]
  status <- if (pass) "PASS" else "FLAG"
  list(pass = pass, status = status, value = as.numeric(value),
       label = label, bounds = bounds)
}

format_check_row <- function(chk) {
  bounds_str <- sprintf("[%s, %s]",
                        fmt_num(chk$bounds[1], 2),
                        fmt_num(chk$bounds[2], 2))
  sprintf("| %s | %s | %s | %s |",
          chk$label, fmt_num(chk$value, 2), bounds_str, chk$status)
}

safe_read_csv <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(read_csv(path, show_col_types = FALSE),
           error = function(e) NULL)
}

safe_read_rds <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(readRDS(path), error = function(e) NULL)
}

# Parse ci_summaries.csv interval strings like "0.005 (0.005, 0.006)" into
# numeric mean.
parse_ci_mean <- function(x) {
  if (is.numeric(x)) return(x)
  as.numeric(sub(" .*$", "", as.character(x)))
}

# -----------------------------------------------------------------------------
# Output presence check
# -----------------------------------------------------------------------------

required_files <- c(
  "table_inventory_summary.csv",
  "table_gr_ratios.csv",
  "ci_summaries.csv",
  "raw_mc_summaries.csv",
  "per_plot_projections.rds"
)

missing <- required_files[!file.exists(file.path(WA_DIR, required_files))]

if (length(missing) > 0 || !dir.exists(WA_DIR)) {
  msg <- sprintf(
    "WA output not ready yet. Missing files in %s:\n  %s\n\nCheck SLURM job 9327153 status:\n  sacct -j 9327153 --format=JobID,JobName%%25,State,ExitCode,Elapsed\n",
    WA_DIR, paste(missing, collapse = ", "))
  cat(msg, file = stderr())
  quit(status = 2, save = "no")
}

cat("WA output dir present, all required files found. Reading...\n")

# -----------------------------------------------------------------------------
# Load WA outputs
# -----------------------------------------------------------------------------

wa_inv  <- safe_read_csv(file.path(WA_DIR, "table_inventory_summary.csv"))
wa_gr   <- safe_read_csv(file.path(WA_DIR, "table_gr_ratios.csv"))
wa_ci   <- safe_read_csv(file.path(WA_DIR, "ci_summaries.csv"))
wa_raw  <- safe_read_csv(file.path(WA_DIR, "raw_mc_summaries.csv"))
wa_plot <- safe_read_rds(file.path(WA_DIR, "per_plot_projections.rds"))

me_inv  <- safe_read_csv(file.path(ME_REF_DIR, "table_inventory_summary.csv"))
me_gr   <- safe_read_csv(file.path(ME_REF_DIR, "table_gr_ratios.csv"))
me_ci   <- safe_read_csv(file.path(ME_REF_DIR, "ci_summaries.csv"))

me_available <- !is.null(me_inv)
if (!me_available) {
  warning("ME r21 RCP 4.5 reference not found at ", ME_REF_DIR,
          ". Cross state deltas will be omitted.")
}

# -----------------------------------------------------------------------------
# Extract WA headline numbers (cycle 1 baseline, BAU scenario)
# -----------------------------------------------------------------------------

wa_cyc1 <- wa_inv |>
  filter(cycle == 1, scenario == "BAU") |>
  slice(1)

wa_per_ac_vol     <- wa_cyc1$mean_vol_mean[1]
wa_per_ac_ba      <- wa_cyc1$mean_ba_mean[1]
wa_per_ac_carbon  <- wa_cyc1$mean_carbon_mean[1]
wa_per_ac_tpa     <- wa_cyc1$total_tpa_mean[1]

# Harvest rate may be stored as "16.7%" string or as numeric. Coerce.
wa_harv_rate_str <- as.character(wa_cyc1$harvest_rate_mean[1])
wa_harv_rate_pct <- as.numeric(sub("%", "", wa_harv_rate_str))

# Total statewide volume and carbon (per acre x forest area)
wa_total_vol_bcuft   <- (wa_per_ac_vol * WA_FOREST_AREA_MAC * 1e6) / 1e9
wa_total_carbon_kgst <- wa_per_ac_carbon * WA_FOREST_AREA_MAC * 1e6
wa_total_carbon_tgc  <- wa_total_carbon_kgst / 1e9  # kg to Tg

# Cycle 1 BAU gr_ratio (mean from interval string)
wa_gr_cyc1 <- if (!is.null(wa_gr)) {
  gr_row <- wa_gr |> filter(cycle == 1) |> slice(1)
  parse_ci_mean(gr_row$BAU[1])
} else NA_real_

# -----------------------------------------------------------------------------
# Per ownership distribution (from per_plot)
# -----------------------------------------------------------------------------

owner_dist <- NULL
if (!is.null(wa_plot) && is.data.frame(wa_plot)) {
  owner_cols <- intersect(c("owner_class", "OwnerClass", "hcb_class",
                            "HCB_CLASS", "OWNCD"), names(wa_plot))
  if (length(owner_cols) > 0) {
    owner_col <- owner_cols[1]

    # Find a harvest volume column. Common candidates from the pipeline.
    harv_cols <- intersect(c("vol_removed_total", "harvest_volume",
                             "removed_vol", "harv_vol"), names(wa_plot))
    vol_col <- intersect(c("proj_volcfnet", "volcfnet", "vol"),
                         names(wa_plot))

    if (length(harv_cols) > 0 || length(vol_col) > 0) {
      use_col <- if (length(harv_cols) > 0) harv_cols[1] else vol_col[1]
      owner_dist <- wa_plot |>
        filter(!is.na(.data[[owner_col]])) |>
        group_by(owner = .data[[owner_col]]) |>
        summarise(
          n_plots = n_distinct(if ("PLT_CN" %in% names(wa_plot)) PLT_CN else row_number()),
          mean_value = mean(.data[[use_col]], na.rm = TRUE),
          .groups = "drop"
        ) |>
        arrange(desc(n_plots))
    }
  }
}

# -----------------------------------------------------------------------------
# Apply sanity bound checks
# -----------------------------------------------------------------------------

checks <- list(
  check_bound(wa_per_ac_vol,      WA_BOUNDS$per_ac_vol_cuft,
              "Per acre volume (cuft/ac)"),
  check_bound(wa_per_ac_ba,       WA_BOUNDS$per_ac_ba_sqft,
              "Per acre BA (sqft/ac)"),
  check_bound(wa_per_ac_carbon,   WA_BOUNDS$per_ac_carbon_kgac,
              "Per acre carbon (kg/ac)"),
  check_bound(wa_per_ac_tpa,      WA_BOUNDS$per_ac_tpa,
              "Per acre TPA"),
  check_bound(wa_harv_rate_pct,   WA_BOUNDS$harvest_rate_pct,
              "Harvest rate (%)"),
  check_bound(wa_total_vol_bcuft, WA_BOUNDS$total_vol_bcuft,
              "Statewide total volume (Bcuft)"),
  check_bound(wa_total_carbon_tgc, WA_BOUNDS$total_carbon_tgc,
              "Statewide total carbon (TgC)"),
  check_bound(wa_gr_cyc1,         WA_BOUNDS$gr_ratio_cycle1,
              "gr_ratio cycle 1 BAU (post L1)")
)

n_pass <- sum(vapply(checks, function(c) isTRUE(c$pass), logical(1)))
n_flag <- sum(vapply(checks, function(c) isFALSE(c$pass), logical(1)))
n_miss <- sum(vapply(checks, function(c) is.na(c$pass), logical(1)))

overall <- if (n_flag == 0 && n_miss == 0) {
  "PASS (all checks within bounds)"
} else if (n_flag <= 2 && n_miss == 0) {
  "REVIEW (one or two flagged; not blocking)"
} else {
  "FAIL (multiple flags or missing data)"
}

# -----------------------------------------------------------------------------
# Cross state deltas vs ME r21 RCP 4.5
# -----------------------------------------------------------------------------

deltas <- NULL
if (me_available) {
  me_cyc1 <- me_inv |>
    filter(cycle == 1, scenario == "BAU") |>
    slice(1)

  me_per_ac_vol    <- me_cyc1$mean_vol_mean[1]
  me_per_ac_ba     <- me_cyc1$mean_ba_mean[1]
  me_per_ac_carbon <- me_cyc1$mean_carbon_mean[1]
  me_per_ac_tpa    <- me_cyc1$total_tpa_mean[1]
  me_harv_rate_pct <- as.numeric(sub("%", "", as.character(me_cyc1$harvest_rate_mean[1])))
  me_total_vol_bcuft  <- (me_per_ac_vol * ME_FOREST_AREA_MAC * 1e6) / 1e9
  me_total_carbon_tgc <- (me_per_ac_carbon * ME_FOREST_AREA_MAC * 1e6) / 1e9

  deltas <- tribble(
    ~metric,                          ~WA,                ~ME_r21,           ~delta_pct,
    "Per acre vol (cuft/ac)",         wa_per_ac_vol,      me_per_ac_vol,     100 * (wa_per_ac_vol - me_per_ac_vol) / me_per_ac_vol,
    "Per acre BA (sqft/ac)",          wa_per_ac_ba,       me_per_ac_ba,      100 * (wa_per_ac_ba - me_per_ac_ba) / me_per_ac_ba,
    "Per acre carbon (kg/ac)",        wa_per_ac_carbon,   me_per_ac_carbon,  100 * (wa_per_ac_carbon - me_per_ac_carbon) / me_per_ac_carbon,
    "Per acre TPA",                   wa_per_ac_tpa,      me_per_ac_tpa,     100 * (wa_per_ac_tpa - me_per_ac_tpa) / me_per_ac_tpa,
    "Harvest rate (%)",               wa_harv_rate_pct,   me_harv_rate_pct,  100 * (wa_harv_rate_pct - me_harv_rate_pct) / me_harv_rate_pct,
    "Statewide vol (Bcuft)",          wa_total_vol_bcuft, me_total_vol_bcuft,100 * (wa_total_vol_bcuft - me_total_vol_bcuft) / me_total_vol_bcuft,
    "Statewide carbon (TgC)",         wa_total_carbon_tgc,me_total_carbon_tgc,100 * (wa_total_carbon_tgc - me_total_carbon_tgc) / me_total_carbon_tgc
  )
}

# -----------------------------------------------------------------------------
# Write the memo
# -----------------------------------------------------------------------------

dir.create(dirname(MEMO_PATH), showWarnings = FALSE, recursive = TRUE)
sink(MEMO_PATH)

cat("# WA RCP 4.5 production run validation (job 9327153)\n\n")
cat(sprintf("*Generated %s from %s*\n\n",
            format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
            WA_DIR))

cat(sprintf("**Overall: %s.** %d of %d checks passed, %d flagged, %d missing.\n\n",
            overall, n_pass, length(checks), n_flag, n_miss))

cat("## Sanity bound checks (EVALIDator + smoke baseline)\n\n")
cat("| Check | Value | Bounds | Status |\n")
cat("|---|---:|---|:---:|\n")
for (chk in checks) cat(format_check_row(chk), "\n", sep = "")
cat("\n")

cat("## Headline numbers, cycle 1 BAU baseline\n\n")
cat("- Per acre volume: ", fmt_num(wa_per_ac_vol, 0), " cuft/ac\n", sep = "")
cat("- Per acre BA: ", fmt_num(wa_per_ac_ba, 1), " sqft/ac\n", sep = "")
cat("- Per acre carbon: ", fmt_num(wa_per_ac_carbon, 0), " kg/ac\n", sep = "")
cat("- Per acre TPA: ", fmt_num(wa_per_ac_tpa, 0), "\n", sep = "")
cat("- Harvest rate: ", fmt_num(wa_harv_rate_pct, 1), " %\n", sep = "")
cat("- Statewide total volume: ", fmt_num(wa_total_vol_bcuft, 1),
    " Bcuft (forest area assumed ", WA_FOREST_AREA_MAC, " M ac)\n", sep = "")
cat("- Statewide total carbon: ", fmt_num(wa_total_carbon_tgc, 0), " TgC\n", sep = "")
cat("- gr_ratio cycle 1 BAU: ", fmt_num(wa_gr_cyc1, 4), "\n\n", sep = "")

if (!is.null(deltas)) {
  cat("## Cross state deltas vs ME r21 RCP 4.5 baseline\n\n")
  cat("| Metric | WA | ME r21 | Delta (%) |\n")
  cat("|---|---:|---:|---:|\n")
  for (i in seq_len(nrow(deltas))) {
    cat(sprintf("| %s | %s | %s | %s |\n",
                deltas$metric[i],
                fmt_num(deltas$WA[i], 1),
                fmt_num(deltas$ME_r21[i], 1),
                fmt_num(deltas$delta_pct[i], 1)))
  }
  cat("\nExpected pattern: WA per acre volume substantially higher than ME ",
      "(Pacific NW conifer vs Northern mixed forest); harvest rate higher; ",
      "TPA lower (larger average tree size in WA).\n\n", sep = "")
} else {
  cat("## Cross state deltas vs ME r21 RCP 4.5 baseline\n\n",
      "ME r21 reference not available at this path. Skipped.\n\n", sep = "")
}

if (!is.null(owner_dist) && nrow(owner_dist) > 0) {
  cat("## Per ownership distribution\n\n")
  cat("| Owner class | N plots | Mean value (selected column) |\n")
  cat("|---|---:|---:|\n")
  for (i in seq_len(nrow(owner_dist))) {
    cat(sprintf("| %s | %d | %s |\n",
                as.character(owner_dist$owner[i]),
                owner_dist$n_plots[i],
                fmt_num(owner_dist$mean_value[i], 1)))
  }
  cat("\nHCB owner code legend at ",
      "`~/fia_cem_projections/config/owner_class_legend.csv`.\n\n", sep = "")
} else {
  cat("## Per ownership distribution\n\n",
      "Owner distribution could not be computed from per_plot_projections.rds ",
      "(missing owner_class or harvest volume columns). Inspect the RDS schema ",
      "manually.\n\n", sep = "")
}

cat("## Flags and follow ups\n\n")
flagged_checks <- Filter(function(c) isFALSE(c$pass), checks)
if (length(flagged_checks) == 0 && n_miss == 0) {
  cat("None. All sanity bounds satisfied. Greenlight for figure building and ",
      "the GA, MN, and RCP 8.5 validations using the template.\n", sep = "")
} else {
  for (chk in flagged_checks) {
    bd <- chk$bounds
    cat(sprintf("- **%s**: %s, outside bounds [%s, %s]. Investigate before ",
                chk$label, fmt_num(chk$value, 2),
                fmt_num(bd[1], 2), fmt_num(bd[2], 2)))
    cat("propagating WA to manuscript tables.\n")
  }
  if (n_miss > 0) {
    cat(sprintf("- %d checks MISSING (NA value from output). Inspect raw output files.\n",
                n_miss))
  }
}

cat("\n## Next actions\n\n")
cat("1. If status PASS, copy WA outputs to local repo: `rsync av crsfaaron@cardinal.osc.edu:fia_cem_projections/output/WA_20260510_rcp45_wear_p1/ output/WA_20260510_rcp45_wear_p1/`\n")
cat("2. Run the template against GA RCP 4.5 (job 9327155) once it lands: `Rscript scripts/validate_template.R --state GA --rcp 45 --tag rcp45_wear_p1`\n")
cat("3. Run the template against MN RCP 4.5 (job 9327152) once it lands.\n")
cat("4. Repeat for the three RCP 8.5 runs (jobs 9327550, 9327551, 9327552).\n")
cat("5. After all six pass, build the dual RCP comparison figures.\n")

sink()
cat("\nMemo written to: ", MEMO_PATH, "\n", sep = "")

# Exit code reflects overall status for shell scripting
if (grepl("^PASS", overall)) {
  quit(status = 0, save = "no")
} else if (grepl("^REVIEW", overall)) {
  quit(status = 1, save = "no")
} else {
  quit(status = 2, save = "no")
}
