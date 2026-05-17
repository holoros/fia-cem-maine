#!/usr/bin/env Rscript
# ga_bias_candidate_diagnostic.R
# Test GA bias candidate mechanisms against the existing GA p1 per_plot RDS:
#  Candidate 1: growth-ratio multiplicative effect on high productivity baseline
#  Candidate 4: stand age distribution / saturation behavior
# Companion diagnostic to GA_DONOR_POOL_DIAGNOSTIC_20260517.md which refuted
# the original plantation/natural donor mixing hypothesis.
#
# Run on Cardinal. Reads:
#   ~/fia_cem_projections/output/GA_20260510_rcp45_wear_p1/per_plot_projections.rds
#   ~/fia_data/GA_COND.csv (for STDAGE distribution by FORTYPCD)
#
# Outputs:
#   ga_growth_ratio_by_baseline_decile.csv
#   ga_stand_age_distribution_by_fortyp.csv
#   ga_bias_candidate_diagnostic.png
#   ga_bias_candidate_summary.txt

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
})

PP_RDS  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/GA_20260510_rcp45_wear_p1/per_plot_projections.rds"
COND_FP <- "/users/PUOM0008/crsfaaron/fia_data/GA_COND.csv"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/ga_bias_candidate_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Plantation indicative FORTYPCD set per GA donor pool diagnostic
PLANTATION_INDICATIVE_TYPES <- c(141, 142, 161, 165, 166, 167, 168)

cat("Reading per_plot RDS...\n")
pp <- readRDS(PP_RDS)
cat("Class:", class(pp)[1], "  Rows:", nrow(pp), "  Cols:", ncol(pp), "\n")
cat("First few colnames:\n")
print(head(colnames(pp), 30))

# Identify needed columns. Most pipelines have something like:
# PLT_CN, scenario, cycle, year_proj, proj_carbon, carbon_ag (baseline), STDAGE,
# FORTYPCD, etc.
has_col <- function(n) n %in% colnames(pp)

cat("\nKey column presence check:\n")
for (c in c("PLT_CN", "STDAGE", "FORTYPCD", "scenario", "cycle", "year_proj",
             "proj_carbon", "carbon_ag", "T2_carbon_ag", "proj_BA", "BA",
             "tpa_live", "proj_tpa", "gr_carbon", "harvested")) {
  cat(sprintf("  %-15s : %s\n", c, has_col(c)))
}

# Filter to cycle 1, BAU scenario for the multiplicative effect test
scen_col <- intersect(c("scenario", "Scenario", "scen"), colnames(pp))[1]
if (!is.na(scen_col) && !is.null(scen_col)) {
  cat(sprintf("\nUnique %s values:\n", scen_col))
  print(head(unique(pp[[scen_col]]), 10))
}

# Use BAU and cycle 1
pp_dt <- as.data.table(pp)
if ("scenario" %in% colnames(pp_dt)) {
  pp_dt <- pp_dt[scenario %in% c("BAU", "baseline", "no_harvest_bau", "Business_As_Usual")]
}
if ("cycle" %in% colnames(pp_dt)) {
  pp_dt <- pp_dt[cycle == 1]
}
cat("\nRows after BAU + cycle 1 filter:", nrow(pp_dt), "\n")

# --- Candidate 1: growth ratio multiplicative effect ---
cat("\n--- Candidate 1: growth ratio by baseline carbon decile ---\n")
if (all(c("proj_carbon", "carbon_ag") %in% colnames(pp_dt))) {
  pp_dt[, baseline_carbon_decile := ntile(carbon_ag, 10)]
  pp_dt[, gr_carbon_implied := proj_carbon / pmax(1, carbon_ag)]
  pp_dt[, growth_increment  := proj_carbon - carbon_ag]
  c1 <- pp_dt[, .(
    n_plots                = .N,
    mean_baseline_carbon   = mean(carbon_ag, na.rm = TRUE),
    median_baseline        = median(carbon_ag, na.rm = TRUE),
    mean_proj_carbon       = mean(proj_carbon, na.rm = TRUE),
    mean_growth_increment  = mean(growth_increment, na.rm = TRUE),
    mean_implied_gr        = mean(gr_carbon_implied, na.rm = TRUE)
  ), by = baseline_carbon_decile][order(baseline_carbon_decile)]
  fwrite(c1, file.path(OUT_DIR, "ga_growth_ratio_by_baseline_decile.csv"))
  cat("Top vs bottom decile mean growth increment ratio:",
      round(c1[baseline_carbon_decile == 10]$mean_growth_increment /
            pmax(0.01, c1[baseline_carbon_decile == 1]$mean_growth_increment), 2), "x\n")
  cat("Top decile implied gr_carbon:",
      round(c1[baseline_carbon_decile == 10]$mean_implied_gr, 3), "\n")
  cat("Bottom decile implied gr_carbon:",
      round(c1[baseline_carbon_decile == 1]$mean_implied_gr, 3), "\n")
} else {
  cat("proj_carbon or carbon_ag column missing; skipping Candidate 1\n")
}

# --- Candidate 4: stand age distribution by plantation status ---
cat("\n--- Candidate 4: GA stand age distribution by plantation/natural ---\n")
cond <- data.table::fread(COND_FP,
                            select = c("PLT_CN", "INVYR", "COND_STATUS_CD",
                                       "FORTYPCD", "STDAGE", "STDORGCD",
                                       "CONDPROP_UNADJ"),
                            showProgress = FALSE)
cond_b <- cond[COND_STATUS_CD == 1 & INVYR %in% 1999:2008 &
                  !is.na(FORTYPCD) & FORTYPCD > 0 & !is.na(STDAGE) & STDAGE > 0]
cond_b[, plant_class := ifelse(FORTYPCD %in% PLANTATION_INDICATIVE_TYPES,
                                "plantation_indicative", "other_forest_type")]

c4 <- cond_b[, .(
  n_cond     = .N,
  mean_age   = round(mean(STDAGE), 1),
  median_age = median(STDAGE),
  p25_age    = quantile(STDAGE, 0.25),
  p75_age    = quantile(STDAGE, 0.75),
  p90_age    = quantile(STDAGE, 0.90),
  pct_age_lt_30 = round(mean(STDAGE < 30), 3),
  pct_age_lt_60 = round(mean(STDAGE < 60), 3),
  pct_age_lt_80 = round(mean(STDAGE < 80), 3)
), by = plant_class]
fwrite(c4, file.path(OUT_DIR, "ga_stand_age_distribution_by_fortyp.csv"))

cat("\nStand age distribution:\n")
print(c4)

# Saturation function (mirrors R/06): terminal_age=80, growth_start_age=60 for GA
terminal_age     <- 80
growth_start_age <- 60
sat_for_age <- function(age) {
  age <- pmin(pmax(ifelse(is.na(age), 0, age), 0), terminal_age)
  pmax(0, pmin(1, (terminal_age - age) / (terminal_age - growth_start_age)))
}
cond_b[, sat_age := sat_for_age(STDAGE)]
sat_by_class <- cond_b[, .(
  n_cond = .N,
  pct_sat_full_1     = round(mean(sat_age == 1.0), 3),
  pct_sat_lt_05      = round(mean(sat_age < 0.5),  3),
  pct_sat_0          = round(mean(sat_age == 0),   3),
  mean_sat_age       = round(mean(sat_age), 3)
), by = plant_class]
cat("\nSaturation factor distribution by plantation status (GA terminal_age=80, growth_start_age=60):\n")
print(sat_by_class)
fwrite(sat_by_class, file.path(OUT_DIR, "ga_sat_age_distribution.csv"))

# Plot: stand age histogram by plantation/natural
p_age <- ggplot(cond_b, aes(x = STDAGE, fill = plant_class)) +
  geom_histogram(binwidth = 5, alpha = 0.7, position = "identity") +
  geom_vline(xintercept = growth_start_age, linetype = "dashed", color = "grey30") +
  geom_vline(xintercept = terminal_age,     linetype = "dashed", color = "red") +
  annotate("text", x = growth_start_age + 2, y = 0, label = "sat_age starts attenuating",
           color = "grey30", angle = 90, hjust = 0, size = 3) +
  annotate("text", x = terminal_age + 2, y = 0, label = "terminal_age (sat_age = 0)",
           color = "red", angle = 90, hjust = 0, size = 3) +
  scale_fill_manual(values = c("plantation_indicative" = "#c08020",
                                "other_forest_type"     = "#3a78a3")) +
  labs(
    title    = "GA stand age distribution (baseline 1999-2008 forested conds)",
    subtitle = "GA terminal_age = 80, growth_start_age = 60. Plantation rotations 25-35 yr.",
    x = "STDAGE (years)", y = "Count of conditions",
    fill = "Forest type class"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave(file.path(OUT_DIR, "ga_bias_candidate_diagnostic.png"),
       plot = p_age, width = 9, height = 5, dpi = 150, bg = "white")

# Summary text
sink(file.path(OUT_DIR, "ga_bias_candidate_summary.txt"))
cat("GA BIAS CANDIDATE DIAGNOSTIC\n")
cat("============================\n\n")
cat("Candidate 1: growth ratio multiplicative effect by baseline decile\n")
if (exists("c1")) print(c1)
cat("\nCandidate 4: GA stand age distribution by plantation/natural\n")
print(c4)
cat("\nSaturation factor distribution:\n")
print(sat_by_class)
cat("\nKey signals:\n")
cat("- If pct_age_lt_60 is high for plantation_indicative, those plots are\n")
cat("  in the unconstrained sat_age=1.0 zone (no growth attenuation).\n")
cat("- If implied gr_carbon (Candidate 1) is similar across deciles but\n")
cat("  growth_increment scales with baseline, the multiplicative effect is real.\n")
sink()

cat("Outputs at:", OUT_DIR, "\n")
