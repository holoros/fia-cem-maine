# =============================================================================
# Title: Re-pull FIA GRM tables WITH macroplot columns
# Author: A. Weiskittel
# Date: 2026-05-22
# Description:
#   The GRM exports currently on Cardinal (per-state CSVs and the fia_db_*.rds
#   rFIA databases) were produced WITHOUT the macroplot family of columns: the
#   TREE_GRM_COMPONENT tables are 78 columns with no MACR_* fields and an empty
#   SUBPTYP_BEGIN/MIDPT/END. As a result the macroplot tree pool (large trees in
#   the West and PNW) is dropped from gross growth, removals, and mortality.
#   This is the data-side root cause of the bias John Shaw raised on 2026-05-22.
#
#   This script re-pulls the GRM tables straight from the FIA DataMart so the
#   full schema (including MACR_TPAGROW/REMV/MORT_UNADJ_AL_FOREST,
#   MACR_COMPONENT_AL_FOREST, and populated SUBPTYP_* design codes) is retained,
#   then asserts that the macroplot columns are present before you trust it.
#
#   After this completes, run GRM_2026_macroplot_aware.R against the new files;
#   its subplot+macroplot expansion will then actually correct the bias instead
#   of being a no-op.
#
# Run on Cardinal:
#   module load gcc/12.3.0 R/4.4.0
#   Rscript fia_grm_extract_macroplot.R
# =============================================================================

# Macroplot states matter most; extend as the national analysis requires.
states <- c("OR", "WA", "CA")
out    <- path.expand("~/fia_data/grm_full")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

if (!requireNamespace("rFIA", quietly = TRUE)) {
  install.packages("rFIA", repos = "https://cloud.r-project.org")
}
library(rFIA)

# getFIA downloads the full DataMart CSVs (all columns) for the requested tables.
tables <- c("PLOT", "COND", "TREE",
            "TREE_GRM_COMPONENT", "TREE_GRM_BEGIN", "TREE_GRM_MIDPT")
message("Downloading GRM tables for: ", paste(states, collapse = ", "))
getFIA(states = states, tables = tables, dir = out, load = FALSE)

# --- Verify the macroplot columns survived the pull --------------------------
library(data.table)
for (s in states) {
  f <- file.path(out, paste0(s, "_TREE_GRM_COMPONENT.csv"))
  if (!file.exists(f)) { message(s, ": component file missing"); next }
  hdr  <- names(fread(f, nrows = 0))
  macr <- grep("^MACR_", hdr, value = TRUE)
  cat(sprintf("%s_TREE_GRM_COMPONENT: %d cols, %d MACR cols\n",
              s, length(hdr), length(macr)))
  if (length(macr) == 0L)
    warning(s, ": still no MACR columns; the DataMart pull may be subset or stale.")
}
cat("\nIf MACR column counts are > 0 the re-pull worked. Point GRM_2026_macroplot_aware.R\n",
    "data_dir at ", out, " and the macroplot correction will take effect.\n", sep = "")
