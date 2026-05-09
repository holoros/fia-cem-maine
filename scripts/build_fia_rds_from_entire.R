## build_fia_rds_from_entire.R
## Build per-state fia_db_<STATE>.rds from local ~/FIA/ENTIRE_*.csv tables,
## without calling rFIA::getFIA() (which needs internet, blocking compute-node
## runs). The pipeline already auto-upgrades from --fia_access rfia to "rds"
## when the RDS file is present (run_projection.R line ~297), so this script
## fixes the failure mode of submit_mn_smoke.sh that we hit in job 9292743.
##
## Inputs:
##   ~/FIA/ENTIRE_PLOT.csv
##   ~/FIA/ENTIRE_COND.csv
##   ~/FIA/ENTIRE_TREE.csv
##   ~/FIA/ENTIRE_TREE_GRM_COMPONENT.csv
##   ~/FIA/ENTIRE_TREE_GRM_MIDPT.csv
##   ~/FIA/ENTIRE_SUBP_COND_CHNG_MTRX.csv
##
## Output:
##   ~/fia_data/fia_db_<STATE>.rds   list of data.frames, one per FIA table
##                                    filtered to the target state's donor pool
##
## Donor mapping mirrors osc/00_download_data.R / run_projection.R:
##   ME -> {ME, NH, VT, NY, MA, CT, RI}
##   MN -> {MN, WI, MI, IA}
##   WA -> {WA, OR, ID, MT}
##   GA -> {GA, FL, SC, NC, TN, AL}
##
## Usage on Cardinal login node:
##   module load gcc/12.3.0 R/4.4.0
##   Rscript scripts/build_fia_rds_from_entire.R MN
##   Rscript scripts/build_fia_rds_from_entire.R WA
##   Rscript scripts/build_fia_rds_from_entire.R GA

suppressPackageStartupMessages({
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
state <- if (length(args) > 0) toupper(args[1]) else "MN"

FIA_DIR  <- file.path(Sys.getenv("HOME"), "FIA")
DATA_DIR <- file.path(Sys.getenv("HOME"), "fia_data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

donor_map <- list(
  ME = c("ME", "NH", "VT", "NY", "MA", "CT", "RI"),
  MN = c("MN", "WI", "MI", "IA"),
  WA = c("WA", "OR", "ID", "MT"),
  GA = c("GA", "FL", "SC", "NC", "TN", "AL")
)
state_fips <- c(
  ME = 23L, NH = 33L, VT = 50L, NY = 36L, MA = 25L, CT = 9L, RI = 44L,
  MN = 27L, WI = 55L, MI = 26L, IA = 19L,
  WA = 53L, OR = 41L, ID = 16L, MT = 30L,
  GA = 13L, FL = 12L, SC = 45L, NC = 37L, TN = 47L, AL =  1L
)

if (!state %in% names(donor_map)) {
  stop(sprintf("State '%s' not in donor_map; supported: %s",
               state, paste(names(donor_map), collapse = ", ")))
}
states <- donor_map[[state]]
fips   <- state_fips[states]

cat("============================================\n")
cat(sprintf("  Building fia_db_%s.rds from ENTIRE_*.csv\n", state))
cat(sprintf("  Target state : %s (STATECD %d)\n", state, state_fips[state]))
cat(sprintf("  Donor pool   : %s\n", paste(states, collapse = ", ")))
cat(sprintf("  Donor STATECDs: %s\n", paste(fips, collapse = ", ")))
cat(sprintf("  FIA dir      : %s\n", FIA_DIR))
cat(sprintf("  Output dir   : %s\n", DATA_DIR))
cat("============================================\n\n")

read_filtered <- function(name) {
  f <- file.path(FIA_DIR, paste0("ENTIRE_", name, ".csv"))
  if (!file.exists(f)) {
    cat(sprintf("  %-25s SKIP (file not present)\n", name))
    return(NULL)
  }
  cat(sprintf("  %-25s reading...\n", name))
  ## Reading just STATECD first to identify rows to keep would require two
  ## passes. data.table::fread is fast enough that we just read all rows and
  ## filter. (~700 MB ENTIRE_PLOT reads in roughly 30s.)
  dt <- data.table::fread(f, data.table = TRUE, showProgress = FALSE)
  if ("STATECD" %in% names(dt)) {
    keep <- dt[STATECD %in% fips, ]
    cat(sprintf("    %-25s %d rows -> %d after STATECD filter\n",
                name, nrow(dt), nrow(keep)))
    keep
  } else {
    cat(sprintf("    %-25s %d rows (no STATECD column; kept all)\n",
                name, nrow(dt)))
    dt
  }
}

## Tables required by the pipeline (matches what 00_download_data.R requests).
tbl_names <- c("PLOT", "COND", "TREE",
               "TREE_GRM_COMPONENT", "TREE_GRM_MIDPT",
               "SUBP_COND_CHNG_MTRX")

cat("Reading and filtering ENTIRE_*.csv tables...\n")
db <- lapply(tbl_names, read_filtered)
names(db) <- tbl_names
db <- db[!vapply(db, is.null, logical(1))]

cat(sprintf("\nLoaded %d tables: %s\n",
            length(db), paste(names(db), collapse = ", ")))

out_rds <- file.path(DATA_DIR, sprintf("fia_db_%s.rds", state))
saveRDS(db, out_rds)
sz_mb <- file.size(out_rds) / 1e6
cat(sprintf("\nWrote %s (%.1f MB)\n", out_rds, sz_mb))

## Quick sanity print: row counts per table.
cat("\nRow counts:\n")
for (n in names(db)) {
  cat(sprintf("  %-25s %d\n", n, nrow(db[[n]])))
}

## Plot count by STATECD.
if ("PLOT" %in% names(db)) {
  cat("\nPLOT rows by STATECD:\n")
  print(table(db[["PLOT"]]$STATECD))
}

cat("\nDone.\n")
