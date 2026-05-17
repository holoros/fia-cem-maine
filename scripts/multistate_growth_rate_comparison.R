#!/usr/bin/env Rscript
# multistate_growth_rate_comparison.R
# Cross state comparison of per acre baseline, gross growth, and implied
# relative growth rates from existing raw_mc_summaries.csv files. Tests
# whether GA's +10 percent over bias is driven by high productivity baseline
# x normal relative growth rate (multiplicative effect, Candidate 1).
# Companion to ga_bias_candidate_diagnostic.R.
#
# Tiny script: reads only the small CSVs, not the 6.2GB RDS files.
# Inputs:
#   ~/fia_cem_projections/output/<STATE>_20260510_rcp45_wear_p1/raw_mc_summaries.csv
# Outputs:
#   multistate_growth_rate_comparison.csv
#   multistate_growth_rate_comparison.png
#   multistate_growth_rate_summary.txt

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/multistate_growth_rate_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Find the p1 production output directories for each state
state_dirs <- c(
  GA = "GA_20260510_rcp45_wear_p1",
  WA = "WA_20260510_rcp45_wear_p1",
  MN = "MN_20260510_rcp45_wear_p1",
  ME = "ME_20260516_rcp45_hadgem2_wear_econ_r21"  # newer ME canonical
)

read_state <- function(state, dirname) {
  fp <- file.path("/users/PUOM0008/crsfaaron/fia_cem_projections/output",
                   dirname, "raw_mc_summaries.csv")
  if (!file.exists(fp)) {
    cat(sprintf("  %s: missing at %s\n", state, fp))
    return(NULL)
  }
  dt <- data.table::fread(fp, showProgress = FALSE)
  dt[, state := state]
  dt
}

cat("Reading raw_mc_summaries for all states...\n")
all <- data.table::rbindlist(
  lapply(names(state_dirs), function(s) read_state(s, state_dirs[s])),
  fill = TRUE
)
cat("Total rows:", nrow(all), "  states present:",
    paste(unique(all$state), collapse = ","), "\n")

# Per state cycle 1 BAU baseline + gross growth
bau1 <- all[cycle == 1 & scenario == "BAU", .(
  n_sims = .N,
  mean_carbon = mean(mean_carbon, na.rm = TRUE),
  mean_vol    = mean(mean_vol,    na.rm = TRUE),
  mean_ba     = mean(mean_ba,     na.rm = TRUE),
  gross_growth = mean(gross_growth, na.rm = TRUE),
  total_tpa   = mean(total_tpa,   na.rm = TRUE)
), by = state]
bau1[, rel_growth_rate := gross_growth / mean_carbon]
data.table::setorder(bau1, -mean_carbon)

cat("\nCycle 1 BAU per acre baseline + gross growth across states:\n")
print(bau1)

fwrite(bau1, file.path(OUT_DIR, "multistate_growth_rate_comparison.csv"))

# Plot: 3 panel comparison
plot_long <- data.table::rbindlist(list(
  bau1[, .(state, value = mean_carbon, metric = "Baseline carbon (lb/ac)")],
  bau1[, .(state, value = gross_growth, metric = "Gross growth (lb/ac/cycle)")],
  bau1[, .(state, value = rel_growth_rate, metric = "Relative growth rate (gross / baseline)")]
))

p <- ggplot(plot_long, aes(x = reorder(state, -value), y = value)) +
  geom_col(fill = "#3a78a3", alpha = 0.85) +
  facet_wrap(~ metric, scales = "free_y", ncol = 3) +
  labs(
    title    = "Cross state multistate p1 BAU cycle 1: baseline, growth, and relative rate",
    subtitle = "Tests the multiplicative-effect hypothesis: if relative rate is similar across states but growth scales with baseline, hypothesis confirmed",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "multistate_growth_rate_comparison.png"),
       plot = p, width = 10, height = 4.5, dpi = 150, bg = "white")

# Also cycle-by-cycle BAU mean trajectories for full panel
trajectory <- all[scenario == "BAU", .(
  mean_carbon  = mean(mean_carbon,  na.rm = TRUE),
  gross_growth = mean(gross_growth, na.rm = TRUE),
  rel_growth_rate = mean(gross_growth, na.rm = TRUE) /
                     mean(mean_carbon, na.rm = TRUE)
), by = .(state, cycle)][order(state, cycle)]
fwrite(trajectory, file.path(OUT_DIR, "multistate_trajectory_comparison.csv"))

p2 <- ggplot(trajectory[cycle <= 5], aes(x = cycle, y = rel_growth_rate,
                                          color = state, group = state)) +
  geom_line(linewidth = 1) + geom_point() +
  labs(
    title    = "Cross state relative growth rate by cycle (BAU)",
    subtitle = "Cycle 5 = 2024 RPA-comparable year",
    x = "Projection cycle", y = "Relative growth rate (gross_growth / mean_carbon)",
    color = "State"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "multistate_rel_growth_trajectory.png"),
       plot = p2, width = 9, height = 5, dpi = 150, bg = "white")

# Summary text
sink(file.path(OUT_DIR, "multistate_growth_rate_summary.txt"))
cat("MULTISTATE GROWTH RATE COMPARISON\n")
cat("=================================\n\n")
cat("Cycle 1 BAU per acre (multistate p1, RCP 4.5):\n")
print(bau1)
cat("\nKey observation:\n")
cat("- If GA has highest mean_carbon AND highest gross_growth absolute,\n")
cat("  but mid-range rel_growth_rate, the multiplicative effect is confirmed:\n")
cat("  similar relative growth applied to higher baseline = larger absolute growth.\n")
cat("- If GA has highest rel_growth_rate, the absolute over comes from a\n")
cat("  faster donor-to-subject growth ratio not the baseline level.\n")
sink()

cat("\nOutputs at:", OUT_DIR, "\n")
