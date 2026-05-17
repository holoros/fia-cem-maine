#!/usr/bin/env Rscript
# cem_3way_strat_cell_sizes.R
# Empirical cell-size check for 3-way CEM stratification: ecoregion x
# TYPGRPCD x HCB owner class. Companion to cem_ecoregion_fortyp_cell_sizes.R
# (2-way) — adds owner as a third matching dimension per user direction.
#
# HCB classes from Harris, Caputo, Butler 2025: typically 4 classes covering
# federal, state/local, corporate, family. Already encoded in
# config/fia_plots_hcb_l3.csv as the hcb_class column.
#
# Run on Cardinal. Outputs:
#   cem_3way_strat_cell_sizes_overall.csv
#   cem_3way_strat_cell_sizes_summary.txt
#   cem_3way_strat_per_subject_state.csv

suppressPackageStartupMessages({
  library(data.table)
})

ENTIRE_COND <- "/users/PUOM0008/crsfaaron/FIA/ENTIRE_COND.csv"
REF_FORTYP  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/REF_FOREST_TYPE.csv"
HCB_L3      <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/fia_plots_hcb_l3.csv"
OUT_DIR     <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/cem_3way_strat_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("Reading ENTIRE_COND.csv...\n")
cond <- data.table::fread(
  ENTIRE_COND,
  select = c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
             "PLT_CN", "CONDPROP_UNADJ", "OWNGRPCD"),
  showProgress = FALSE
)
cond <- cond[COND_STATUS_CD == 1 & INVYR %in% 1999:2008 &
              !is.na(FORTYPCD) & FORTYPCD > 0]
cat(sprintf("Forested baseline conds: %d\n", nrow(cond)))

cat("\nReading HCB L3 ecoregion crosswalk (for us_l3code only)...\n")
hcb <- data.table::fread(HCB_L3,
                          select = c("PLT_CN", "us_l3code"),
                          showProgress = FALSE)
hcb[, PLT_CN := as.character(PLT_CN)]
cond[, PLT_CN := as.character(PLT_CN)]
cond <- merge(cond, hcb, by = "PLT_CN", all.x = TRUE)

# Fill NAs with explicit "unknown" buckets
cond[is.na(us_l3code), us_l3code := -1L]
cond[is.na(OWNGRPCD),  OWNGRPCD  := -1L]

# Use OWNGRPCD as the owner dimension. FIA codes:
#   10 = USDA Forest Service (federal)
#   20 = Other federal (BLM, NPS, DOD, etc.)
#   30 = State and local
#   40 = Private (NIPF + industrial)
# HCB is more granular (10 classes) but only 0.75% coverage in fia_plots_hcb_l3.csv.
# OWNGRPCD has 100% coverage and is the production-ready choice for 3-way CEM.
cond[, hcb_class := OWNGRPCD]  # reuse downstream variable name

# Join TYPGRPCD
ref <- data.table::fread(REF_FORTYP, showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
cond <- merge(cond, ref[, .(FORTYPCD, TYPGRPCD)], by = "FORTYPCD", all.x = TRUE)
cond[is.na(TYPGRPCD), TYPGRPCD := -1]

cat(sprintf("\nUnique ecoregions: %d  (+1 unknown bucket)\n",
            length(unique(cond$us_l3code)) - any(cond$us_l3code == -1)))
cat(sprintf("Unique TYPGRPCDs : %d\n", length(unique(cond$TYPGRPCD))))
cat(sprintf("Unique OWNGRPCDs (owner classes): %d\n", length(unique(cond$hcb_class))))
cat("Owner distribution (OWNGRPCD):\n")
print(cond[, .N, by = hcb_class][order(-N)])

# 3-way cell tabulation
cells <- cond[, .(n_cond = .N), by = .(us_l3code, TYPGRPCD, hcb_class)]
cat(sprintf("\nUnique cells (3-way): %d\n", nrow(cells)))
cat("Cell size distribution:\n")
print(summary(cells$n_cond))
cat(sprintf("\nCells >= 30 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 30),
            100*mean(cells$n_cond >= 30)))
cat(sprintf("Cells >= 100 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 100),
            100*mean(cells$n_cond >= 100)))
cat(sprintf("Cells >= 500 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 500),
            100*mean(cells$n_cond >= 500)))

fwrite(cells, file.path(OUT_DIR, "cem_3way_strat_cell_sizes_overall.csv"))

# Subject cells and cross-state donor cells for multistate p1 four states
SUBJECT_STATES <- c(23L, 27L, 53L, 13L)  # ME MN WA GA

state_cells <- cond[, .N, by = .(STATECD, us_l3code, TYPGRPCD, hcb_class)]
data.table::setnames(state_cells, "N", "n_self_state")
donor_cells <- cond[, .(n_donor_total = .N),
                      by = .(us_l3code, TYPGRPCD, hcb_class)]
match_avail <- merge(state_cells, donor_cells,
                      by = c("us_l3code", "TYPGRPCD", "hcb_class"))
match_avail[, n_other_state_donors := n_donor_total - n_self_state]
match_avail_subj <- match_avail[STATECD %in% SUBJECT_STATES]
data.table::setorder(match_avail_subj, STATECD, -n_self_state)
fwrite(match_avail_subj, file.path(OUT_DIR, "cem_3way_strat_per_subject_state.csv"))

# Summary of low-donor cells for subject states
low_donor <- match_avail_subj[n_other_state_donors < 30 & n_self_state >= 20]
subj_total <- sum(match_avail_subj$n_self_state)
low_total  <- sum(low_donor$n_self_state)
cat(sprintf("\nSubject cells with subject conds >= 20 but other-state donors < 30: %d\n",
            nrow(low_donor)))
cat(sprintf("Subject conds in low-donor cells: %d of %d (%.2f%%)\n",
            low_total, subj_total, 100 * low_total / subj_total))

# Save text summary
sink(file.path(OUT_DIR, "cem_3way_strat_cell_sizes_summary.txt"))
cat("CEM 3-WAY STRATIFICATION CELL SIZE TEST\n")
cat("========================================\n")
cat("Dimensions: ecoregion (us_l3code) x TYPGRPCD x HCB owner class\n\n")
cat(sprintf("Total CONUS forested baseline conds: %d\n", nrow(cond)))
cat(sprintf("Unique ecoregions: %d\n", length(unique(cond$us_l3code))))
cat(sprintf("Unique TYPGRPCDs : %d\n", length(unique(cond$TYPGRPCD))))
cat(sprintf("Unique HCB classes: %d\n", length(unique(cond$hcb_class))))
cat(sprintf("Unique cells: %d\n", nrow(cells)))
cat("\nCell size distribution:\n")
print(summary(cells$n_cond))
cat(sprintf("\nCells >= 30 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 30),
            100*mean(cells$n_cond >= 30)))
cat(sprintf("Cells >= 100 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 100),
            100*mean(cells$n_cond >= 100)))
cat("\nSubject cells with insufficient cross-state donors:\n")
cat(sprintf("Subject conds in low-donor cells: %d of %d (%.2f%%)\n",
            low_total, subj_total, 100 * low_total / subj_total))
cat("\nLow-donor cells preview (top 20 by subject n):\n")
print(head(low_donor[order(-n_self_state),
                     .(STATECD, us_l3code, TYPGRPCD, hcb_class,
                       n_self_state, n_other_state_donors)], 20))

# Compare to 2-way result from yesterday
cat("\n--- Comparison to 2-way stratification ---\n")
cat("2-way (ecoregion x TYPGRPCD): 156 cells, 33% >= 30, 4% subj in zero-donor cells\n")
cat(sprintf("3-way (ecoregion x TYPGRPCD x HCB owner): %d cells, %.1f%% >= 30, %.2f%% subj in low-donor cells\n",
            nrow(cells), 100*mean(cells$n_cond >= 30),
            100 * low_total / subj_total))
sink()

cat("\nOutputs at:", OUT_DIR, "\n")
