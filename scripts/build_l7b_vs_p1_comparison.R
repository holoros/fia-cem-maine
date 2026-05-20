#!/usr/bin/env Rscript
# build_l7b_vs_p1_comparison.R
# Cross-state pre/post Layer 7b CEM ecoregion patch comparison.
#
# Reads ci_summaries.csv from existing p1 outputs and the new l7b outputs,
# computes cycle 1 BAU bias-relevant metrics, and produces a comparison
# table + figure showing the bias reduction (if any) for each state x RCP.
#
# Run on Cardinal after Layer 7b production reruns land.
# Outputs:
#   l7b_vs_p1_cycle1_bau_comparison.csv
#   l7b_vs_p1_cycle1_bau_figure.png
#   l7b_vs_p1_summary.txt

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/l7b_comparison_20260520"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Map state x RCP x patch to output directory
PATHS <- list(
  list(state = "ME", rcp = "45", patch = "p1",  dir = "ME_20260516_rcp45_hadgem2_wear_econ_r21"),
  list(state = "ME", rcp = "85", patch = "p1",  dir = "ME_20260516_rcp85_hadgem2_wear_econ_r21"),
  list(state = "MN", rcp = "45", patch = "p1",  dir = "MN_20260510_rcp45_wear_p1"),
  list(state = "MN", rcp = "85", patch = "p1",  dir = "MN_20260510_rcp85_wear_p1"),
  list(state = "WA", rcp = "45", patch = "p1",  dir = "WA_20260510_rcp45_wear_p1"),
  list(state = "WA", rcp = "85", patch = "p1",  dir = "WA_20260510_rcp85_wear_p1"),
  list(state = "GA", rcp = "45", patch = "p1",  dir = "GA_20260510_rcp45_wear_p1"),
  list(state = "GA", rcp = "85", patch = "p1",  dir = "GA_20260510_rcp85_wear_p1"),
  list(state = "ME", rcp = "45", patch = "l7b", dir = "ME_20260520_rcp45_hadgem2_wear_econ_l7b"),
  list(state = "ME", rcp = "85", patch = "l7b", dir = "ME_20260520_rcp85_hadgem2_wear_econ_l7b"),
  list(state = "MN", rcp = "45", patch = "l7b", dir = "MN_20260520_rcp45_wear_l7b"),
  list(state = "MN", rcp = "85", patch = "l7b", dir = "MN_20260520_rcp85_wear_l7b"),
  list(state = "WA", rcp = "45", patch = "l7b", dir = "WA_20260520_rcp45_wear_l7b"),
  list(state = "WA", rcp = "85", patch = "l7b", dir = "WA_20260520_rcp85_wear_l7b"),
  list(state = "GA", rcp = "45", patch = "l7b", dir = "GA_20260520_rcp45_wear_l7b"),
  list(state = "GA", rcp = "85", patch = "l7b", dir = "GA_20260520_rcp85_wear_l7b")
)

BASE <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output"

read_cycle1_bau <- function(rec) {
  fp <- file.path(BASE, rec$dir, "ci_summaries.csv")
  if (!file.exists(fp)) {
    cat(sprintf("  [%s %s %s] MISSING: %s\n", rec$state, rec$rcp, rec$patch, rec$dir))
    return(NULL)
  }
  ci <- data.table::fread(fp, showProgress = FALSE)
  row <- ci[scenario == "BAU" & cycle == 1]
  if (nrow(row) == 0) {
    cat(sprintf("  [%s %s %s] no BAU cycle 1 row in %s\n", rec$state, rec$rcp, rec$patch, fp))
    return(NULL)
  }
  data.table::data.table(
    state         = rec$state,
    rcp           = rec$rcp,
    patch         = rec$patch,
    mean_ba       = row$mean_ba_mean,
    mean_vol      = row$mean_vol_mean,
    mean_carbon   = row$mean_carbon_mean,
    total_tpa     = row$total_tpa_mean,
    harvest_rate  = row$harvest_rate_mean,
    gr_ratio      = row$gr_ratio_mean
  )
}

cat("Reading cycle 1 BAU stats for all 8 state-rcp combos x p1/l7b...\n")
results <- data.table::rbindlist(lapply(PATHS, read_cycle1_bau), fill = TRUE)

# Pivot: wide so we have p1 vs l7b side-by-side per state/rcp
if (nrow(results) > 0) {
  wide <- dcast(results, state + rcp ~ patch,
                  value.var = c("mean_ba", "mean_vol", "mean_carbon",
                                 "total_tpa", "harvest_rate", "gr_ratio"))
  fwrite(wide, file.path(OUT_DIR, "l7b_vs_p1_cycle1_bau_comparison.csv"))

  cat("\nCycle 1 BAU comparison (p1 baseline vs l7b patched):\n")
  print(wide)
} else {
  cat("No results read; check production reruns have completed.\n")
}

# Diff figure: pct change in key metrics
if (nrow(results) > 0 && all(c("p1", "l7b") %in% results$patch)) {
  long_p1  <- results[patch == "p1",  .(state, rcp, mean_carbon_p1  = mean_carbon, gr_ratio_p1  = gr_ratio, harvest_rate_p1 = harvest_rate)]
  long_l7b <- results[patch == "l7b", .(state, rcp, mean_carbon_l7b = mean_carbon, gr_ratio_l7b = gr_ratio, harvest_rate_l7b = harvest_rate)]
  diff <- merge(long_p1, long_l7b, by = c("state", "rcp"))
  diff[, pct_carbon_change   := 100 * (mean_carbon_l7b  - mean_carbon_p1)  / mean_carbon_p1]
  diff[, pct_gr_ratio_change := 100 * (gr_ratio_l7b     - gr_ratio_p1)     / gr_ratio_p1]
  diff[, pct_harvest_change  := 100 * (harvest_rate_l7b - harvest_rate_p1) / harvest_rate_p1]
  fwrite(diff, file.path(OUT_DIR, "l7b_vs_p1_pct_change.csv"))

  cat("\nPct change (l7b vs p1, negative = bias reduction direction):\n")
  print(diff[, .(state, rcp, pct_carbon = round(pct_carbon_change, 2),
                   pct_gr_ratio = round(pct_gr_ratio_change, 2),
                   pct_harvest = round(pct_harvest_change, 2))])

  # Plot
  diff_long <- melt(diff[, .(state, rcp, pct_carbon_change,
                              pct_gr_ratio_change, pct_harvest_change)],
                     id.vars = c("state", "rcp"),
                     variable.name = "metric", value.name = "pct_change")
  diff_long[, metric := gsub("^pct_|_change$", "", metric)]

  p <- ggplot(diff_long, aes(x = paste(state, rcp), y = pct_change, fill = metric)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_hline(yintercept = 0, color = "grey30", linewidth = 0.4) +
    scale_fill_manual(values = c("carbon" = "#3a78a3",
                                  "gr_ratio" = "#7a9c6d",
                                  "harvest" = "#c08020")) +
    labs(
      title    = "Layer 7b vs p1 baseline: cycle 1 BAU metric change (%)",
      subtitle = "Negative for WA/MN means donor pool composition fix REDUCES under-prediction; for GA, reduces over-prediction",
      x = NULL, y = "Pct change (l7b - p1) / p1",
      fill = "Metric"
    ) +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          panel.grid.minor = element_blank(),
          legend.position = "bottom")
  ggsave(file.path(OUT_DIR, "l7b_vs_p1_cycle1_bau_figure.png"),
         plot = p, width = 10, height = 5.5, dpi = 150, bg = "white")
}

# Summary text
sink(file.path(OUT_DIR, "l7b_vs_p1_summary.txt"))
cat("LAYER 7B vs P1 PRODUCTION COMPARISON\n")
cat("=====================================\n\n")
cat("Wide-format cycle 1 BAU stats:\n")
if (exists("wide")) print(wide)
cat("\nPct change (negative for under-predicting states means improvement):\n")
if (exists("diff")) print(diff)
sink()

cat("\nOutputs at:", OUT_DIR, "\n")
