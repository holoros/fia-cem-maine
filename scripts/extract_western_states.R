#!/usr/bin/env Rscript
# extract_western_states.R
# Extract western states from the CONUS ENTIRE_*.csv files into per-state
# COND/PLOT/TREE CSVs matching the ~/fia_data naming convention, so the
# --conus_donors flag picks them up via get_all_available_states().
#
# Focus: CA (STATECD 6) is the critical ecological donor for WA west-side
# Doug-fir/hemlock. Also extract other western states for completeness so
# all subject states' ecoregion matching has a fuller CONUS donor universe.

suppressPackageStartupMessages(library(data.table))

FIA_DIR  <- "/users/PUOM0008/crsfaaron/FIA"
OUT_DIR  <- "/users/PUOM0008/crsfaaron/fia_data"

# Western states to extract (STATECD -> postal). Skip those already present
# in fia_data (ID=16, MT=30, OR=41, WA=53 already there).
WANT <- list(
  "6"  = "CA",   # California (key for WA west-side coastal)
  "4"  = "AZ",
  "8"  = "CO",
  "32" = "NV",
  "35" = "NM",
  "49" = "UT",
  "56" = "WY"
)

extract_table <- function(entire_name, suffix, statecd_col = "STATECD") {
  fp <- file.path(FIA_DIR, entire_name)
  if (!file.exists(fp)) {
    cat(sprintf("  MISSING %s\n", fp))
    return(invisible())
  }
  cat(sprintf("Reading %s ...\n", entire_name))
  ts <- Sys.time()
  # Read only what's needed; STATECD must be present for the filter
  dt <- data.table::fread(fp, showProgress = FALSE)
  cat(sprintf("  read %d rows in %.0fs\n", nrow(dt),
              as.numeric(difftime(Sys.time(), ts, units = "secs"))))
  if (!statecd_col %in% names(dt)) {
    cat(sprintf("  no %s column in %s; skipping\n", statecd_col, entire_name))
    return(invisible())
  }
  for (sc in names(WANT)) {
    postal <- WANT[[sc]]
    sub <- dt[get(statecd_col) == as.integer(sc)]
    if (nrow(sub) == 0) { cat(sprintf("  %s %s: 0 rows\n", postal, suffix)); next }
    outfp <- file.path(OUT_DIR, paste0(postal, "_", suffix, ".csv"))
    data.table::fwrite(sub, outfp)
    cat(sprintf("  wrote %s (%d rows)\n", basename(outfp), nrow(sub)))
  }
  rm(dt); gc()
}

cat("=== Extracting COND ===\n")
extract_table("ENTIRE_COND.csv", "COND")
cat("=== Extracting PLOT ===\n")
extract_table("ENTIRE_PLOT.csv", "PLOT")
cat("=== Extracting TREE ===\n")
extract_table("ENTIRE_TREE.csv", "TREE")

cat("\nDone. New per-state files in", OUT_DIR, "\n")
cat("Available states now:\n")
cond_files <- list.files(OUT_DIR, pattern = "_COND.csv$")
print(sort(unique(sub("_COND.csv$", "", cond_files))))
