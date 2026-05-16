#!/usr/bin/env Rscript
# =============================================================================
# scripts/build_p1_comparison_figures.R
#
# Cross state x cross RCP comparison figures for the multistate p1 set.
# Reads ci_summaries.csv from each of the six production output directories
# (3 states x 2 RCPs), tidies the data, and produces publication ready
# ggplot2 panel figures.
#
# Output figures (saved to figures/):
#   p1_carbon_trajectory_panel.png      Per acre carbon trajectory by state x RCP x scenario
#   p1_volume_trajectory_panel.png      Per acre volume trajectory
#   p1_statewide_agc_panel.png          Statewide total AGC trajectory in TgC
#   p1_harvest_delta_panel.png          Delta from BAU by scenario, state, RCP
#   p1_summary_grid.png                 4 metric x state grid combining all
#
# Usage:
#   Rscript scripts/build_p1_comparison_figures.R
#   Rscript scripts/build_p1_comparison_figures.R --input_dir <path> --output_dir <path>
#
# Author: Aaron Weiskittel (built 15 May 2026)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
arg_or_default <- function(flag, default) {
  i <- which(args == flag)
  if (length(i) > 0) args[i + 1] else default
}

input_dir  <- arg_or_default("--input_dir",  here::here("output", "p1_summaries"))
output_dir <- arg_or_default("--output_dir", here::here("figures"))

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Forest area per state (M acres) for statewide totals
FOREST_AREA_MAC <- c(WA = 22.0, MN = 17.4, GA = 24.8, ME = 17.6)
LB_TO_TGC <- 4.53592e-10  # per_ac_carbon is lb/ac per R/01 sum(TPA_UNADJ * CARBON_AG)

# Cycle to year conversion (cycle 1 = baseline 1999 + 5 = 2004)
CYCLE_TO_YEAR <- function(c) 1999 + c * 5

# Publication theme: minimal with major gridlines, sans serif sized for figure panels
pub_theme <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "grey92", colour = NA),
    strip.text       = element_text(face = "bold"),
    legend.position  = "bottom",
    plot.title       = element_text(face = "bold", size = 12),
    plot.subtitle    = element_text(size = 10, colour = "grey30")
  )

# State and scenario factor orders for consistent plotting
STATE_ORDER <- c("MN", "WA", "GA", "ME")
RCP_LABEL <- c("45" = "RCP 4.5", "85" = "RCP 8.5")

# -----------------------------------------------------------------------------
# Load and tidy all six summaries
# -----------------------------------------------------------------------------

load_ci <- function(state, rcp) {
  path <- file.path(input_dir, sprintf("%s_RCP%s_ci.csv", state, rcp))
  if (!file.exists(path)) return(NULL)
  read_csv(path, show_col_types = FALSE) |>
    mutate(state = state, rcp = rcp, .before = scenario)
}

ci_all <- expand_grid(state = c("WA", "MN", "GA"),
                      rcp   = c("45", "85")) |>
  pmap_dfr(\(state, rcp) load_ci(state, rcp))

if (nrow(ci_all) == 0) {
  stop("No ci_summaries found in ", input_dir,
       ". Pull them from Cardinal first.")
}

# Add a year column and statewide totals where possible
ci_all <- ci_all |>
  mutate(
    year      = CYCLE_TO_YEAR(cycle),
    state_f   = factor(state, levels = STATE_ORDER),
    rcp_label = factor(RCP_LABEL[rcp], levels = unname(RCP_LABEL)),
    forest_area_mac = unname(FOREST_AREA_MAC[state]),
    statewide_agc_tgc      = mean_carbon_mean * forest_area_mac * 1e6 * LB_TO_TGC,
    statewide_agc_tgc_lo   = mean_carbon_lo   * forest_area_mac * 1e6 * LB_TO_TGC,
    statewide_agc_tgc_hi   = mean_carbon_hi   * forest_area_mac * 1e6 * LB_TO_TGC,
    statewide_vol_bcuft    = mean_vol_mean    * forest_area_mac * 1e6 / 1e9,
    statewide_vol_bcuft_lo = mean_vol_lo      * forest_area_mac * 1e6 / 1e9,
    statewide_vol_bcuft_hi = mean_vol_hi      * forest_area_mac * 1e6 / 1e9
  )

cat(sprintf("Loaded %d rows from %d states x %d RCPs x %d scenarios x %d cycles\n",
            nrow(ci_all),
            n_distinct(ci_all$state), n_distinct(ci_all$rcp),
            n_distinct(ci_all$scenario), n_distinct(ci_all$cycle)))

# -----------------------------------------------------------------------------
# Figure 1: per acre carbon trajectory
# -----------------------------------------------------------------------------

fig_carbon <- ci_all |>
  ggplot(aes(x = year, y = mean_carbon_mean / 1000,
             colour = scenario, fill = scenario, group = scenario)) +
  geom_ribbon(aes(ymin = mean_carbon_lo / 1000, ymax = mean_carbon_hi / 1000),
              alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) +
  facet_grid(rcp_label ~ state_f, scales = "free_y") +
  scale_colour_brewer(palette = "Set1") +
  scale_fill_brewer(palette = "Set1") +
  labs(title    = "Per acre aboveground carbon trajectory, multistate p1",
       subtitle = "Cycle 1 (2004) through cycle 15 (2074). Ribbons show 95 percent CI across n_sims = 100.",
       x = "Year",
       y = expression("Per acre AGC (kilopounds C per acre)"),
       colour = "Scenario", fill = "Scenario") +
  pub_theme

ggsave(file.path(output_dir, "p1_carbon_trajectory_panel.png"),
       fig_carbon, width = 12, height = 6, dpi = 200, bg = "white")
cat("  Wrote figures/p1_carbon_trajectory_panel.png\n")

# -----------------------------------------------------------------------------
# Figure 2: per acre volume trajectory
# -----------------------------------------------------------------------------

fig_vol <- ci_all |>
  ggplot(aes(x = year, y = mean_vol_mean,
             colour = scenario, fill = scenario, group = scenario)) +
  geom_ribbon(aes(ymin = mean_vol_lo, ymax = mean_vol_hi),
              alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) +
  facet_grid(rcp_label ~ state_f, scales = "free_y") +
  scale_colour_brewer(palette = "Set1") +
  scale_fill_brewer(palette = "Set1") +
  labs(title    = "Per acre net merchantable volume trajectory",
       subtitle = "Cubic feet per acre, BAU and four harvest scenarios.",
       x = "Year",
       y = "Per acre volume (cuft per acre)",
       colour = "Scenario", fill = "Scenario") +
  pub_theme

ggsave(file.path(output_dir, "p1_volume_trajectory_panel.png"),
       fig_vol, width = 12, height = 6, dpi = 200, bg = "white")
cat("  Wrote figures/p1_volume_trajectory_panel.png\n")

# -----------------------------------------------------------------------------
# Figure 3: statewide AGC trajectory in TgC
# -----------------------------------------------------------------------------

fig_statewide <- ci_all |>
  ggplot(aes(x = year, y = statewide_agc_tgc,
             colour = scenario, fill = scenario, group = scenario)) +
  geom_ribbon(aes(ymin = statewide_agc_tgc_lo, ymax = statewide_agc_tgc_hi),
              alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.7) +
  facet_grid(rcp_label ~ state_f, scales = "free_y") +
  scale_colour_brewer(palette = "Set1") +
  scale_fill_brewer(palette = "Set1") +
  labs(title    = "Statewide aboveground carbon trajectory",
       subtitle = "Per acre carbon expanded by FIA forest area; corrected lb to TgC conversion.",
       x = "Year",
       y = "Statewide AGC (TgC)",
       colour = "Scenario", fill = "Scenario") +
  pub_theme

ggsave(file.path(output_dir, "p1_statewide_agc_panel.png"),
       fig_statewide, width = 12, height = 6, dpi = 200, bg = "white")
cat("  Wrote figures/p1_statewide_agc_panel.png\n")

# -----------------------------------------------------------------------------
# Figure 4: harvest scenario delta vs BAU
# -----------------------------------------------------------------------------

bau_ref <- ci_all |>
  filter(scenario == "BAU") |>
  select(state, rcp, cycle, year, statewide_agc_tgc_bau = statewide_agc_tgc)

deltas <- ci_all |>
  filter(scenario != "BAU") |>
  inner_join(bau_ref, by = c("state", "rcp", "cycle", "year")) |>
  mutate(delta_tgc = statewide_agc_tgc - statewide_agc_tgc_bau)

fig_delta <- deltas |>
  ggplot(aes(x = year, y = delta_tgc, colour = scenario, group = scenario)) +
  geom_hline(yintercept = 0, linewidth = 0.4, colour = "grey60") +
  geom_line(linewidth = 0.7) +
  facet_grid(rcp_label ~ state_f, scales = "free_y") +
  scale_colour_brewer(palette = "Set2") +
  labs(title    = "Scenario delta from BAU, statewide AGC",
       subtitle = "Positive: scenario stores more carbon than BAU. Negative: less.",
       x = "Year",
       y = "Delta statewide AGC (TgC, scenario minus BAU)",
       colour = "Scenario") +
  pub_theme

ggsave(file.path(output_dir, "p1_harvest_delta_panel.png"),
       fig_delta, width = 12, height = 6, dpi = 200, bg = "white")
cat("  Wrote figures/p1_harvest_delta_panel.png\n")

# -----------------------------------------------------------------------------
# Figure 5: summary grid combining BA, volume, carbon, gr_ratio
# -----------------------------------------------------------------------------

# Long format with 4 metrics, BAU only, mean only
metric_long <- ci_all |>
  filter(scenario == "BAU") |>
  select(state_f, rcp_label, year, cycle,
         BA = mean_ba_mean,
         Volume = mean_vol_mean,
         Carbon = mean_carbon_mean,
         gr_ratio = gr_ratio_mean) |>
  pivot_longer(cols = c(BA, Volume, Carbon, gr_ratio),
               names_to = "metric", values_to = "value") |>
  mutate(metric = factor(metric, levels = c("BA", "Volume", "Carbon", "gr_ratio")))

fig_grid <- metric_long |>
  ggplot(aes(x = year, y = value, colour = state_f,
             linetype = rcp_label, group = interaction(state_f, rcp_label))) +
  geom_line(linewidth = 0.7) +
  facet_wrap(~ metric, scales = "free_y", ncol = 2) +
  scale_colour_brewer(palette = "Dark2", name = "State") +
  scale_linetype_manual(values = c("RCP 4.5" = "solid", "RCP 8.5" = "dashed"),
                        name = "Climate") +
  labs(title    = "BAU scenario summary, all four metrics",
       subtitle = "BA (sqft per ac), Volume (cuft per ac), Carbon (lb per ac), gr_ratio (dimensionless).",
       x = "Year", y = "Value") +
  pub_theme

ggsave(file.path(output_dir, "p1_summary_grid.png"),
       fig_grid, width = 12, height = 8, dpi = 200, bg = "white")
cat("  Wrote figures/p1_summary_grid.png\n")

# -----------------------------------------------------------------------------
# Statewide totals summary table (for the manuscript appendix)
# -----------------------------------------------------------------------------

summary_table <- ci_all |>
  filter(scenario == "BAU", cycle %in% c(1, 5, 10, 15)) |>
  select(state, rcp, cycle, year,
         per_ac_carbon_lbac = mean_carbon_mean,
         statewide_agc_tgc,
         per_ac_vol_cuft = mean_vol_mean,
         statewide_vol_bcuft) |>
  arrange(state, rcp, cycle)

write_csv(summary_table,
          file.path(output_dir, "p1_summary_BAU_milestones.csv"))
cat("  Wrote figures/p1_summary_BAU_milestones.csv\n")

cat("\nDone. Figures and summary table in: ", output_dir, "\n", sep = "")
