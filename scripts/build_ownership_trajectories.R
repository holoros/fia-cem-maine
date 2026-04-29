# =============================================================================
# Title: Ownership-specific carbon trajectories by OWNGRPCD
# Author: A. Weiskittel
# Date: 2026-04-18
# Description: Breaks out state expansion by FIA OWNGRPCD category.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(data.table)
  library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

source(file.path(project_dir, "R", "10_state_expansion.R"))

# FIA OWNGRPCD simplified 3-category grouping
OWN_SIMPLE <- tibble::tribble(
  ~OWNGRPCD, ~own_cat,
  10L, "Public", 20L, "Public", 30L, "Public",
  40L, "Private Industrial", 41L, "Private Industrial", 42L, "Private Industrial",
  43L, "Private Industrial",
  44L, "Private Nonindustrial", 45L, "Private Nonindustrial",
  46L, "Private Nonindustrial", 49L, "Private Nonindustrial", 50L, "Private Nonindustrial"
)

LB_TO_MMT <- 4.53592e-10
TON_TO_LB <- 2000

# Use expand_to_state's get_plot_expns helper for EXPNS
expns <- get_plot_expns(state = "ME", fia_dir = "~/fia_data") |>
  as.data.table()
setkey(expns, PLT_CN)

# Load COND for pool cols + OWNGRPCD
cond <- fread("~/fia_data/ME_COND.csv",
               select = c("PLT_CN","CONDID","OWNGRPCD","CONDPROP_UNADJ",
                          "CARBON_DOWN_DEAD","CARBON_LITTER","CARBON_SOIL_ORG",
                          "CARBON_UNDERSTORY_AG","CARBON_UNDERSTORY_BG"),
               colClasses = list(character = "PLT_CN"))

cond_agg <- cond[, lapply(.SD, function(x) mean(x, na.rm = TRUE)),
                  by = .(PLT_CN, CONDID),
                  .SDcols = c("OWNGRPCD","CARBON_DOWN_DEAD","CARBON_LITTER",
                              "CARBON_SOIL_ORG","CARBON_UNDERSTORY_AG","CARBON_UNDERSTORY_BG")]
cond_agg[, OWNGRPCD := as.integer(round(OWNGRPCD))]
setkey(cond_agg, PLT_CN, CONDID)

out_dir <- file.path(project_dir, "output", "ownership_20260418")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Find wear-family RDS files (exclude policy for now since OWNGRPCD breakdown
# is most interesting in baseline scenarios)
rds_files <- list.files(file.path(project_dir, "output"),
                         pattern = "^per_plot_projections\\.rds$",
                         recursive = TRUE, full.names = TRUE)
rds_files <- rds_files[grepl("wear", rds_files) & !grepl("policy", rds_files)]
cat(sprintf("\nProcessing %d RDS files\n", length(rds_files)))

all_own <- list()
for (f in rds_files) {
  scen <- basename(dirname(f))
  cat(sprintf("  %s\n", scen))
  d <- as.data.table(readRDS(f))
  d <- d[STATECD == 23]
  d[, PLT_CN := format(PLT_CN, scientific = FALSE, trim = TRUE)]
  setkey(d, PLT_CN, CONDID)
  d <- cond_agg[d, on = c("PLT_CN","CONDID"), nomatch = NULL]
  d <- expns[, .(PLT_CN, EXPNS)][d, on = "PLT_CN", nomatch = NULL]
  d[, area_acres := EXPNS * fcoalesce(CONDPROP_UNADJ, 1)]
  d[, plot_c_lb     := proj_carbon * area_acres]
  d[, plot_bgc_lb   := proj_carbon * 0.22 * area_acres]
  d[, plot_dead_lb  := fcoalesce(CARBON_DOWN_DEAD, 0) * TON_TO_LB * area_acres]
  d[, plot_lit_lb   := fcoalesce(CARBON_LITTER, 0) * TON_TO_LB * area_acres]
  d[, plot_soil_lb  := fcoalesce(CARBON_SOIL_ORG, 0) * TON_TO_LB * area_acres]
  d[, plot_un_lb    := (fcoalesce(CARBON_UNDERSTORY_AG, 0) +
                         fcoalesce(CARBON_UNDERSTORY_BG, 0)) * TON_TO_LB * area_acres]
  d[, plot_tot_lb   := plot_c_lb + plot_bgc_lb + plot_dead_lb + plot_lit_lb + plot_soil_lb + plot_un_lb]

  d[, scenario := scen]
  tot_by_own <- d[, .(
    mmt_agc      = sum(plot_c_lb,   na.rm = TRUE) * LB_TO_MMT,
    mmt_total_c  = sum(plot_tot_lb, na.rm = TRUE) * LB_TO_MMT,
    n_conditions = .N,
    area_ac      = sum(area_acres, na.rm = TRUE)
  ), by = .(scenario, sim, cycle, OWNGRPCD)]
  all_own[[scen]] <- tot_by_own
  rm(d); gc()
}
all_own <- rbindlist(all_own)

# Across-sim aggregation
ci_own <- all_own[, .(
  mmt_agc_mean     = mean(mmt_agc, na.rm = TRUE),
  mmt_agc_lo       = quantile(mmt_agc, 0.025, na.rm = TRUE),
  mmt_agc_hi       = quantile(mmt_agc, 0.975, na.rm = TRUE),
  mmt_total_c_mean = mean(mmt_total_c, na.rm = TRUE),
  mmt_total_c_lo   = quantile(mmt_total_c, 0.025, na.rm = TRUE),
  mmt_total_c_hi   = quantile(mmt_total_c, 0.975, na.rm = TRUE),
  mean_area_ac     = mean(area_ac, na.rm = TRUE),
  n_sims           = uniqueN(sim)
), by = .(scenario, cycle, OWNGRPCD)]

ci_own <- merge(ci_own, OWN_SIMPLE, by = "OWNGRPCD", all.x = TRUE)
ci_own[, year := 1999 + cycle * 5]

fwrite(ci_own, file.path(out_dir, "ownership_trajectories_ci.csv"))
cat(sprintf("\nWrote ownership_trajectories_ci.csv (%d rows)\n", nrow(ci_own)))

# 3-category summary
summary_by_cat <- ci_own[, .(
  mmt_agc_mean     = sum(mmt_agc_mean, na.rm = TRUE),
  mmt_total_c_mean = sum(mmt_total_c_mean, na.rm = TRUE),
  area_ac          = sum(mean_area_ac, na.rm = TRUE)
), by = .(scenario, cycle, year, own_cat)]
fwrite(summary_by_cat, file.path(out_dir, "ownership_3cat_trajectories.csv"))

cat("\n=== 3-category ownership at cycle 1 and 10 ===\n")
print(summary_by_cat[cycle %in% c(1, 10)][order(scenario, cycle, own_cat)])
