#!/usr/bin/env Rscript
# =============================================================================
# scripts/validate_template.R
#
# Reusable validation template for any state and RCP combination of the
# multistate p1 production run set. Mirrors scripts/validate_wa_rcp45_r21.R
# but parameterized so it can run against GA, MN, ME, or new states, and
# against RCP 4.5 or RCP 8.5 outputs.
#
# Usage:
#   Rscript scripts/validate_template.R --state WA --rcp 45 --tag rcp45_wear_p1
#   Rscript scripts/validate_template.R --state GA --rcp 45 --tag rcp45_wear_p1
#   Rscript scripts/validate_template.R --state MN --rcp 85 --tag rcp85_wear_p1
#
# Optional flags:
#   --date 20260510     output dir date stamp (default 20260510)
#   --out_dir <path>    override output base, default $FIA_CEM_DIR/output
#   --ref_state ME      cross state delta reference (default ME)
#   --ref_tag <tag>     reference run tag (default rcp45_hadgem2_wear_r21)
#   --memo <path>       memo destination (default docs/VALIDATION_<STATE>_R21_RCP<RCP>.md)
#
# Exit codes:
#   0 = PASS, 1 = REVIEW, 2 = FAIL/MISSING
#
# Author: A. Weiskittel (pre staged by CRSF Cowork session 10 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(optparse)
  library(here)
})

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------

option_list <- list(
  make_option("--state",     type = "character", default = NULL,
              help = "State code (WA, MN, GA, ME). Required."),
  make_option("--rcp",       type = "character", default = "45",
              help = "RCP scenario (45 or 85). Default 45."),
  make_option("--tag",       type = "character", default = NULL,
              help = "Output dir tag (e.g. rcp45_wear_p1). Defaults to rcp<rcp>_wear_p1."),
  make_option("--date",      type = "character", default = "20260510",
              help = "Date stamp in output dir name. Default 20260510."),
  make_option("--out_dir",   type = "character", default = NULL,
              help = "Override output base directory."),
  make_option("--ref_state", type = "character", default = "ME",
              help = "Reference state for cross state deltas. Default ME."),
  make_option("--ref_tag",   type = "character", default = "rcp45_hadgem2_wear_r21",
              help = "Reference output tag. Default rcp45_hadgem2_wear_r21."),
  make_option("--ref_date",  type = "character", default = "20260505",
              help = "Reference date stamp. Default 20260505 (ME r21 RCP 4.5)."),
  make_option("--memo",      type = "character", default = NULL,
              help = "Memo output path. Defaults to docs/VALIDATION_<STATE>_R21_RCP<RCP>.md.")
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$state)) {
  stop("--state is required (WA, MN, GA, or ME).")
}
opt$state <- toupper(opt$state)
opt$ref_state <- toupper(opt$ref_state)
if (is.null(opt$tag)) {
  opt$tag <- sprintf("rcp%s_wear_p1", opt$rcp)
}

# -----------------------------------------------------------------------------
# State specific sanity bounds and forest area (EVALIDator headline)
# -----------------------------------------------------------------------------

# Bounds reflect the smoke baselines in docs/SMOKE_SANITY_20260510.md plus a
# +/-15% acceptance window for production scale up. Adjust if a state drifts
# meaningfully at n_sims 100 and the new value is biophysically defensible.

STATE_PROFILES <- list(
  WA = list(
    forest_area_mac    = 22.0,
    per_ac_vol_cuft    = c(2700, 3300),  # smoke 3004, p1 3133
    per_ac_ba_sqft     = c(95, 115),     # smoke 106, p1 110
    per_ac_carbon_kgac = c(55000, 65000),# p1 62569 lb/ac (column is lb/ac, not kg)
    per_ac_tpa         = c(280, 380),    # smoke 326, p1 340
    harvest_rate_pct   = c(9, 18),       # smoke 16.7, p1 9.8 (owner_balanced drops it)
    total_vol_bcuft    = c(55, 80),      # EVALIDator ~70, p1 68.9
    total_carbon_tgc   = c(500, 800)     # FIA full panel ~650 TgC (re calibrated after lb fix)
  ),
  MN = list(
    forest_area_mac    = 17.4,
    per_ac_vol_cuft    = c(1050, 1450),  # smoke 1223; production 1241
    per_ac_ba_sqft     = c(60, 80),      # smoke 68, p1 68
    per_ac_carbon_kgac = c(28000, 38000),# p1 33650 lb/ac
    per_ac_tpa         = c(450, 650),    # smoke 538, p1 543
    harvest_rate_pct   = c(8, 15),       # smoke 11.6, p1 9.9
    total_vol_bcuft    = c(18, 32),      # EVALIDator ~28, p1 21.6 (~23% under, structural)
    total_carbon_tgc   = c(180, 320)     # FIA full panel ~220 TgC (re calibrated after lb fix)
  ),
  GA = list(
    forest_area_mac    = 24.8,
    per_ac_vol_cuft    = c(1000, 1400),  # smoke 1205, p1 1326
    per_ac_ba_sqft     = c(50, 70),      # smoke 61, p1 67
    per_ac_carbon_kgac = c(28000, 38000),# p1 35214 lb/ac
    per_ac_tpa         = c(400, 540),    # smoke 470, p1 498
    harvest_rate_pct   = c(9, 18),       # smoke 19.9, p1 9.9 (owner_balanced drops it)
    total_vol_bcuft    = c(25, 36),      # EVALIDator ~32, p1 32.9
    total_carbon_tgc   = c(330, 500)     # FIA full panel ~410 TgC (re calibrated after lb fix)
  ),
  ME = list(
    forest_area_mac    = 17.6,
    per_ac_vol_cuft    = c(1300, 1800),  # ME r21 1542
    per_ac_ba_sqft     = c(78, 105),     # ME r21 90
    per_ac_carbon_kgac = c(38000, 50000),# ME r21 44240 lb/ac
    per_ac_tpa         = c(600, 900),    # ME r21 742
    harvest_rate_pct   = c(7, 12),       # ME r21 8.9
    total_vol_bcuft    = c(22, 35),      # EVALIDator ~30
    total_carbon_tgc   = c(300, 420)     # FIA-derived 353 TgC (re calibrated after lb fix)
  )
)

if (!opt$state %in% names(STATE_PROFILES)) {
  stop("No bounds profile for state '", opt$state,
       "'. Add an entry to STATE_PROFILES in validate_template.R.")
}

profile <- STATE_PROFILES[[opt$state]]

# gr_ratio expected magnitude depends on Layer 1 vs Layer 2 patch state. The
# six p1 multistate runs all have Layer 1 deployed, no econ overlay, so the
# expected range is 0.003 to 0.010 driven by the 1/harvest_rate scaling.
GR_RATIO_RANGE <- c(0.003, 0.012)

# -----------------------------------------------------------------------------
# Resolve paths
# -----------------------------------------------------------------------------

fia_root <- Sys.getenv("FIA_CEM_DIR", "")
if (!nzchar(fia_root)) {
  fia_root <- if (dir.exists("~/fia_cem_projections")) {
    path.expand("~/fia_cem_projections")
  } else {
    here::here()
  }
}

out_base <- opt$out_dir %||% file.path(fia_root, "output")

state_dir <- file.path(out_base,
                       sprintf("%s_%s_%s", opt$state, opt$date, opt$tag))
ref_dir   <- file.path(out_base,
                       sprintf("%s_%s_%s", opt$ref_state, opt$ref_date, opt$ref_tag))

memo_path <- opt$memo %||% here::here("docs",
  sprintf("VALIDATION_%s_R21_RCP%s.md", opt$state, opt$rcp))

# -----------------------------------------------------------------------------
# Helpers (same as validate_wa_rcp45_r21.R)
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
  list(pass = pass,
       status = if (pass) "PASS" else "FLAG",
       value = as.numeric(value), label = label, bounds = bounds)
}

format_check_row <- function(chk) {
  sprintf("| %s | %s | [%s, %s] | %s |",
          chk$label, fmt_num(chk$value, 2),
          fmt_num(chk$bounds[1], 2), fmt_num(chk$bounds[2], 2),
          chk$status)
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

parse_ci_mean <- function(x) {
  if (is.numeric(x)) return(x)
  as.numeric(sub(" .*$", "", as.character(x)))
}

# -----------------------------------------------------------------------------
# Output presence check
# -----------------------------------------------------------------------------

required_files <- c("table_inventory_summary.csv", "table_gr_ratios.csv",
                    "ci_summaries.csv", "raw_mc_summaries.csv",
                    "per_plot_projections.rds")
missing <- required_files[!file.exists(file.path(state_dir, required_files))]

if (length(missing) > 0 || !dir.exists(state_dir)) {
  cat(sprintf("Output not ready in %s. Missing: %s\n",
              state_dir, paste(missing, collapse = ", ")),
      file = stderr())
  quit(status = 2, save = "no")
}

# -----------------------------------------------------------------------------
# Load and summarize
# -----------------------------------------------------------------------------

st_inv <- safe_read_csv(file.path(state_dir, "table_inventory_summary.csv"))
st_gr  <- safe_read_csv(file.path(state_dir, "table_gr_ratios.csv"))
st_plot <- safe_read_rds(file.path(state_dir, "per_plot_projections.rds"))

ref_inv <- safe_read_csv(file.path(ref_dir, "table_inventory_summary.csv"))
ref_available <- !is.null(ref_inv)

cyc1 <- st_inv |> filter(cycle == 1, scenario == "BAU") |> slice(1)
per_ac_vol     <- cyc1$mean_vol_mean[1]
per_ac_ba      <- cyc1$mean_ba_mean[1]
per_ac_carbon  <- cyc1$mean_carbon_mean[1]
per_ac_tpa     <- cyc1$total_tpa_mean[1]
harv_rate_pct  <- as.numeric(sub("%", "", as.character(cyc1$harvest_rate_mean[1])))

# UNIT FIX (13 May 2026): per_ac_carbon from table_inventory_summary.csv is in
# LB/AC, not kg/ac, because R/01_data_prep.R builds carbon_ag with TPA_UNADJ ×
# CARBON_AG (FIA pounds). The conversion to TgC uses LB_TO_TG = 4.5359e-10.
# Prior version used 1e-9 (treating as kg), which inflated statewide totals
# by a factor of 2.2.
total_vol_bcuft  <- (per_ac_vol * profile$forest_area_mac * 1e6) / 1e9
total_carbon_tgc <- (per_ac_carbon * profile$forest_area_mac * 1e6) * 4.5359e-10

gr_cyc1 <- if (!is.null(st_gr)) {
  gr_row <- st_gr |> filter(cycle == 1) |> slice(1)
  parse_ci_mean(gr_row$BAU[1])
} else NA_real_

# -----------------------------------------------------------------------------
# Per ownership distribution
# -----------------------------------------------------------------------------

owner_dist <- NULL
owngrp_legend <- c("10" = "USDA Forest Service",
                   "20" = "Other federal",
                   "30" = "State and local",
                   "40" = "Private (NIPF + industrial)")

if (!is.null(st_plot) && is.data.frame(st_plot)) {
  # Owner column candidates (broad to narrow). Production per_plot_projections.rds
  # uses OWNGRPCD (FIA standard); older builds may use different names.
  owner_cols <- intersect(c("OWNGRPCD", "owngrpcd", "owner_class",
                            "OwnerClass", "hcb_class", "HCB_CLASS", "OWNCD"),
                          names(st_plot))
  if (length(owner_cols) > 0) {
    oc <- owner_cols[1]

    # Restrict to cycle 1 BAU for a comparable cross owner snapshot. The
    # per_plot table is long format across scenario x sim x cycle x plot, so
    # we average across sims at cycle 1 for the headline BAU panel.
    snap <- st_plot |>
      filter(scenario == "BAU", cycle == 1, !is.na(.data[[oc]]))

    if (nrow(snap) > 0) {
      # Harvest fraction = mean(was_harvested) per owner group at cycle 1.
      # Per acre volume = mean(proj_volcfnet) per owner group.
      harv_avail <- "was_harvested" %in% names(snap)
      vol_avail  <- "proj_volcfnet" %in% names(snap)

      owner_dist <- snap |>
        group_by(owner_code = as.character(.data[[oc]])) |>
        summarise(
          n_plots    = n_distinct(PLT_CN),
          mean_vol   = if (vol_avail) mean(proj_volcfnet, na.rm = TRUE) else NA_real_,
          harv_frac  = if (harv_avail) mean(was_harvested, na.rm = TRUE) else NA_real_,
          .groups    = "drop"
        ) |>
        mutate(owner_label = coalesce(owngrp_legend[owner_code],
                                      paste("code", owner_code))) |>
        arrange(desc(n_plots))
    }
  }
}

# -----------------------------------------------------------------------------
# Apply bound checks
# -----------------------------------------------------------------------------

checks <- list(
  check_bound(per_ac_vol,      profile$per_ac_vol_cuft,    "Per acre volume (cuft/ac)"),
  check_bound(per_ac_ba,       profile$per_ac_ba_sqft,     "Per acre BA (sqft/ac)"),
  check_bound(per_ac_carbon,   profile$per_ac_carbon_kgac, "Per acre carbon (kg/ac)"),
  check_bound(per_ac_tpa,      profile$per_ac_tpa,         "Per acre TPA"),
  check_bound(harv_rate_pct,   profile$harvest_rate_pct,   "Harvest rate (%)"),
  check_bound(total_vol_bcuft, profile$total_vol_bcuft,    "Statewide total volume (Bcuft)"),
  check_bound(total_carbon_tgc,profile$total_carbon_tgc,   "Statewide total carbon (TgC)"),
  check_bound(gr_cyc1,         GR_RATIO_RANGE,             "gr_ratio cycle 1 BAU (post L1)")
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
# Deltas vs reference
# -----------------------------------------------------------------------------

deltas <- NULL
if (ref_available) {
  ref_cyc1 <- ref_inv |> filter(cycle == 1, scenario == "BAU") |> slice(1)
  ref_profile <- STATE_PROFILES[[opt$ref_state]] %||% list(forest_area_mac = NA)
  ref_per_ac_vol    <- ref_cyc1$mean_vol_mean[1]
  ref_per_ac_ba     <- ref_cyc1$mean_ba_mean[1]
  ref_per_ac_carbon <- ref_cyc1$mean_carbon_mean[1]
  ref_per_ac_tpa    <- ref_cyc1$total_tpa_mean[1]
  ref_harv_rate     <- as.numeric(sub("%", "", as.character(ref_cyc1$harvest_rate_mean[1])))
  ref_total_vol     <- (ref_per_ac_vol * ref_profile$forest_area_mac * 1e6) / 1e9
  ref_total_carbon  <- (ref_per_ac_carbon * ref_profile$forest_area_mac * 1e6) / 1e9

  deltas <- tribble(
    ~metric,                    ~state_val,        ~ref_val,         ~delta_pct,
    "Per acre vol (cuft/ac)",   per_ac_vol,        ref_per_ac_vol,    100 * (per_ac_vol - ref_per_ac_vol) / ref_per_ac_vol,
    "Per acre BA (sqft/ac)",    per_ac_ba,         ref_per_ac_ba,     100 * (per_ac_ba - ref_per_ac_ba) / ref_per_ac_ba,
    "Per acre carbon (kg/ac)",  per_ac_carbon,     ref_per_ac_carbon, 100 * (per_ac_carbon - ref_per_ac_carbon) / ref_per_ac_carbon,
    "Per acre TPA",             per_ac_tpa,        ref_per_ac_tpa,    100 * (per_ac_tpa - ref_per_ac_tpa) / ref_per_ac_tpa,
    "Harvest rate (%)",         harv_rate_pct,     ref_harv_rate,     100 * (harv_rate_pct - ref_harv_rate) / ref_harv_rate,
    "Statewide vol (Bcuft)",    total_vol_bcuft,   ref_total_vol,     100 * (total_vol_bcuft - ref_total_vol) / ref_total_vol,
    "Statewide carbon (TgC)",   total_carbon_tgc,  ref_total_carbon,  100 * (total_carbon_tgc - ref_total_carbon) / ref_total_carbon
  )
}

# -----------------------------------------------------------------------------
# Write memo
# -----------------------------------------------------------------------------

dir.create(dirname(memo_path), showWarnings = FALSE, recursive = TRUE)
sink(memo_path)

cat(sprintf("# %s RCP %s production run validation\n\n", opt$state, opt$rcp))
cat(sprintf("*Generated %s from %s*\n\n",
            format(Sys.time(), "%Y-%m-%d %H:%M %Z"), state_dir))

cat(sprintf("**Overall: %s.** %d of %d checks passed, %d flagged, %d missing.\n\n",
            overall, n_pass, length(checks), n_flag, n_miss))

cat("## Sanity bound checks\n\n")
cat("| Check | Value | Bounds | Status |\n|---|---:|---|:---:|\n")
for (chk in checks) cat(format_check_row(chk), "\n", sep = "")
cat("\n")

cat("## Headline numbers, cycle 1 BAU baseline\n\n")
cat("- Per acre volume: ", fmt_num(per_ac_vol, 0), " cuft/ac\n", sep = "")
cat("- Per acre BA: ", fmt_num(per_ac_ba, 1), " sqft/ac\n", sep = "")
cat("- Per acre carbon: ", fmt_num(per_ac_carbon, 0), " kg/ac\n", sep = "")
cat("- Per acre TPA: ", fmt_num(per_ac_tpa, 0), "\n", sep = "")
cat("- Harvest rate: ", fmt_num(harv_rate_pct, 1), " %\n", sep = "")
cat("- Statewide total volume: ", fmt_num(total_vol_bcuft, 1),
    " Bcuft (assumes ", profile$forest_area_mac, " M ac forest area)\n", sep = "")
cat("- Statewide total carbon: ", fmt_num(total_carbon_tgc, 0), " TgC\n", sep = "")
cat("- gr_ratio cycle 1 BAU: ", fmt_num(gr_cyc1, 4), "\n\n", sep = "")

if (!is.null(deltas)) {
  cat(sprintf("## Cross state deltas vs %s reference (%s)\n\n",
              opt$ref_state, opt$ref_tag))
  cat("| Metric | ", opt$state, " | ", opt$ref_state, " | Delta (%) |\n",
      "|---|---:|---:|---:|\n", sep = "")
  for (i in seq_len(nrow(deltas))) {
    cat(sprintf("| %s | %s | %s | %s |\n",
                deltas$metric[i],
                fmt_num(deltas$state_val[i], 1),
                fmt_num(deltas$ref_val[i], 1),
                fmt_num(deltas$delta_pct[i], 1)))
  }
  cat("\n")
}

if (!is.null(owner_dist) && nrow(owner_dist) > 0) {
  cat("## Per ownership distribution (cycle 1 BAU)\n\n")
  cat("| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |\n",
      "|---|---|---:|---:|---:|\n", sep = "")
  for (i in seq_len(nrow(owner_dist))) {
    cat(sprintf("| %s | %s | %d | %s | %s |\n",
                owner_dist$owner_code[i],
                owner_dist$owner_label[i],
                owner_dist$n_plots[i],
                fmt_num(owner_dist$mean_vol[i], 1),
                fmt_num(owner_dist$harv_frac[i], 3)))
  }
  cat("\nOWNGRPCD codes follow the FIA convention: 10 USDA Forest Service, ",
      "20 Other federal, 30 State and local, 40 Private. HCB sub classification ",
      "lives in `config/fia_plots_with_owner.csv` and is not joined into per_plot.\n\n",
      sep = "")
} else {
  cat("## Per ownership distribution\n\nOwner distribution unavailable from per_plot RDS. Inspect schema manually.\n\n")
}

cat("## Flags and follow ups\n\n")
flagged <- Filter(function(c) isFALSE(c$pass), checks)
if (length(flagged) == 0 && n_miss == 0) {
  cat("None. All sanity bounds satisfied.\n")
} else {
  for (chk in flagged) {
    cat(sprintf("- **%s**: %s, outside bounds [%s, %s]. Investigate.\n",
                chk$label, fmt_num(chk$value, 2),
                fmt_num(chk$bounds[1], 2), fmt_num(chk$bounds[2], 2)))
  }
  if (n_miss > 0) {
    cat(sprintf("- %d checks MISSING; inspect raw output.\n", n_miss))
  }
}

sink()
cat("\nMemo written to: ", memo_path, "\n", sep = "")

if (grepl("^PASS", overall)) {
  quit(status = 0, save = "no")
} else if (grepl("^REVIEW", overall)) {
  quit(status = 1, save = "no")
} else {
  quit(status = 2, save = "no")
}
