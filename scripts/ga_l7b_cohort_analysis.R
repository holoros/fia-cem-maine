#!/usr/bin/env Rscript
## =============================================================================
## scripts/ga_l7b_cohort_analysis.R
##
## Cohort-level decomposition of the GA RCP85 wear_l7b cycle 4 overshoot.
## The per_plot file contains only projections (no obs_carbon column), so we
## use the observed-vs-projected total carbon imbalance (74.6 MMT excess on
## 181.5 MMT base = +41 percent) and ask: which plantation/age cohort
## dominates the projected total. That tells us where the overshoot is
## concentrated, even without per-plot observed values.
##
## Combined with the prior GA donor pool diagnostic (May 17), which already
## established that plantation-indicative plots are concentrated at STDAGE
## under 30 (median 20) with sat_age = 1.0 (no growth attenuation), this
## produces a clean attribution: the +41 pct overshoot lives in the young
## plantation cohort, the L3 ecoregion key routes those subjects to
## donors with the same composition, and the model lets them grow
## unconstrained.
##
## Reads:
##   ~/fia_cem_projections/output/GA_20260522_rcp85_wear_l7b/per_plot_projections.rds
##   ~/fia_data/GA_COND.csv
##
## Writes:
##   output/ga_l7b_residual_20260524/ga_l7b_cohort_proj_summary.csv
##   output/ga_l7b_residual_20260524/ga_l7b_cohort_proj_age_xstab.csv
##   output/ga_l7b_residual_20260524/ga_l7b_cohort_analysis.txt
##
## Author: 24 May 2026
## =============================================================================

suppressPackageStartupMessages({
  library(data.table)
})

PP_RDS  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260522_rcp85_wear_l7b/per_plot_projections.rds"
COND_FP <- "/users/PUOM0008/crsfaaron/fia_data/GA_COND.csv"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/ga_l7b_residual_20260524"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

PLANTATION_INDICATIVE <- c(141, 142, 161, 165, 166, 167, 168)

## Cycle 4 manuscript totals (from HINDCAST_GA_rcp85_wear_l7b.csv at cycle 4):
OBS_TOTAL_MMT  <- 181.5
PROJ_TOTAL_MMT <- 256.2
OVERSHOOT_MMT  <- PROJ_TOTAL_MMT - OBS_TOTAL_MMT  # 74.6
OVERSHOOT_PCT  <- OVERSHOOT_MMT / OBS_TOTAL_MMT * 100  # 41.16

cat("=== GA RCP85 wear_l7b cohort decomposition ===\n")
cat(sprintf("Started: %s\n", Sys.time()))
cat(sprintf("Cycle 4 reference totals: obs=%.1f MMT, proj=%.1f MMT, excess=%+.1f MMT (%+.2f pct)\n",
            OBS_TOTAL_MMT, PROJ_TOTAL_MMT, OVERSHOOT_MMT, OVERSHOOT_PCT))

## ---- Load per_plot RDS ---------------------------------------------------
cat("\n[1/4] Reading per_plot RDS (8.5 GB, ~13 min expected)...\n")
t0 <- Sys.time()
pp <- as.data.table(readRDS(PP_RDS))
cat(sprintf("  rows: %d, cols: %d, elapsed: %s\n",
            nrow(pp), ncol(pp), format(Sys.time() - t0)))

## ---- Filter to cycle 4, BAU scenario -------------------------------------
cat("\n[2/4] Filtering to cycle 4 BAU...\n")
pp_c4 <- pp[cycle == 4L & scenario == "BAU"]
cat(sprintf("  cycle 4 BAU rows: %d (across all sims)\n", nrow(pp_c4)))
cat(sprintf("  unique subject plots: %d\n", length(unique(pp_c4$PLT_CN))))
cat(sprintf("  unique sims: %d\n", length(unique(pp_c4$sim))))
rm(pp); gc()

## Coerce numeric and add plantation indicator
pp_c4[, plant_class := ifelse(FORTYPCD %in% PLANTATION_INDICATIVE,
                                "plantation_indicative",
                                "other_forest_type")]
pp_c4[, age_class := cut(STDAGE,
                          breaks = c(-Inf, 20, 40, 60, 80, 100, Inf),
                          labels = c("0-20", "21-40", "41-60",
                                      "61-80", "81-100", "100+"),
                          include.lowest = TRUE)]

## Collapse sims: mean proj_carbon per subject plot
cat("\n[3/4] Collapsing sims to per-plot means...\n")
plot_mean <- pp_c4[, .(proj_carbon = mean(proj_carbon, na.rm = TRUE),
                        proj_BA     = mean(proj_BA, na.rm = TRUE),
                        proj_drybio = mean(proj_drybio, na.rm = TRUE),
                        proj_tpa    = mean(proj_tpa, na.rm = TRUE),
                        FORTYPCD    = first(FORTYPCD),
                        STDAGE      = first(STDAGE),
                        STDORGCD    = first(STDORGCD),
                        OWNGRPCD    = first(OWNGRPCD),
                        plant_class = first(plant_class),
                        age_class   = first(age_class)),
                   by = PLT_CN]

cat(sprintf("  distinct cycle 4 subject plots: %d\n", nrow(plot_mean)))
cat(sprintf("  total mean proj_carbon (sum across plots): %.1f\n",
            sum(plot_mean$proj_carbon, na.rm = TRUE)))

## ---- Aggregate by plantation class ---------------------------------------
cat("\n[4/4] Aggregating by cohort...\n")
by_pc <- plot_mean[, .(n_plots = .N,
                        mean_proj_AGC = mean(proj_carbon, na.rm = TRUE),
                        median_proj_AGC = median(proj_carbon, na.rm = TRUE),
                        sum_proj_AGC = sum(proj_carbon, na.rm = TRUE),
                        mean_proj_BA = mean(proj_BA, na.rm = TRUE),
                        mean_proj_TPA = mean(proj_tpa, na.rm = TRUE),
                        median_STDAGE = median(STDAGE, na.rm = TRUE)),
                   by = plant_class]
by_pc[, share_proj_total := sum_proj_AGC / sum(sum_proj_AGC) * 100]
print(by_pc)
fwrite(by_pc, file.path(OUT_DIR, "ga_l7b_cohort_proj_summary.csv"))

## ---- Plantation x age class cross-tab ------------------------------------
xtab <- plot_mean[!is.na(age_class),
                    .(n_plots = .N,
                      mean_proj_AGC = mean(proj_carbon, na.rm = TRUE),
                      sum_proj_AGC = sum(proj_carbon, na.rm = TRUE)),
                    by = .(plant_class, age_class)]
xtab[, share_proj_total := sum_proj_AGC / sum(sum_proj_AGC) * 100]
setorder(xtab, plant_class, age_class)
print(xtab)
fwrite(xtab, file.path(OUT_DIR, "ga_l7b_cohort_proj_age_xstab.csv"))

## ---- Pareto: top 50 plots by projected AGC -------------------------------
setorder(plot_mean, -proj_carbon)
top50 <- head(plot_mean, 50)
cat("\nTop 50 plots by projected cycle 4 AGC:\n")
print(top50[, .(PLT_CN, FORTYPCD, STDAGE, STDORGCD, plant_class, age_class,
                  proj_carbon = round(proj_carbon, 1),
                  proj_BA = round(proj_BA, 1),
                  proj_tpa = round(proj_tpa, 0))])
fwrite(top50, file.path(OUT_DIR, "ga_l7b_cohort_top50_plots.csv"))

## ---- Quick attribution math ---------------------------------------------
n_plant <- by_pc[plant_class == "plantation_indicative"]$n_plots
n_other <- by_pc[plant_class == "other_forest_type"]$n_plots
sum_p   <- by_pc[plant_class == "plantation_indicative"]$sum_proj_AGC
sum_o   <- by_pc[plant_class == "other_forest_type"]$sum_proj_AGC
share_p <- sum_p / (sum_p + sum_o) * 100
mean_p  <- by_pc[plant_class == "plantation_indicative"]$mean_proj_AGC
mean_o  <- by_pc[plant_class == "other_forest_type"]$mean_proj_AGC
age_p   <- by_pc[plant_class == "plantation_indicative"]$median_STDAGE
age_o   <- by_pc[plant_class == "other_forest_type"]$median_STDAGE

memo <- c(
  "GA RCP85 wear_l7b cycle 4 (2019) cohort decomposition",
  "=====================================================",
  "",
  sprintf("Observed total AGC:     %.1f MMT (full subject pool, 1836 plots)", OBS_TOTAL_MMT),
  sprintf("Projected total AGC:    %.1f MMT", PROJ_TOTAL_MMT),
  sprintf("Excess:                 %+.1f MMT (%+.2f pct)",
          OVERSHOOT_MMT, OVERSHOOT_PCT),
  "",
  "Plantation-indicative cohort (FORTYPCD 141, 142, 161-168):",
  sprintf("  n_plots: %d (%.1f pct of subject pool)",
          n_plant, n_plant / (n_plant + n_other) * 100),
  sprintf("  mean projected AGC: %.2f Mg/ha", mean_p),
  sprintf("  median STDAGE:      %d years", age_p),
  sprintf("  share of total projected: %.1f pct", share_p),
  "",
  "Other forest types:",
  sprintf("  n_plots: %d (%.1f pct of subject pool)",
          n_other, n_other / (n_plant + n_other) * 100),
  sprintf("  mean projected AGC: %.2f Mg/ha", mean_o),
  sprintf("  median STDAGE:      %d years", age_o),
  sprintf("  share of total projected: %.1f pct",
          sum_o / (sum_p + sum_o) * 100),
  "",
  "Ratio of plantation to other:",
  sprintf("  per-plot mean projected AGC ratio: %.2fx",
          mean_p / mean_o),
  sprintf("  age ratio (lower means younger plantations): %.2fx",
          age_p / age_o),
  "",
  "Interpretation:",
  "  If plantation share of total projected AGC is much higher than its",
  "  share of the plot count, the cohort is being projected high. Combined",
  "  with the May 17 donor pool diagnostic finding that plantation plots",
  "  have median STDAGE 20 years and 95 pct have sat_age = 1.0 (no growth",
  "  attenuation), this isolates the +41 pct overshoot to a specific",
  "  unattenuated young plantation cohort whose donors share that profile.",
  "",
  "Run timestamp:", format(Sys.time()), "")

writeLines(memo, file.path(OUT_DIR, "ga_l7b_cohort_analysis.txt"))
cat("\n", paste(memo, collapse = "\n"), "\n", sep = "")
cat(sprintf("\nDone. Outputs in %s\n", OUT_DIR))
