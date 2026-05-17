#!/usr/bin/env Rscript
# cem_ecoregion_fortyp_cell_sizes.R
# Empirical check of cell sizes for a CEM matching scheme that uses both
# Bailey ecoregion (or EPA L3) AND forest type group (TYPGRPCD) as
# covariates. The question being tested: would the cross-stratification
# leave too many empty or sparse subject cells that have no donors?
#
# Uses full CONUS ENTIRE_COND.csv at ~/FIA/ and BAILEY section codes from
# the existing fia_plots_hcb_l3.csv crosswalk.
#
# Run on Cardinal. Outputs:
#   cem_strat_cell_sizes_overall.csv      (full CONUS cell sizes by ecoregion x typgrp)
#   cem_strat_cell_sizes_summary.txt
#   cem_strat_per_subject_state.csv       (per state x ecoregion x typgrp subject cell counts)

suppressPackageStartupMessages({
  library(data.table)
})

ENTIRE_COND <- "/users/PUOM0008/crsfaaron/FIA/ENTIRE_COND.csv"
REF_FORTYP  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/REF_FOREST_TYPE.csv"
OUT_DIR     <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/cem_strat_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Look for HCB or EPA L3 crosswalk (already in config)
HCB_L3 <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/fia_plots_hcb_l3.csv"

cat("Reading ENTIRE_COND.csv (740MB)...\n")
cond <- data.table::fread(
  ENTIRE_COND,
  select = c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
             "PLT_CN", "CONDPROP_UNADJ"),
  showProgress = FALSE
)
cat(sprintf("Read %d rows\n", nrow(cond)))

# Filter to forested baseline window
cond <- cond[COND_STATUS_CD == 1 & INVYR %in% 1999:2008 &
              !is.na(FORTYPCD) & FORTYPCD > 0]
cat(sprintf("Forested baseline conds (1999-2008): %d\n", nrow(cond)))

# Read HCB L3 crosswalk
cat("\nReading HCB L3 ecoregion crosswalk...\n")
hcb <- try(data.table::fread(HCB_L3, showProgress = FALSE), silent = TRUE)
if (inherits(hcb, "try-error")) {
  cat("HCB crosswalk read failed; using STATECD as proxy for ecoregion stratification\n")
  cond[, ecoregion := paste0("STATE_", STATECD)]
} else {
  cat(sprintf("HCB L3 rows: %d  cols: %s\n", nrow(hcb),
              paste(head(colnames(hcb), 10), collapse = ",")))
  # Try common column names for the join key
  l3_col <- intersect(c("us_l3code", "us_l3name", "EPA_L3", "epa_l3",
                         "L3_KEY", "Ecoregion", "L3"),
                       colnames(hcb))[1]
  cn_col <- intersect(c("PLT_CN", "plt_cn", "CN", "PltCN"), colnames(hcb))[1]
  if (!is.na(l3_col) && !is.na(cn_col)) {
    cat(sprintf("Joining on %s (HCB) to PLT_CN (COND); ecoregion col = %s\n",
                cn_col, l3_col))
    setnames(hcb, c(cn_col, l3_col), c("PLT_CN", "ecoregion"))
    hcb[, PLT_CN := as.character(PLT_CN)]
    cond[, PLT_CN := as.character(PLT_CN)]
    cond <- merge(cond, hcb[, .(PLT_CN, ecoregion)],
                   by = "PLT_CN", all.x = TRUE)
    cond[is.na(ecoregion), ecoregion := "UNKNOWN_ECOREGION"]
  } else {
    cat("Could not identify HCB columns; falling back to STATECD ecoregion\n")
    cond[, ecoregion := paste0("STATE_", STATECD)]
  }
}

# Get TYPGRPCD via forest type reference
ref <- data.table::fread(REF_FORTYP, showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
cond <- merge(cond, ref[, .(FORTYPCD, TYPGRPCD, MEANING)],
                by = "FORTYPCD", all.x = TRUE)
cond[is.na(TYPGRPCD), TYPGRPCD := -1]

cat("\nUnique ecoregions:", length(unique(cond$ecoregion)), "\n")
cat("Unique TYPGRPCDs :", length(unique(cond$TYPGRPCD)), "\n")

# Compute cross-tabulation of cell sizes
cells <- cond[, .(n_cond = .N), by = .(ecoregion, TYPGRPCD)]
cat(sprintf("\nUnique ecoregion x TYPGRPCD cells: %d\n", nrow(cells)))
cat("Cell size distribution:\n")
print(summary(cells$n_cond))
cat("\nCells with at least 30 conditions:",
    sum(cells$n_cond >= 30), "of", nrow(cells), "\n")
cat("Cells with at least 100 conditions:",
    sum(cells$n_cond >= 100), "\n")
cat("Cells with at least 500 conditions:",
    sum(cells$n_cond >= 500), "\n")

fwrite(cells, file.path(OUT_DIR, "cem_strat_cell_sizes_overall.csv"))

# Per state subject cell counts (proxy for the multistate p1 4 states: ME=23, MN=27, WA=53, GA=13)
SUBJECT_STATES <- c(23L, 27L, 53L, 13L)
per_state <- cond[STATECD %in% SUBJECT_STATES, .(
  n_subj_conds = .N
), by = .(STATECD, ecoregion, TYPGRPCD)][order(STATECD, ecoregion, TYPGRPCD)]
fwrite(per_state, file.path(OUT_DIR, "cem_strat_per_subject_state.csv"))

# For each (subject_state, ecoregion, TYPGRPCD) cell, count available donor
# conditions in the same (ecoregion, TYPGRPCD) cell from OTHER states
donor_cells <- cond[, .(n_donor_total = .N),
                      by = .(ecoregion, TYPGRPCD)]
# Donor count excluding self-state
state_typ_eco <- cond[, .N, by = .(STATECD, ecoregion, TYPGRPCD)]
data.table::setnames(state_typ_eco, "N", "n_self_state")
match_avail <- merge(state_typ_eco, donor_cells,
                      by = c("ecoregion", "TYPGRPCD"))
match_avail[, n_other_state_donors := n_donor_total - n_self_state]
match_avail <- match_avail[STATECD %in% SUBJECT_STATES]
data.table::setorder(match_avail, STATECD, -n_self_state)

cat("\nSubject states (ME=23, MN=27, WA=53, GA=13) subject cells with low donor counts:\n")
low_donor <- match_avail[n_other_state_donors < 30 & n_self_state >= 20]
cat(sprintf("Cells with subject conds >= 20 but other-state donor conds < 30: %d\n",
            nrow(low_donor)))
print(head(low_donor[order(n_other_state_donors)], 20))

# Summary
sink(file.path(OUT_DIR, "cem_strat_cell_sizes_summary.txt"))
cat("CEM ECOREGION X FORTYPCD STRATIFICATION CELL SIZE TEST\n")
cat("=======================================================\n")
cat(sprintf("Total CONUS forested baseline conds: %d\n", nrow(cond)))
cat(sprintf("Unique ecoregions: %d\n", length(unique(cond$ecoregion))))
cat(sprintf("Unique TYPGRPCDs : %d\n", length(unique(cond$TYPGRPCD))))
cat(sprintf("Unique cells: %d\n", nrow(cells)))
cat("\nCell size distribution:\n")
print(summary(cells$n_cond))
cat(sprintf("\nCells >= 30 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 30),
            100*mean(cells$n_cond >= 30)))
cat(sprintf("Cells >= 100 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 100),
            100*mean(cells$n_cond >= 100)))
cat(sprintf("Cells >= 500 conds: %d (%.1f%%)\n", sum(cells$n_cond >= 500),
            100*mean(cells$n_cond >= 500)))
cat("\nSubject cells with insufficient cross-state donors (< 30):\n")
cat(sprintf("Subject conds in low-donor cells: %d of %d (%.2f%%)\n",
            sum(low_donor$n_self_state),
            sum(match_avail$n_self_state),
            100 * sum(low_donor$n_self_state) / sum(match_avail$n_self_state)))
sink()

cat("\nOutputs at:", OUT_DIR, "\n")
