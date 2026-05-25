#!/usr/bin/env Rscript
## =============================================================================
## scripts/ga_l7b_residual_decomposition.R
##
## Decomposes the GA RCP85 wear_l7b cycle 4 +41.2 percent bias by subject
## FORTYPCD class and stand age class. Goal is to identify whether the
## overshoot is concentrated in a specific cohort, and whether adding the
## L3 ecoregion key (l7b) systematically routes those subjects to faster
## growing donors than the p1 baseline does.
##
## Designed to run on Cardinal. Reads:
##   ~/fia_cem_projections/output/GA_20260522_rcp85_wear_l7b/per_plot_projections.rds
##   ~/fia_cem_projections/output/GA_20260522_rcp85_wear_l7b/raw_mc_summaries.csv
##   ~/fia_data/GA_COND.csv
##   ~/fia_cem_projections/output/hindcast/HINDCAST_GA_rcp85_wear_l7b.csv
##
## Writes:
##   output/ga_l7b_residual_20260524/ga_l7b_residual_by_fortyp.csv
##   output/ga_l7b_residual_20260524/ga_l7b_residual_by_age_class.csv
##   output/ga_l7b_residual_20260524/ga_l7b_residual_by_fortyp_age.csv
##   output/ga_l7b_residual_20260524/ga_l7b_residual_summary.txt
##
## Author: 24 May 2026
## =============================================================================

suppressPackageStartupMessages({
  library(data.table)
})

PP_RDS  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260522_rcp85_wear_l7b/per_plot_projections.rds"
COND_FP <- "/users/PUOM0008/crsfaaron/fia_data/GA_COND.csv"
HC_FP   <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/hindcast/HINDCAST_GA_rcp85_wear_l7b.csv"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/ga_l7b_residual_20260524"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

PLANTATION_INDICATIVE <- c(141, 142, 161, 165, 166, 167, 168)

cat("=== GA RCP85 wear_l7b residual decomposition ===\n")
cat(sprintf("Started: %s\n", Sys.time()))

## ---- Read per_plot projections ------------------------------------------
cat("\n[1/5] Reading per_plot RDS (8.5 GB)...\n")
t0 <- Sys.time()
pp <- readRDS(PP_RDS)
cat(sprintf("  class: %s; rows: %d; cols: %d; elapsed: %s\n",
            class(pp)[1], nrow(pp), ncol(pp),
            format(Sys.time() - t0)))
cat("  first 30 column names:\n")
print(head(colnames(pp), 30))

pp_dt <- as.data.table(pp)
rm(pp); gc()

## Pick cycle 4 (year 2019). Column names vary across pipeline versions.
year_col <- intersect(c("year_proj", "year", "Year"), colnames(pp_dt))[1]
cycle_col <- intersect(c("cycle_match", "cycle", "Cycle"), colnames(pp_dt))[1]
scen_col <- intersect(c("scenario", "Scenario"), colnames(pp_dt))[1]

cat(sprintf("\nDetected columns: year=%s  cycle=%s  scenario=%s\n",
            year_col, cycle_col, scen_col))

## Filter to RCP85 BAU scenario and cycle 4 (year 2019)
if (!is.na(scen_col)) {
  cat("Unique scenario values:\n")
  print(table(pp_dt[[scen_col]]))
}

## Common pipeline pattern: keep BAU and a target year
if (!is.na(year_col)) {
  pp_c4 <- pp_dt[get(year_col) == 2019]
} else if (!is.na(cycle_col)) {
  pp_c4 <- pp_dt[get(cycle_col) == 4]
} else {
  stop("No year or cycle column found")
}

cat(sprintf("\nCycle 4 (2019) rows after filter: %d\n", nrow(pp_c4)))
cat("Column names in pp_c4:\n")
print(colnames(pp_c4))

## ---- Identify projection and observed columns ---------------------------
proj_col <- intersect(c("proj_carbon", "proj_carbon_ag", "proj_agc",
                        "T2_carbon_ag", "carbon_ag_proj"),
                      colnames(pp_c4))[1]
obs_col  <- intersect(c("obs_carbon", "obs_carbon_ag", "obs_agc",
                        "carbon_ag", "carbon_ag_obs"),
                      colnames(pp_c4))[1]
plt_col  <- intersect(c("PLT_CN", "plt_cn"), colnames(pp_c4))[1]

cat(sprintf("\nUsing proj_col=%s  obs_col=%s  plt_col=%s\n",
            proj_col, obs_col, plt_col))

## Per plot residual (Mg C / ha or whatever units)
pp_c4[, residual := get(proj_col) - get(obs_col)]
pp_c4[, abs_resid := abs(residual)]

## Collapse Monte Carlo iterations if present (mean across sims)
n_sim_col <- intersect(c("sim", "iter", "iteration"), colnames(pp_c4))[1]
if (!is.na(n_sim_col)) {
  cat(sprintf("Collapsing %d sims per plot to mean...\n",
              length(unique(pp_c4[[n_sim_col]]))))
  plot_resid <- pp_c4[, .(proj = mean(get(proj_col), na.rm = TRUE),
                          obs  = mean(get(obs_col),  na.rm = TRUE),
                          residual = mean(residual, na.rm = TRUE),
                          n_sims = .N),
                      by = c(plt_col)]
} else {
  plot_resid <- pp_c4[, .(proj = get(proj_col), obs = get(obs_col),
                           residual = residual,
                           n_sims = 1L),
                       by = c(plt_col)]
}
setnames(plot_resid, plt_col, "PLT_CN")
cat(sprintf("Distinct subject plots at cycle 4: %d\n", nrow(plot_resid)))

## ---- Join to GA_COND for FORTYPCD, STDAGE -------------------------------
cat("\n[2/5] Reading GA_COND.csv...\n")
cond <- fread(COND_FP, select = c("PLT_CN", "CONDID", "COND_STATUS_CD",
                                    "FORTYPCD", "STDAGE", "STDORGCD",
                                    "OWNGRPCD"))
cat(sprintf("  GA_COND rows: %d; unique PLT_CN: %d\n",
            nrow(cond), length(unique(cond$PLT_CN))))

## Take CONDID 1 (or the only condition) per plot for joining
cond1 <- cond[COND_STATUS_CD == 1L,
              .(FORTYPCD = first(FORTYPCD),
                STDAGE   = first(STDAGE),
                STDORGCD = first(STDORGCD),
                OWNGRPCD = first(OWNGRPCD)),
              by = PLT_CN]

## Coerce PLT_CN to character for safe joining
plot_resid[, PLT_CN := as.character(PLT_CN)]
cond1[,      PLT_CN := as.character(PLT_CN)]

plot_resid <- merge(plot_resid, cond1, by = "PLT_CN", all.x = TRUE)
cat(sprintf("Plots with FORTYPCD: %d / %d\n",
            sum(!is.na(plot_resid$FORTYPCD)), nrow(plot_resid)))

## Plantation indicator
plot_resid[, plant_class := ifelse(FORTYPCD %in% PLANTATION_INDICATIVE,
                                    "plantation_indicative",
                                    "other_forest_type")]

## Stand age bin
plot_resid[, age_class := cut(STDAGE,
                                breaks = c(-Inf, 20, 40, 60, 80, 100, Inf),
                                labels = c("0-20", "21-40", "41-60",
                                            "61-80", "81-100", "100+"),
                                include.lowest = TRUE)]

## ---- Aggregate residual by FORTYPCD class -------------------------------
cat("\n[3/5] Aggregating by plantation class...\n")
by_pc <- plot_resid[, .(n_plots = .N,
                         mean_obs = mean(obs, na.rm = TRUE),
                         mean_proj = mean(proj, na.rm = TRUE),
                         mean_resid = mean(residual, na.rm = TRUE),
                         sum_resid = sum(residual, na.rm = TRUE),
                         pct_bias = (sum(proj, na.rm = TRUE)
                                       - sum(obs, na.rm = TRUE))
                                      / sum(obs, na.rm = TRUE) * 100),
                     by = plant_class]
print(by_pc)
fwrite(by_pc, file.path(OUT_DIR, "ga_l7b_residual_by_fortyp.csv"))

## ---- Aggregate by stand age class ---------------------------------------
cat("\n[4/5] Aggregating by stand age class...\n")
by_age <- plot_resid[!is.na(age_class),
                      .(n_plots = .N,
                        mean_obs = mean(obs, na.rm = TRUE),
                        mean_proj = mean(proj, na.rm = TRUE),
                        mean_resid = mean(residual, na.rm = TRUE),
                        sum_resid = sum(residual, na.rm = TRUE),
                        pct_bias = (sum(proj, na.rm = TRUE)
                                      - sum(obs, na.rm = TRUE))
                                     / sum(obs, na.rm = TRUE) * 100),
                      by = age_class]
print(by_age)
fwrite(by_age, file.path(OUT_DIR, "ga_l7b_residual_by_age_class.csv"))

## ---- Crossed plantation x age -------------------------------------------
by_pc_age <- plot_resid[!is.na(age_class),
                          .(n_plots = .N,
                            mean_resid = mean(residual, na.rm = TRUE),
                            sum_resid = sum(residual, na.rm = TRUE),
                            pct_bias = (sum(proj, na.rm = TRUE)
                                          - sum(obs, na.rm = TRUE))
                                         / sum(obs, na.rm = TRUE) * 100),
                         by = .(plant_class, age_class)]
setorder(by_pc_age, plant_class, age_class)
print(by_pc_age)
fwrite(by_pc_age, file.path(OUT_DIR, "ga_l7b_residual_by_fortyp_age.csv"))

## ---- Pareto: which plots contribute the most absolute residual ----------
plot_resid[, abs_resid := abs(residual)]
setorder(plot_resid, -abs_resid)
top_20 <- head(plot_resid, 20)
cat("\n[5/5] Top 20 plots by absolute residual:\n")
print(top_20[, .(PLT_CN, FORTYPCD, STDAGE, STDORGCD,
                  plant_class, age_class,
                  obs = round(obs, 2),
                  proj = round(proj, 2),
                  residual = round(residual, 2))])

## ---- Summary memo --------------------------------------------------------
total_proj <- sum(plot_resid$proj, na.rm = TRUE)
total_obs  <- sum(plot_resid$obs, na.rm = TRUE)
total_pct  <- (total_proj - total_obs) / total_obs * 100

plant_pct <- by_pc[plant_class == "plantation_indicative"]$pct_bias
other_pct <- by_pc[plant_class == "other_forest_type"]$pct_bias

plant_share <- by_pc[plant_class == "plantation_indicative"]$sum_resid /
                sum(by_pc$sum_resid) * 100

memo <- c(
  "GA RCP85 wear_l7b cycle 4 (2019) residual decomposition",
  "=======================================================",
  sprintf("Total observed AGC:    %.1f", total_obs),
  sprintf("Total projected AGC:   %.1f", total_proj),
  sprintf("Total bias percent:    %+.2f", total_pct),
  "",
  "By plantation class:",
  sprintf("  plantation_indicative bias: %+.2f pct  (n=%d, share of residual: %.1f pct)",
          plant_pct, by_pc[plant_class == "plantation_indicative"]$n_plots, plant_share),
  sprintf("  other_forest_type     bias: %+.2f pct  (n=%d)",
          other_pct, by_pc[plant_class == "other_forest_type"]$n_plots),
  "",
  "Run timestamp:",
  format(Sys.time()),
  "")
writeLines(memo, file.path(OUT_DIR, "ga_l7b_residual_summary.txt"))
cat("\n", paste(memo, collapse = "\n"), "\n", sep = "")

cat(sprintf("\nDone. Outputs in %s\n", OUT_DIR))
