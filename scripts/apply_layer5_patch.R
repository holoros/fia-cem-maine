#!/usr/bin/env Rscript
# =============================================================================
# scripts/apply_layer5_patch.R
#
# Conditional Layer 5 patch applicator for R/03_harvest_choice.R.
# Replaces the line `dVAL = REV_harvest,` (the Wear 2025 revenue proxy
# shortcut at line ~257) with the proper Wear 2025 differential:
#
#   dVAL = abs(REV_harvest + delta * (EV_h - EV_nh))
#
# Where EV_nh is computed inline from T2_vol_* columns using the same MBF
# and cord conversions as the Layer 4 patch.
#
# Usage:
#   Rscript scripts/apply_layer5_patch.R [--dry-run] [path/to/03_harvest_choice.R]
#
# If --dry-run is given, prints the proposed diff without writing.
# Default file: ~/fia_cem_projections/R/03_harvest_choice.R
#
# Author: Aaron Weiskittel (built 16 May 2026, conditional on Layer 4 result)
# =============================================================================

suppressPackageStartupMessages({
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
dry_run <- "--dry-run" %in% args
args <- args[args != "--dry-run"]
target <- if (length(args) > 0) args[1] else "~/fia_cem_projections/R/03_harvest_choice.R"
target <- path.expand(target)

if (!file.exists(target)) stop("Target file not found: ", target)

lines <- readLines(target)

# Find the dVAL = REV_harvest line. It should be preceded by "# Compute dVAL".
dval_line_idx <- which(grepl("^\\s*dVAL\\s*=\\s*REV_harvest\\s*,?\\s*$", lines))

if (length(dval_line_idx) == 0) {
  message("No `dVAL = REV_harvest` line found. Either Layer 5 already applied or pattern changed.")
  message("Searched in: ", target)
  quit(status = 1, save = "no")
}

if (length(dval_line_idx) > 1) {
  warning(sprintf("Found %d matches; using first at line %d.",
                  length(dval_line_idx), dval_line_idx[1]))
}
idx <- dval_line_idx[1]

# Preserve indentation
indent <- str_extract(lines[idx], "^\\s*")

# New replacement block. Note: assumes T2_vol_* columns and prices are in scope
# at this mutate site (they are: predict_harvest_probability receives cond_data
# which has T2_vol_* via the compute_harvest_revenue join earlier).
new_block <- c(
  paste0(indent, "# Layer 5 fix (built 16 May 2026): replace the Wear 2025 revenue proxy with"),
  paste0(indent, "# the proper differential. EV_h is residual stand value after harvest (regen,"),
  paste0(indent, "# nominally $50/ac). EV_nh is the discounted standing timber value at T2,"),
  paste0(indent, "# computed inline using the same MBF and cord conversions as Layer 4."),
  paste0(indent, "EV_h_value = 50,    # $/ac residual after harvest"),
  paste0(indent, "EV_nh_value = (coalesce(T2_vol_sawtimber_softwood, 0) * (1/200) *"),
  paste0(indent, "                 prices$sawtimber$softwood +"),
  paste0(indent, "               coalesce(T2_vol_sawtimber_hardwood, 0) * (1/200) *"),
  paste0(indent, "                 prices$sawtimber$hardwood +"),
  paste0(indent, "               coalesce(T2_vol_pulpwood_softwood,  0) * (1/80)  *"),
  paste0(indent, "                 prices$pulpwood$softwood +"),
  paste0(indent, "               coalesce(T2_vol_pulpwood_hardwood,  0) * (1/80)  *"),
  paste0(indent, "                 prices$pulpwood$hardwood),"),
  paste0(indent, "delta_5yr = (1 + 0.04)^(-5),   # 4 percent annual discount, 5 yr remper"),
  paste0(indent, "dVAL = abs(REV_harvest + delta_5yr * (EV_h_value - EV_nh_value)),")
)

if (dry_run) {
  cat("DRY RUN -- no changes written\n")
  cat(sprintf("Target file: %s\n", target))
  cat(sprintf("Original line %d: %s\n", idx, lines[idx]))
  cat("\nProposed replacement (15 lines):\n")
  cat(paste(new_block, collapse = "\n"), "\n", sep = "")
  quit(status = 0, save = "no")
}

# Write backup
backup <- sprintf("%s.preupdate.%s_layer5", target, format(Sys.Date(), "%Y%m%d"))
file.copy(target, backup, overwrite = TRUE)
cat(sprintf("Backup written: %s\n", backup))

# Apply replacement
new_lines <- c(lines[seq_len(idx - 1)], new_block, lines[(idx + 1):length(lines)])
writeLines(new_lines, target)
cat(sprintf("Layer 5 patch applied to %s\n", target))
cat(sprintf("Original line %d replaced with %d lines\n", idx, length(new_block)))
cat("\nNext step: redeploy to Cardinal if applying locally, or run on Cardinal directly:\n")
cat("  ssh cardinal\n")
cat("  cd ~/fia_cem_projections\n")
cat("  Rscript scripts/apply_layer5_patch.R\n")
cat("Then submit a Layer 5 verification smoke:\n")
cat("  sbatch osc/submit_layer4_smoke.sh   # (reuse the same script; tag the output dir differently if needed)\n")
