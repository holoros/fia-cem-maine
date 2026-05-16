#!/usr/bin/env Rscript
# =============================================================================
# scripts/hindcast_multistate.R
#
# Multistate subject matched hindcast. Adapts scripts/build_subject_matched_cv.R
# from Maine to any state, then computes a comparison table against the p1
# projection cycles.
#
# For each state, this script:
#   1. Loads the cycle 1 subject plot list from output/<STATE>_<date>_<tag>/per_plot_projections.rds
#   2. Loads per state FIA TREE, COND, PLOT, POP_PLOT_STRATUM_ASSGN, POP_STRATUM, POP_EVAL, POP_EVAL_TYP
#   3. Computes observed AGC for each EXPALL EVALID using the standard EXPNS expansion,
#      restricted to the intersection of subject plots and the EVALID's plot list
#   4. Computes projected AGC for each cycle by joining per plot proj_carbon to the
#      same EXPNS factors (using the most recent EVALID as a representative weight)
#   5. Matches projection cycles to EVALID years (cycle 1 = baseline + 5, etc.)
#   6. Writes a hindcast table with year, observed, projected, residual, plus
#      summary RMSE and bias rows
#
# Usage:
#   Rscript scripts/hindcast_multistate.R --state WA --tag rcp45_wear_p1 --date 20260510
#   Rscript scripts/hindcast_multistate.R --state MN --tag rcp45_wear_p1 --date 20260510
#
# Output:
#   output/hindcast/HINDCAST_<STATE>_<tag>.csv
#   docs/HINDCAST_<STATE>_<TAG>.md (memo)
#
# Author: Aaron Weiskittel (built 13 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(optparse)
  library(here)
})

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------

option_list <- list(
  make_option("--state",     type = "character", default = NULL,
              help = "State postal code (WA, MN, GA, ME). Required."),
  make_option("--tag",       type = "character", default = "rcp45_wear_p1",
              help = "Output dir tag. Default rcp45_wear_p1."),
  make_option("--date",      type = "character", default = "20260510",
              help = "Output dir date stamp. Default 20260510."),
  make_option("--fia_dir",   type = "character", default = "~/fia_data",
              help = "FIA per state CSV dir. Default ~/fia_data."),
  make_option("--baseline_year", type = "integer", default = 1999,
              help = "Baseline year (cycle 1 corresponds to baseline + 5)."),
  make_option("--out_dir",   type = "character", default = NULL,
              help = "Output base. Default ~/fia_cem_projections/output.")
)
opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$state)) stop("--state is required.")
opt$state <- toupper(opt$state)

STATE_CODES <- c(WA = 53L, MN = 27L, GA = 13L, ME = 23L)
if (!opt$state %in% names(STATE_CODES)) stop("Unknown state: ", opt$state)
state_cd <- STATE_CODES[[opt$state]]

# Cycle length in years
CYCLE_YEARS <- 5L

# Unit conversions
# CRITICAL: proj_carbon column in per_plot_projections.rds is in LB/AC, not
# kg/ac, because R/01_data_prep.R builds carbon_ag = sum(TPA_UNADJ * CARBON_AG)
# where CARBON_AG is in pounds per tree (FIA convention). The same conversion
# factor applies to both observed and projected. Earlier versions of this
# script used 1e-9 for the projection, treating it as kg, which produced a
# spurious 2.2x over prediction. See VALIDATION_SYNTHESIS_20260513.md for the
# investigation history.
LB_TO_MMT <- 4.53592e-10

# -----------------------------------------------------------------------------
# Resolve paths
# -----------------------------------------------------------------------------

fia_root <- Sys.getenv("FIA_CEM_DIR", "~/fia_cem_projections")
out_base <- opt$out_dir %||% file.path(fia_root, "output")
state_dir <- file.path(out_base,
                       sprintf("%s_%s_%s", opt$state, opt$date, opt$tag))

rds_file <- file.path(state_dir, "per_plot_projections.rds")
if (!file.exists(rds_file)) stop("per_plot RDS not found: ", rds_file)

fia_dir <- path.expand(opt$fia_dir)

out_csv  <- file.path(fia_root, "output", "hindcast",
                       sprintf("HINDCAST_%s_%s.csv", opt$state, opt$tag))
out_memo <- file.path(fia_root, "docs",
                       sprintf("HINDCAST_%s_%s.md", opt$state, toupper(opt$tag)))
dir.create(dirname(out_csv),  showWarnings = FALSE, recursive = TRUE)
dir.create(dirname(out_memo), showWarnings = FALSE, recursive = TRUE)

cat(sprintf("State: %s (STATECD %d)\n", opt$state, state_cd))
cat(sprintf("Projection RDS: %s\n", rds_file))
cat(sprintf("FIA dir: %s\n\n", fia_dir))

# -----------------------------------------------------------------------------
# Load projection RDS, extract subject plots and per cycle projected AGC
# -----------------------------------------------------------------------------

cat("Loading per_plot RDS...\n")
t0 <- Sys.time()
d <- readRDS(rds_file)
cat(sprintf("  %d rows, %d cols, loaded in %.1f sec\n",
            nrow(d), ncol(d), as.numeric(Sys.time() - t0, units = "secs")))

# Filter to this state's BAU scenario for the hindcast comparison
d <- d |> filter(STATECD == state_cd, scenario == "BAU")
cat(sprintf("  After state + BAU filter: %d rows\n", nrow(d)))

# Subject plots = unique cycle 1 PLT_CN
subj_plots <- unique(format(d$PLT_CN[d$cycle == 1L],
                             scientific = FALSE, trim = TRUE))
cat(sprintf("Subject plot count (cycle 1 PLT_CN): %d\n\n", length(subj_plots)))

# Per cycle projected AGC at the plot level (mean across sims first, then aggregate)
proj_per_plot <- d |>
  group_by(PLT_CN, CONDID, cycle, CONDPROP_UNADJ) |>
  summarise(proj_carbon_lbac = mean(proj_carbon, na.rm = TRUE),
            .groups = "drop") |>
  mutate(PLT_CN_chr = format(PLT_CN, scientific = FALSE, trim = TRUE))

rm(d); gc()

cat(sprintf("Aggregated projection: %d plot x condition x cycle rows\n\n",
            nrow(proj_per_plot)))

# -----------------------------------------------------------------------------
# Load FIA tables for this state
# -----------------------------------------------------------------------------

cat("Loading FIA tables...\n")
t0 <- Sys.time()

tre_path <- file.path(fia_dir, sprintf("%s_TREE.csv", opt$state))
cnd_path <- file.path(fia_dir, sprintf("%s_COND.csv", opt$state))
plt_path <- file.path(fia_dir, sprintf("%s_PLOT.csv", opt$state))
ppsa_path <- file.path(fia_dir, sprintf("%s_POP_PLOT_STRATUM_ASSGN.csv", opt$state))
ps_path  <- file.path(fia_dir, sprintf("%s_POP_STRATUM.csv", opt$state))
pe_path  <- file.path(fia_dir, sprintf("%s_POP_EVAL.csv", opt$state))
pet_path <- file.path(fia_dir, sprintf("%s_POP_EVAL_TYP.csv", opt$state))

tre <- fread(tre_path,
             select = c("PLT_CN","CONDID","STATUSCD","DIA","TPA_UNADJ",
                        "CARBON_AG"),
             colClasses = list(character = "PLT_CN"))
cnd <- fread(cnd_path,
             select = c("PLT_CN","CONDID","CONDPROP_UNADJ","COND_STATUS_CD"),
             colClasses = list(character = "PLT_CN"))
ppsa <- fread(ppsa_path, colClasses = list(character = c("PLT_CN","STRATUM_CN")))
ps   <- fread(ps_path,   colClasses = list(character = "CN"))
pe   <- fread(pe_path,   colClasses = list(character = "CN"))
pet  <- fread(pet_path,  colClasses = list(character = "EVAL_CN"))

cat(sprintf("  TREE %d rows, COND %d rows, PPSA %d rows, loaded in %.1f sec\n",
            nrow(tre), nrow(cnd), nrow(ppsa),
            as.numeric(Sys.time() - t0, units = "secs")))

# -----------------------------------------------------------------------------
# Per condition observed AGC (live trees, DIA >= 1.0)
# -----------------------------------------------------------------------------

cond_agc <- tre[STATUSCD == 1 & DIA >= 1.0,
                .(carbon_per_ac = sum(TPA_UNADJ * CARBON_AG, na.rm = TRUE)),
                by = .(PLT_CN, CONDID)]
cond_agc <- cnd[COND_STATUS_CD == 1, .(PLT_CN, CONDID, CONDPROP_UNADJ)][
  cond_agc, on = c("PLT_CN","CONDID"), nomatch = NULL]
rm(tre); gc()

# -----------------------------------------------------------------------------
# Pull EXPALL EVALIDs and EXPNS factors
# -----------------------------------------------------------------------------

evt <- merge(pet[, .(EVAL_CN, EVAL_TYP)],
             pe[, .(CN, EVALID, END_INVYR)],
             by.x = "EVAL_CN", by.y = "CN")
evt <- evt[EVAL_TYP == "EXPALL"][order(END_INVYR)]
cat(sprintf("\nEXPALL EVALIDs: %d (years %d to %d)\n",
            nrow(evt), min(evt$END_INVYR), max(evt$END_INVYR)))

# -----------------------------------------------------------------------------
# Per EVALID: observed full panel AGC, observed subject AGC, projected AGC
# matched to the cycle that aligns with END_INVYR
# -----------------------------------------------------------------------------

cat("\nComputing per EVALID observed vs projected AGC...\n")

results <- map_dfr(seq_len(nrow(evt)), function(i) {
  e <- evt[i, ]

  expns_e <- ppsa[EVALID == e$EVALID][ps, on = c("STRATUM_CN" = "CN"),
                                       nomatch = NULL]
  expns_e <- unique(expns_e[, .(PLT_CN = as.character(PLT_CN), EXPNS)],
                    by = "PLT_CN")

  # Observed AGC, full panel
  obs_full <- cond_agc[expns_e, on = "PLT_CN", nomatch = NULL]
  obs_full_agc <- sum(obs_full$carbon_per_ac * obs_full$CONDPROP_UNADJ *
                       obs_full$EXPNS, na.rm = TRUE) * LB_TO_MMT

  # Observed AGC, subject only (intersection of subject plot list and EVALID plots)
  obs_subj <- obs_full[PLT_CN %in% subj_plots]
  obs_subj_agc <- sum(obs_subj$carbon_per_ac * obs_subj$CONDPROP_UNADJ *
                       obs_subj$EXPNS, na.rm = TRUE) * LB_TO_MMT

  # Match this EVALID year to a projection cycle.
  # Baseline year + cycle * CYCLE_YEARS == END_INVYR  =>  cycle = (END_INVYR - baseline) / 5
  cycle_match <- (e$END_INVYR - opt$baseline_year) / CYCLE_YEARS
  cycle_match <- if (cycle_match == round(cycle_match) &&
                     cycle_match >= 1 && cycle_match <= 15) {
    as.integer(round(cycle_match))
  } else NA_integer_

  proj_agc <- NA_real_
  if (!is.na(cycle_match)) {
    pj <- proj_per_plot |>
      filter(cycle == cycle_match) |>
      inner_join(expns_e, by = c("PLT_CN_chr" = "PLT_CN"))
    proj_agc <- sum(pj$proj_carbon_lbac * pj$CONDPROP_UNADJ * pj$EXPNS,
                     na.rm = TRUE) * LB_TO_MMT
  }

  data.frame(
    year                  = as.integer(e$END_INVYR),
    EVALID                = e$EVALID,
    cycle_match           = cycle_match,
    n_full_plots          = nrow(expns_e),
    n_subj_plots_in_eval  = sum(expns_e$PLT_CN %in% subj_plots),
    obs_full_agc_mmt      = round(obs_full_agc, 1),
    obs_subj_agc_mmt      = round(obs_subj_agc, 1),
    proj_subj_agc_mmt     = round(proj_agc, 1),
    residual_mmt          = round(proj_agc - obs_subj_agc, 1)
  )
})

# Summary stats: RMSE and bias over years with matched projections
matched <- results[!is.na(results$cycle_match) & !is.na(results$proj_subj_agc_mmt), ]
rmse <- if (nrow(matched) > 0) {
  sqrt(mean((matched$residual_mmt)^2, na.rm = TRUE))
} else NA_real_
bias <- if (nrow(matched) > 0) {
  mean(matched$residual_mmt, na.rm = TRUE)
} else NA_real_

# -----------------------------------------------------------------------------
# Write outputs
# -----------------------------------------------------------------------------

fwrite(results, out_csv)
cat(sprintf("\nWrote %s\n", out_csv))

# Markdown memo
sink(out_memo)
cat(sprintf("# Hindcast validation: %s %s\n\n", opt$state, toupper(opt$tag)))
cat(sprintf("*Generated %s from %s*\n\n",
            format(Sys.time(), "%Y-%m-%d %H:%M %Z"), state_dir))

cat("## Summary\n\n")
cat(sprintf("- Subject plot count (cycle 1): %d\n", length(subj_plots)))
cat(sprintf("- EXPALL EVALIDs analyzed: %d\n", nrow(results)))
cat(sprintf("- Year range: %d to %d\n",
            min(results$year), max(results$year)))
matched_years <- matched$year
if (length(matched_years) > 0) {
  cat(sprintf("- Years with projection match: %s\n",
              paste(matched_years, collapse = ", ")))
}
if (!is.na(rmse)) {
  cat(sprintf("- **RMSE: %.1f MMT AGC**\n", rmse))
  cat(sprintf("- **Bias: %+.1f MMT AGC** (projected minus observed)\n", bias))
  cat(sprintf("- RMSE as percent of observed mean: %.1f%%\n",
              100 * rmse / mean(matched$obs_subj_agc_mmt)))
  cat(sprintf("- Bias as percent of observed mean: %+.1f%%\n",
              100 * bias / mean(matched$obs_subj_agc_mmt)))
}
cat("\n")

cat("## Detail by EVALID\n\n")
cat("| Year | EVALID | Cycle | N full plots | N subj plots | Obs full (MMT) | Obs subj (MMT) | Proj subj (MMT) | Residual (MMT) |\n",
    "|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n", sep = "")
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  cat(sprintf("| %d | %s | %s | %d | %d | %.1f | %.1f | %s | %s |\n",
              r$year, as.character(r$EVALID),
              if (is.na(r$cycle_match)) "—" else as.character(r$cycle_match),
              r$n_full_plots, r$n_subj_plots_in_eval,
              r$obs_full_agc_mmt, r$obs_subj_agc_mmt,
              if (is.na(r$proj_subj_agc_mmt)) "—" else sprintf("%.1f", r$proj_subj_agc_mmt),
              if (is.na(r$residual_mmt)) "—" else sprintf("%+.1f", r$residual_mmt)))
}
cat("\n")

cat("## Interpretation\n\n")
if (!is.na(rmse)) {
  ref_mean <- mean(matched$obs_subj_agc_mmt)
  pct_rmse <- 100 * rmse / ref_mean
  pct_bias <- 100 * bias / ref_mean
  status <- if (pct_rmse < 10 && abs(pct_bias) < 5) {
    "Strong hindcast performance."
  } else if (pct_rmse < 20 && abs(pct_bias) < 10) {
    "Acceptable hindcast performance."
  } else {
    "Hindcast performance outside expected bounds; investigate."
  }
  cat(sprintf("%s RMSE of %.1f MMT is %.1f%% of the subject matched observed mean ",
              status, rmse, pct_rmse))
  cat(sprintf("(%.1f MMT). Bias of %+.1f MMT is %+.1f%% of the observed mean.\n\n",
              ref_mean, bias, pct_bias))

  cat("ME r11 hindcast (reference): RMSE 16 MMT AGC (6% of mean), bias -2 MMT (-1.1%).\n")
}
sink()
cat(sprintf("Wrote %s\n", out_memo))

print(results)
cat(sprintf("\nRMSE: %.1f MMT, Bias: %+.1f MMT\n",
            rmse %||% NA_real_, bias %||% NA_real_))
