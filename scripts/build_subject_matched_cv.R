# =============================================================================
# Subject-matched observed FIA totals for cross-validation
# =============================================================================
# Purpose: Compute observed FIA AGC using ONLY the plots that are in the
# pipeline subject pool. Removes the structural -90 MMT bias from CV metrics
# that comes from comparing subject-only projections against full-panel EXPALL.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse); library(data.table); library(here)
})

project_dir <- tryCatch(here::here(), error = function(e) getwd())
setwd(project_dir)

# Use cycle-1 plot list from r11 wear_r11 RDS as the subject pool definition
rds_file <- file.path(project_dir, "output",
                       "ME_20260419_rcp45_hadgem2_wear_r11",
                       "per_plot_projections.rds")
cat(sprintf("Loading subject plot list from %s\n", rds_file))
d <- readRDS(rds_file)
subj_plots <- unique(format(d$PLT_CN[d$cycle == 1 & d$STATECD == 23],
                             scientific = FALSE, trim = TRUE))
cat(sprintf("Subject plots from r11 cycle 1 (Maine only): %d\n", length(subj_plots)))

# Load FIA tables
fia_dir <- "~/fia_data"
tre <- data.table::fread(file.path(fia_dir, "ME_TREE.csv"),
                          select = c("PLT_CN","CONDID","STATUSCD","DIA",
                                      "TPA_UNADJ","CARBON_AG","DRYBIO_AG",
                                      "VOLCFNET","VOLCSNET"),
                          colClasses = list(character = "PLT_CN"))
cnd <- data.table::fread(file.path(fia_dir, "ME_COND.csv"),
                          select = c("PLT_CN","CONDID","CONDPROP_UNADJ",
                                      "COND_STATUS_CD"),
                          colClasses = list(character = "PLT_CN"))
plt <- data.table::fread(file.path(fia_dir, "ME_PLOT.csv"),
                          select = c("CN","INVYR","STATECD"),
                          colClasses = list(character = "CN"))
ppsa <- data.table::fread(file.path(fia_dir, "ME_POP_PLOT_STRATUM_ASSGN.csv"),
                           colClasses = list(character = c("PLT_CN","STRATUM_CN")))
ps <- data.table::fread(file.path(fia_dir, "ME_POP_STRATUM.csv"),
                         colClasses = list(character = "CN"))
pe <- data.table::fread(file.path(fia_dir, "ME_POP_EVAL.csv"),
                         colClasses = list(character = "CN"))
pet <- data.table::fread(file.path(fia_dir, "ME_POP_EVAL_TYP.csv"),
                          colClasses = list(character = "EVAL_CN"))

LB_TO_MMT <- 4.53592e-10

# Per-condition AGC (live trees DIA >= 1)
cond_agc <- tre[STATUSCD == 1 & DIA >= 1.0,
                .(carbon_per_ac = sum(TPA_UNADJ * CARBON_AG, na.rm = TRUE)),
                by = .(PLT_CN, CONDID)]
cond_agc <- cnd[COND_STATUS_CD == 1, .(PLT_CN, CONDID, CONDPROP_UNADJ)
                ][cond_agc, on = c("PLT_CN","CONDID"), nomatch = NULL]

# For each EXPALL EVALID, compute total AGC using ONLY subject plots
evt <- merge(pet[, .(EVAL_CN, EVAL_TYP)],
              pe[, .(CN, EVALID, END_INVYR)],
              by.x = "EVAL_CN", by.y = "CN")
evt <- evt[EVAL_TYP == "EXPALL"][order(END_INVYR)]
cat(sprintf("EXPALL EVALIDs: %d (years %d to %d)\n",
            nrow(evt), min(evt$END_INVYR), max(evt$END_INVYR)))

results <- purrr::map_dfr(seq_len(nrow(evt)), function(i) {
  e <- evt[i, ]
  expns_e <- ppsa[EVALID == e$EVALID][ps, on = c("STRATUM_CN" = "CN"), nomatch = NULL]
  expns_e <- unique(expns_e[, .(PLT_CN = as.character(PLT_CN), EXPNS)],
                     by = "PLT_CN")
  # Full panel AGC
  dt_full <- cond_agc[expns_e, on = "PLT_CN", nomatch = NULL]
  full_agc <- sum(dt_full$carbon_per_ac * dt_full$CONDPROP_UNADJ * dt_full$EXPNS,
                   na.rm = TRUE) * LB_TO_MMT
  # Subject-only AGC (intersection with the pipeline's subject plot list)
  dt_subj <- dt_full[PLT_CN %in% subj_plots]
  subj_agc <- sum(dt_subj$carbon_per_ac * dt_subj$CONDPROP_UNADJ * dt_subj$EXPNS,
                   na.rm = TRUE) * LB_TO_MMT
  data.frame(
    year                = as.integer(e$END_INVYR),
    EVALID              = e$EVALID,
    n_full_plots        = nrow(expns_e),
    n_subj_plots_in_eval = sum(expns_e$PLT_CN %in% subj_plots),
    full_panel_agc_mmt  = round(full_agc, 1),
    subject_only_agc_mmt = round(subj_agc, 1),
    diff_mmt            = round(full_agc - subj_agc, 1)
  )
})

out_dir <- file.path(project_dir, "output", "subject_matched_cv")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path(out_dir, "subject_matched_observed.csv")
data.table::fwrite(results, out_file)
cat(sprintf("\nWrote %s\n", out_file))
print(results)
