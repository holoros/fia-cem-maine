## yc_10_adapters_v4.R  (Yield-Curve Phase 2, step 6 — v4 model adapters)
##
## Same logic as yc_08_adapters.R but consumes v4 (anchored harvested)
## yield curves and writes to adapters_v4/ to keep v3 outputs intact.
##
## Convert maine_yield_curves_v4_long.csv into four model-specific input
## formats for cross-model use:
##
##   GCBM/libcbm:  growth_curves.csv keyed by classifier set
##                 (forest_type, ecoregion, owner, treatment) → rows of
##                 (age, merch_volume, foliage, other) with biomass
##                 conversion via Jenkins component ratios.
##   LANDIS-II:    PnETBiomassParameters.txt — one block per stratum
##                 with maximum biomass (asymptote × Jenkins ratio) and
##                 EstablishmentProbability tables driven by treatment.
##   CEM:          cem_productivity_multipliers_v4.csv — per-cell scaling
##                 factor for the CEM pipeline's growth multiplier,
##                 derived from the empirical asymptote relative to
##                 the population mean.
##   Woodstock:    woodstock_yields_v4.csv — periodic AGB and merch volume
##                 per (stratum × action × period) for direct ingestion
##                 into a Woodstock LP.
##
## Inputs : yield_curves/maine_yield_curves_v4_long.csv
##          yield_curves/maine_yield_curves_v4_fits.csv
## Outputs: yield_curves/adapters_v4/{gcbm,landis,cem,woodstock}_*.csv

args <- commandArgs(trailingOnly = TRUE)
yc_dir <- if (length(args) >= 1) args[1] else file.path(Sys.getenv("HOME"), "yield_curves")
out_dir <- file.path(yc_dir, "adapters_v4")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

curves <- read.csv(file.path(yc_dir, "maine_yield_curves_v4_long.csv"),
                   stringsAsFactors = FALSE)
fits   <- read.csv(file.path(yc_dir, "maine_yield_curves_v4_fits.csv"),
                   stringsAsFactors = FALSE)
cat(sprintf("Curves rows: %d\n", nrow(curves)))
cat(sprintf("Fits rows  : %d\n", nrow(fits)))

# Conversion factors
# AGB tons/ac × 0.45 = C tons/ac (carbon fraction)
# tons/ac × 2.2417 = Mg/ha
# vol cuft/ac × 0.069972 = m³/ha
TON_AC_TO_C_TON_AC  <- 0.45
TON_AC_TO_MG_HA     <- 2.2417
CUFT_AC_TO_M3_HA    <- 0.069972
JENKINS_BG_RATIO    <- 0.22  # below-ground / above-ground

# ============================================================
# 1. GCBM / libcbm growth_curves.csv
# ============================================================
# GCBM expects: classifier_set, age, merch_vol_m3_ha, foliage_kgC_m2,
#               other_aboveground_kgC_m2 (rough breakdown via component
#               ratios of total AGB).
# We use the v3 medians as point estimates.

agb <- curves[curves$response == "agb_tonac", ]
vol <- curves[curves$response == "vol_cuftac", ]

if (nrow(agb) > 0 && nrow(vol) > 0) {
  gcbm <- merge(
    agb[, c("cell_key","ft_group","ecoregion","owner","treatment",
            "age","predicted")],
    vol[, c("cell_key","treatment","age","predicted")],
    by = c("cell_key","treatment","age"),
    suffixes = c("_agb","_vol"))
  gcbm$classifier_set <- paste(gcbm$ft_group, gcbm$ecoregion,
                                gcbm$owner, gcbm$treatment, sep = "/")
  gcbm$merch_vol_m3_ha <- round(gcbm$predicted_vol * CUFT_AC_TO_M3_HA, 3)
  # Jenkins component ratios for eastern hardwood mix:
  # foliage = 0.05 of AGB; other_aboveground (branches+bark) = 0.18
  agb_mg_ha <- gcbm$predicted_agb * TON_AC_TO_MG_HA
  c_mg_ha   <- agb_mg_ha * 0.45         # carbon
  gcbm$foliage_kgC_m2     <- round(c_mg_ha * 0.05 * 100 / 10000, 4)  # Mg/ha → kg/m²
  gcbm$other_above_kgC_m2 <- round(c_mg_ha * 0.18 * 100 / 10000, 4)
  gcbm$total_above_kgC_m2 <- round(c_mg_ha       * 100 / 10000, 4)
  gcbm <- gcbm[, c("classifier_set","ft_group","ecoregion","owner",
                   "treatment","age","merch_vol_m3_ha",
                   "foliage_kgC_m2","other_above_kgC_m2",
                   "total_above_kgC_m2")]
  write.csv(gcbm, file.path(out_dir, "gcbm_growth_v4_curves.csv"),
            row.names = FALSE)
  cat(sprintf("Wrote gcbm_growth_v4_curves.csv (%d rows)\n", nrow(gcbm)))
}

# ============================================================
# 2. LANDIS-II PnET BiomassParameters table
# ============================================================
# LANDIS PnET-Succession wants per-species, per-stratum biomass scalars.
# Since our cells are forest-type aggregates, we emit one block per
# (cell, treatment) with the asymptote serving as the cell maximum
# AGB and a piecewise breakdown by age class.

agb_fits <- fits[fits$response == "agb_tonac", ]
landis <- agb_fits[, c("cell_key","ft_group","ecoregion","owner",
                        "treatment","a","b","c","n_plots")]
names(landis)[names(landis) == "a"] <- "MaxAGB_tonac"
landis$MaxAGB_MgHa     <- round(landis$MaxAGB_tonac * TON_AC_TO_MG_HA, 1)
landis$BG_root_MgHa    <- round(landis$MaxAGB_MgHa * JENKINS_BG_RATIO, 1)
landis$age_to_50pct_a  <- round(-log(1 - 0.5^(1/landis$c)) / landis$b, 0)
landis$age_to_90pct_a  <- round(-log(1 - 0.9^(1/landis$c)) / landis$b, 0)
landis <- landis[, c("cell_key","ft_group","ecoregion","owner",
                      "treatment","MaxAGB_tonac","MaxAGB_MgHa",
                      "BG_root_MgHa","age_to_50pct_a","age_to_90pct_a",
                      "n_plots")]
write.csv(landis, file.path(out_dir, "landis_biomass_parameters_v4.csv"),
          row.names = FALSE)
cat(sprintf("Wrote landis_biomass_parameters_v4.csv (%d rows)\n", nrow(landis)))

# Also emit a LANDIS-style text block (one per cell × treatment)
landis_txt <- file.path(out_dir, "landis_biomass_parameters_v4.txt")
con <- file(landis_txt, "w")
writeLines("LandisData PnETBiomassParameters\n", con)
writeLines(">> Generated from FIA empirical chronosequence yield curves", con)
writeLines(">> Source: maine_yield_curves_v4_fits.csv\n", con)
writeLines("BiomassParameters", con)
writeLines(sprintf("%-50s %-12s %-12s %-12s %-12s",
                    ">>StratumKey", "MaxAGB_MgHa", "Age50pct",
                    "Age90pct", "Treatment"), con)
for (i in seq_len(nrow(landis))) {
  r <- landis[i, ]
  writeLines(sprintf("%-50s %-12.1f %-12d %-12d %-12s",
                      gsub("\\|", "_", r$cell_key),
                      r$MaxAGB_MgHa, r$age_to_50pct_a,
                      r$age_to_90pct_a, r$treatment), con)
}
close(con)
cat(sprintf("Wrote landis_biomass_parameters_v4.txt\n"))

# ============================================================
# 3. CEM productivity multipliers
# ============================================================
# CEM pipeline (this repo) uses a per-plot growth multiplier in
# 06_projection_engine.R. We emit a per-cell × treatment scaling
# factor relative to the population-mean asymptote.
mean_a <- mean(agb_fits$a, na.rm = TRUE)
cem <- agb_fits[, c("cell_key","ft_group","ecoregion","owner",
                     "treatment","a","n_plots")]
cem$prod_mult <- round(cem$a / mean_a, 3)
cem$asymptote_tonac <- round(cem$a, 1)
cem <- cem[, c("cell_key","ft_group","ecoregion","owner","treatment",
                "asymptote_tonac","prod_mult","n_plots")]
write.csv(cem, file.path(out_dir, "cem_productivity_multipliers_v4.csv"),
          row.names = FALSE)
cat(sprintf("Wrote cem_productivity_multipliers_v4.csv (%d rows; mean a = %.1f)\n",
            nrow(cem), mean_a))

# ============================================================
# 4. Woodstock YIELDS table
# ============================================================
# Woodstock wants periodic flows per (theme set / action / period). We
# pivot the predicted AGB and volume to 5-yr periodic columns suitable
# for direct paste into a Woodstock YIELDS section.

# Period 1 = age 5, Period 2 = age 10, ... Period 30 = age 150
periods <- seq(5, 150, by = 5)
ws_agb <- agb[, c("cell_key","ft_group","ecoregion","owner","treatment",
                   "age","predicted")]
names(ws_agb)[ncol(ws_agb)] <- "AGB_tonac"
ws_vol <- vol[, c("cell_key","treatment","age","predicted")]
names(ws_vol)[ncol(ws_vol)] <- "vol_cuftac"
ws <- merge(ws_agb, ws_vol, by = c("cell_key","treatment","age"))
ws$period <- match(ws$age, periods)
ws <- ws[!is.na(ws$period), ]
ws$AGB_MgHa  <- round(ws$AGB_tonac  * TON_AC_TO_MG_HA, 1)
ws$Vol_m3Ha  <- round(ws$vol_cuftac * CUFT_AC_TO_M3_HA, 1)
ws$CarbonMgHa <- round(ws$AGB_MgHa  * 0.45, 1)
ws$stratum   <- gsub("\\|", "_", ws$cell_key)
ws_out <- ws[, c("stratum","ft_group","ecoregion","owner","treatment",
                  "period","age","AGB_tonac","AGB_MgHa","Vol_m3Ha",
                  "CarbonMgHa")]
write.csv(ws_out, file.path(out_dir, "woodstock_yields_v4_long.csv"),
          row.names = FALSE)
cat(sprintf("Wrote woodstock_yields_v4_long.csv (%d rows)\n", nrow(ws_out)))

# Wide version: one row per stratum × treatment, columns = periods
ws_wide_agb <- reshape(ws[, c("stratum","treatment","period","AGB_tonac")],
                       idvar = c("stratum","treatment"),
                       timevar = "period", direction = "wide")
names(ws_wide_agb) <- gsub("AGB_tonac\\.", "P", names(ws_wide_agb))
write.csv(ws_wide_agb, file.path(out_dir, "woodstock_yields_v4_AGB_wide.csv"),
          row.names = FALSE)
cat(sprintf("Wrote woodstock_yields_v4_AGB_wide.csv (%d rows)\n",
            nrow(ws_wide_agb)))

cat("\n=== Adapter summary ===\n")
ad_files <- list.files(out_dir, full.names = TRUE)
for (f in ad_files) {
  fi <- file.info(f)
  cat(sprintf("  %s  %s bytes\n", basename(f),
              format(fi$size, big.mark = ",")))
}
