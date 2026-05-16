#!/usr/bin/env Rscript
# =============================================================================
# scripts/compare_me_econ_vs_no_econ.R
#
# Compares the ME r21 economic projection (--use_maine_econ, post Layer 4
# patch) against the canonical ME r21 no econ baseline (--no_econ
# --skip_supply, from May 5 and May 8 production). Quantifies the effect of
# the economic harvest overlay on statewide AGC trajectories and harvest
# rate patterns.
#
# Reads ci_summaries.csv from:
#   output/ME_<DATE>_rcp45_hadgem2_wear_econ_r21/  (RCP 4.5 econ)
#   output/ME_<DATE>_rcp85_hadgem2_wear_econ_r21/  (RCP 8.5 econ)
#   output/ME_20260505_rcp45_hadgem2_wear_r21/      (RCP 4.5 no econ baseline)
#   output/ME_20260508_rcp85_hadgem2_wear_r21/      (RCP 8.5 no econ baseline)
#
# Output figures:
#   figures/me_r21_econ_vs_no_econ_carbon.png      AGC trajectory comparison
#   figures/me_r21_econ_vs_no_econ_harvest.png     Harvest rate trajectory comparison
#   figures/me_r21_econ_vs_no_econ_summary.csv     Per cycle metric deltas
#
# Usage (run on Cardinal where outputs land):
#   Rscript scripts/compare_me_econ_vs_no_econ.R
#   Rscript scripts/compare_me_econ_vs_no_econ.R --econ_date 20260517
#
# Author: Aaron Weiskittel (built 16 May 2026, ready for next session after
# ME econ reruns (SLURM 9674412, 9674413) finish)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
arg_or <- function(flag, default) {
  i <- which(args == flag)
  if (length(i) > 0) args[i + 1] else default
}

econ_date <- arg_or("--econ_date", "20260517")    # date stamp from the rerun
no_econ_45 <- arg_or("--no_econ_45_date", "20260505")
no_econ_85 <- arg_or("--no_econ_85_date", "20260508")

fia_root <- Sys.getenv("FIA_CEM_DIR", "")
if (!nzchar(fia_root)) {
  fia_root <- if (dir.exists("~/fia_cem_projections")) {
    path.expand("~/fia_cem_projections")
  } else here::here()
}

input_dir  <- file.path(fia_root, "output")
output_dir <- here::here("figures")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

CYCLE_TO_YEAR <- function(c) 1999 + c * 5
LB_TO_TGC <- 4.53592e-10
ME_AREA_MAC <- 17.6

pub_theme <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_rect(fill = "grey92", colour = NA),
        strip.text       = element_text(face = "bold"),
        legend.position  = "bottom",
        plot.title       = element_text(face = "bold", size = 12),
        plot.subtitle    = element_text(size = 10, colour = "grey30"))

# -----------------------------------------------------------------------------
# Load all four runs
# -----------------------------------------------------------------------------

load_run <- function(dir_name, rcp, has_econ) {
  path <- file.path(input_dir, dir_name, "ci_summaries.csv")
  if (!file.exists(path)) {
    warning(sprintf("Missing: %s", path))
    return(NULL)
  }
  read_csv(path, show_col_types = FALSE) |>
    mutate(rcp = rcp, has_econ = has_econ, run_dir = dir_name)
}

econ_45 <- load_run(sprintf("ME_%s_rcp45_hadgem2_wear_econ_r21", econ_date),
                     "RCP 4.5", "with econ")
econ_85 <- load_run(sprintf("ME_%s_rcp85_hadgem2_wear_econ_r21", econ_date),
                     "RCP 8.5", "with econ")
no_45   <- load_run(sprintf("ME_%s_rcp45_hadgem2_wear_r21", no_econ_45),
                     "RCP 4.5", "no econ")
no_85   <- load_run(sprintf("ME_%s_rcp85_hadgem2_wear_r21", no_econ_85),
                     "RCP 8.5", "no econ")

all_runs <- bind_rows(Filter(Negate(is.null), list(econ_45, econ_85, no_45, no_85))) |>
  mutate(
    year       = CYCLE_TO_YEAR(cycle),
    has_econ   = factor(has_econ, levels = c("no econ", "with econ")),
    rcp        = factor(rcp, levels = c("RCP 4.5", "RCP 8.5")),
    statewide_agc_tgc = mean_carbon_mean * ME_AREA_MAC * 1e6 * LB_TO_TGC
  )

if (nrow(all_runs) == 0) {
  stop("No runs loaded. Check that ME econ reruns have completed and the date arg matches the output dir.")
}

cat(sprintf("Loaded %d rows across %d runs:\n", nrow(all_runs),
            n_distinct(all_runs$run_dir)))
print(distinct(all_runs, run_dir, rcp, has_econ))

# -----------------------------------------------------------------------------
# Figure 1: AGC trajectory comparison
# -----------------------------------------------------------------------------

fig_carbon <- all_runs |>
  filter(scenario == "BAU") |>
  ggplot(aes(x = year, y = statewide_agc_tgc,
             colour = has_econ, linetype = has_econ, group = has_econ)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ rcp, ncol = 2) +
  scale_colour_manual(values = c("no econ" = "#1f77b4",
                                  "with econ" = "#d62728")) +
  scale_linetype_manual(values = c("no econ" = "solid",
                                    "with econ" = "dashed")) +
  labs(title    = "ME r21 statewide AGC trajectory: economic overlay effect",
       subtitle = "BAU scenario only. Layer 4 patched economic overlay produces realistic harvest dynamics.",
       x = "Year",
       y = "Statewide AGC (TgC)",
       colour = "Harvest model", linetype = "Harvest model") +
  pub_theme

ggsave(file.path(output_dir, "me_r21_econ_vs_no_econ_carbon.png"),
       fig_carbon, width = 10, height = 5, dpi = 200, bg = "white")
cat("  Wrote figures/me_r21_econ_vs_no_econ_carbon.png\n")

# -----------------------------------------------------------------------------
# Figure 2: Harvest rate comparison
# -----------------------------------------------------------------------------

fig_harvest <- all_runs |>
  filter(scenario == "BAU") |>
  ggplot(aes(x = year, y = harvest_rate_mean,
             colour = has_econ, linetype = has_econ, group = has_econ)) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ rcp, ncol = 2) +
  scale_colour_manual(values = c("no econ" = "#1f77b4",
                                  "with econ" = "#d62728")) +
  scale_linetype_manual(values = c("no econ" = "solid",
                                    "with econ" = "dashed")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title    = "ME r21 cycle harvest rate: economic overlay effect",
       subtitle = "Wear & Coulston (2025) logit with Layer 4 price unit fix.",
       x = "Year", y = "Per cycle harvest rate",
       colour = "Harvest model", linetype = "Harvest model") +
  pub_theme

ggsave(file.path(output_dir, "me_r21_econ_vs_no_econ_harvest.png"),
       fig_harvest, width = 10, height = 5, dpi = 200, bg = "white")
cat("  Wrote figures/me_r21_econ_vs_no_econ_harvest.png\n")

# -----------------------------------------------------------------------------
# Per cycle summary table
# -----------------------------------------------------------------------------

summary_tbl <- all_runs |>
  filter(scenario == "BAU", cycle %in% c(1, 5, 10, 15)) |>
  select(rcp, has_econ, cycle, year,
         carbon_lbac = mean_carbon_mean,
         statewide_agc_tgc, harvest_rate_mean, gr_ratio_mean) |>
  arrange(rcp, cycle, has_econ)

write_csv(summary_tbl, file.path(output_dir, "me_r21_econ_vs_no_econ_summary.csv"))
cat("  Wrote figures/me_r21_econ_vs_no_econ_summary.csv\n")

# Delta comparison: econ minus no-econ
delta_tbl <- all_runs |>
  filter(scenario == "BAU") |>
  select(rcp, has_econ, cycle, year, statewide_agc_tgc, harvest_rate_mean) |>
  pivot_wider(names_from = has_econ, values_from = c(statewide_agc_tgc, harvest_rate_mean)) |>
  mutate(
    delta_agc_tgc = `statewide_agc_tgc_with econ` - `statewide_agc_tgc_no econ`,
    delta_harv    = `harvest_rate_mean_with econ` - `harvest_rate_mean_no econ`
  )

write_csv(delta_tbl, file.path(output_dir, "me_r21_econ_minus_no_econ_delta.csv"))
cat("  Wrote figures/me_r21_econ_minus_no_econ_delta.csv\n")

cat("\nDone. Headline summary at cycles 1, 5, 10, 15:\n")
print(summary_tbl)
