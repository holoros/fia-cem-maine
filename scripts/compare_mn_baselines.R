#!/usr/bin/env Rscript
# =============================================================================
# scripts/compare_mn_baselines.R
#
# Compares MN p1 1999 baseline output vs the MN 2004 baseline diagnostic
# (SLURM 9676388) to test whether the -23 percent statewide volume undercount
# is fully attributable to the DESIGNCD periodic plot exclusion described in
# docs/MN_VOLUME_GAP_ROOT_CAUSE_20260516.md.
#
# Outputs:
#   figures/mn_baseline_comparison.png      Statewide vol + AGC trajectories
#   figures/mn_baseline_comparison.csv      Per cycle delta and EVALIDator gap
#
# Run on Cardinal after job 9676388 finishes:
#   Rscript scripts/compare_mn_baselines.R
#
# Or with custom date:
#   Rscript scripts/compare_mn_baselines.R --diag_date 20260517
#
# Author: Aaron Weiskittel (built 16 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

args <- commandArgs(trailingOnly = TRUE)
arg_or <- function(flag, default) {
  i <- which(args == flag)
  if (length(i) > 0) args[i + 1] else default
}

diag_date <- arg_or("--diag_date", "20260516")
p1_date   <- arg_or("--p1_date",   "20260510")

fia_root <- Sys.getenv("FIA_CEM_DIR", "")
if (!nzchar(fia_root)) {
  fia_root <- if (dir.exists("~/fia_cem_projections")) {
    path.expand("~/fia_cem_projections")
  } else here::here()
}

LB_TO_TGC <- 4.53592e-10
MN_AREA_MAC <- 17.4

# EVALIDator MN targets (subject to verification against official tables)
MN_EVAL_VOL_BCUFT <- 28.0
MN_EVAL_AGC_TGC   <- 220     # FIA full panel from this session's hindcast obs_full

pub_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text       = element_text(face = "bold"),
        legend.position  = "bottom",
        plot.title       = element_text(face = "bold", size = 12),
        plot.subtitle    = element_text(size = 10, colour = "grey30"))

# -----------------------------------------------------------------------------
# Load both runs
# -----------------------------------------------------------------------------

load_run <- function(path, label, baseline_year) {
  if (!file.exists(path)) {
    warning("Missing: ", path)
    return(NULL)
  }
  read_csv(path, show_col_types = FALSE) |>
    mutate(
      run_label     = label,
      baseline_year = baseline_year,
      year_proj     = baseline_year + cycle * 5,
      statewide_agc_tgc   = mean_carbon_mean * MN_AREA_MAC * 1e6 * LB_TO_TGC,
      statewide_vol_bcuft = mean_vol_mean    * MN_AREA_MAC * 1e6 / 1e9
    )
}

p1_path <- file.path(fia_root, "output",
                      sprintf("MN_%s_rcp45_wear_p1", p1_date),
                      "ci_summaries.csv")
diag_path <- file.path(fia_root, "output",
                       sprintf("MN_%s_rcp45_wear_p1_2004base", diag_date),
                       "ci_summaries.csv")

p1   <- load_run(p1_path,   "MN p1 (1999 baseline)", 1999)
diag <- load_run(diag_path, "MN diagnostic (2004 baseline)", 2004)

if (is.null(p1) || is.null(diag)) {
  cat("\nOne or both runs not available yet.\n")
  cat("p1 path:   ", p1_path, "\n")
  cat("diag path: ", diag_path, "\n")
  cat("\nIf diagnostic hasn't landed, check: sacct -j 9676388 --format=JobID,State,Elapsed\n")
  quit(status = 1, save = "no")
}

both <- bind_rows(p1, diag) |>
  mutate(run_label = factor(run_label,
                            levels = c("MN p1 (1999 baseline)",
                                       "MN diagnostic (2004 baseline)")))

cat(sprintf("Loaded %d rows: %d p1 + %d diagnostic\n",
            nrow(both), nrow(p1), nrow(diag)))

# -----------------------------------------------------------------------------
# Cycle 1 comparison (the diagnostic question)
# -----------------------------------------------------------------------------

cycle1 <- both |>
  filter(scenario == "BAU", cycle == 1) |>
  select(run_label, baseline_year, year_proj,
         mean_vol_mean, statewide_vol_bcuft,
         mean_carbon_mean, statewide_agc_tgc)

cat("\n=== Cycle 1 BAU comparison ===\n")
print(cycle1)

cat(sprintf("\nEVALIDator MN target: %.0f Bcuft, %.0f TgC (FIA full panel observed)\n",
            MN_EVAL_VOL_BCUFT, MN_EVAL_AGC_TGC))

p1_gap <- cycle1$statewide_vol_bcuft[cycle1$baseline_year == 1999] - MN_EVAL_VOL_BCUFT
diag_gap <- cycle1$statewide_vol_bcuft[cycle1$baseline_year == 2004] - MN_EVAL_VOL_BCUFT
cat(sprintf("\np1 1999 baseline gap:        %+.1f Bcuft (%.0f%% of EVALIDator)\n",
            p1_gap, 100 * cycle1$statewide_vol_bcuft[cycle1$baseline_year == 1999] / MN_EVAL_VOL_BCUFT))
cat(sprintf("Diagnostic 2004 baseline gap: %+.1f Bcuft (%.0f%% of EVALIDator)\n",
            diag_gap, 100 * cycle1$statewide_vol_bcuft[cycle1$baseline_year == 2004] / MN_EVAL_VOL_BCUFT))

# -----------------------------------------------------------------------------
# Figure: trajectories
# -----------------------------------------------------------------------------

fig <- both |>
  filter(scenario == "BAU") |>
  pivot_longer(cols = c(statewide_vol_bcuft, statewide_agc_tgc),
               names_to = "metric", values_to = "value") |>
  mutate(metric_label = if_else(metric == "statewide_vol_bcuft",
                                "Statewide volume (Bcuft)",
                                "Statewide carbon (TgC)")) |>
  ggplot(aes(x = year_proj, y = value,
             colour = run_label, group = run_label)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.3) +
  geom_hline(data = tibble(metric_label = c("Statewide volume (Bcuft)",
                                            "Statewide carbon (TgC)"),
                            value = c(MN_EVAL_VOL_BCUFT, MN_EVAL_AGC_TGC)),
             aes(yintercept = value),
             linetype = "dashed", colour = "grey50", linewidth = 0.5) +
  facet_wrap(~ metric_label, scales = "free_y", ncol = 2) +
  scale_colour_brewer(palette = "Set1") +
  labs(title    = "MN baseline comparison: 1999 (p1) vs 2004 diagnostic",
       subtitle = "Dashed grey: EVALIDator and FIA full panel observed targets.",
       x = "Projection year", y = NULL,
       colour = "Run") +
  pub_theme

dir.create(here::here("figures"), showWarnings = FALSE, recursive = TRUE)
ggsave(here::here("figures", "mn_baseline_comparison.png"),
       fig, width = 11, height = 5, dpi = 200, bg = "white")
cat("\n  Wrote figures/mn_baseline_comparison.png\n")

# -----------------------------------------------------------------------------
# Summary CSV
# -----------------------------------------------------------------------------

summary_tbl <- both |>
  filter(scenario == "BAU") |>
  select(run_label, baseline_year, cycle, year_proj,
         statewide_vol_bcuft, statewide_agc_tgc) |>
  arrange(run_label, cycle)

write_csv(summary_tbl, here::here("figures", "mn_baseline_comparison.csv"))
cat("  Wrote figures/mn_baseline_comparison.csv\n")

# -----------------------------------------------------------------------------
# Interpretation
# -----------------------------------------------------------------------------

cat("\n=== Interpretation ===\n")
if (abs(diag_gap) < 0.15 * MN_EVAL_VOL_BCUFT) {
  cat("PASS: 2004 baseline brings MN within 15 percent of EVALIDator.\n")
  cat("  This confirms the DESIGNCD periodic plot exclusion (1999 baseline) is\n")
  cat("  the dominant driver of the p1 -23 percent gap. For manuscript:\n")
  cat("    - Report MN p1 1999 baseline result with known limitation\n")
  cat("    - Cross reference the 2004 baseline diagnostic as remediation option\n")
} else {
  cat("REVIEW: 2004 baseline still has a meaningful gap to EVALIDator.\n")
  cat("  The DESIGNCD filter is contributory but not the sole cause. Possible\n")
  cat("  additional mechanisms: (1) HCB owner downscale, (2) MN-specific climate\n")
  cat("  response gating, (3) Lake States donor pool composition.\n")
}
