#!/usr/bin/env Rscript
# wa_donor_pool_diagnostic.R
# Tabulate WA subject plot forest type distribution vs the WA donor pool
# (OR, ID, MT) forest type distribution. If donor pool underrepresents WA
# west side Douglas fir / western hemlock types, that's the dominant
# mechanism for the WA -25 percent hindcast bias documented in
# BIAS_DOCUMENTATION_20260515.md.
#
# Run on Cardinal. Inputs from ~/fia_data/<STATE>_COND.csv and the FIA
# REF_FOREST_TYPE.csv at ~/fia_cem_projections/config/REF_FOREST_TYPE.csv.
#
# Outputs:
#   wa_donor_pool_forest_type_comparison.csv (per FORTYPCD subject vs donor counts/pct)
#   wa_donor_pool_typgrp_comparison.csv      (collapsed to TYPGRPCD)
#   wa_donor_pool_diagnostic.png             (side-by-side bar comparison)
#   wa_donor_pool_diagnostic_summary.txt     (top types + gap signature)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

FIA_DIR <- "/users/PUOM0008/crsfaaron/fia_data"
CFG_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/wa_donor_diagnostic_20260516"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Subject and donor sets per HANDOFF_20260516_evening.md
SUBJECT_STATES <- c("WA")
DONOR_STATES   <- c("OR", "ID", "MT")

# Baseline window: anchor 1999 with +/- 5 year window per pipeline canon.
# Restrict to forested live conditions (COND_STATUS_CD == 1) and the
# canonical DESIGNCD == 1 annualized subset to match the pipeline filter.
BASELINE_YEARS <- 1999:2008

read_cond <- function(state) {
  fp <- file.path(FIA_DIR, paste0(state, "_COND.csv"))
  if (!file.exists(fp)) {
    warning("Missing COND file for ", state, ": ", fp)
    return(NULL)
  }
  # Schema-tolerant read: some COND extracts (ID, MT) lack CONDPROP_UNADJ
  # and STDORGCD. Take what's there, fill missing.
  hdr <- names(data.table::fread(fp, nrows = 0, showProgress = FALSE))
  wanted <- c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
              "CONDPROP_UNADJ", "STDORGCD")
  cols <- intersect(wanted, hdr)
  dt <- data.table::fread(fp, select = cols, showProgress = FALSE)
  if (!"CONDPROP_UNADJ" %in% names(dt)) dt[, CONDPROP_UNADJ := 1.0]
  if (!"STDORGCD"       %in% names(dt)) dt[, STDORGCD       := NA_integer_]
  dt[, source_state := state]
  dt[]
}

cat("Reading COND files...\n")
sub_dt <- data.table::rbindlist(lapply(SUBJECT_STATES, read_cond))
don_dt <- data.table::rbindlist(lapply(DONOR_STATES,  read_cond))

cat(sprintf("  WA subject rows raw: %d\n",  nrow(sub_dt)))
cat(sprintf("  Donor (OR+ID+MT) rows raw: %d\n", nrow(don_dt)))

# Filter: forested live conditions in the baseline window with valid FORTYPCD
keep_filter <- function(dt) {
  dt[COND_STATUS_CD == 1 &
       INVYR %in% BASELINE_YEARS &
       !is.na(FORTYPCD) &
       FORTYPCD > 0]
}
sub_dt <- keep_filter(sub_dt)
don_dt <- keep_filter(don_dt)
cat(sprintf("  WA subject (forested, %d-%d): %d rows\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS), nrow(sub_dt)))
cat(sprintf("  Donor (forested, %d-%d): %d rows\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS), nrow(don_dt)))

# Load FIA forest type reference table
ref <- data.table::fread(file.path(CFG_DIR, "REF_FOREST_TYPE.csv"),
                          showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
ref <- ref[, .(FORTYPCD, MEANING, TYPGRPCD)]

# Tabulate area-weighted counts by FORTYPCD
agg_fortyp <- function(dt, label) {
  dt[, .(n_cond  = .N,
         area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)),
     by = FORTYPCD][
       , pct_area := area_ha / sum(area_ha)][
       , source := label][]
}
sub_agg <- agg_fortyp(sub_dt, "WA_subject")
don_agg <- agg_fortyp(don_dt, "OR_ID_MT_donor")

# Merge with reference table for human readable types
sub_agg <- merge(sub_agg, ref, by = "FORTYPCD", all.x = TRUE)
don_agg <- merge(don_agg, ref, by = "FORTYPCD", all.x = TRUE)

# Per-FORTYPCD comparison (sorted by subject area share)
fortyp_wide <- merge(
  sub_agg[, .(FORTYPCD, MEANING, TYPGRPCD,
              wa_n = n_cond, wa_area_ha = area_ha, wa_pct = pct_area)],
  don_agg[, .(FORTYPCD,
              donor_n = n_cond, donor_area_ha = area_ha, donor_pct = pct_area)],
  by = "FORTYPCD", all = TRUE
)
fortyp_wide[is.na(wa_pct),    wa_pct    := 0]
fortyp_wide[is.na(donor_pct), donor_pct := 0]
fortyp_wide[, gap_pct := wa_pct - donor_pct]
data.table::setorder(fortyp_wide, -wa_pct)

# Per TYPGRPCD collapsed comparison
typgrp_wide <- fortyp_wide[, .(
  n_types       = .N,
  wa_area_ha    = sum(wa_area_ha, na.rm = TRUE),
  donor_area_ha = sum(donor_area_ha, na.rm = TRUE),
  wa_pct        = sum(wa_pct, na.rm = TRUE),
  donor_pct     = sum(donor_pct, na.rm = TRUE)
), by = TYPGRPCD]
typgrp_wide[, gap_pct := wa_pct - donor_pct]
data.table::setorder(typgrp_wide, -wa_pct)
# Add TYPGRPCD meaning by joining to ref on TYPGRPCD (use group label)
typgrp_meaning <- unique(ref[, .(TYPGRPCD, GROUP_NAME = MEANING)])
typgrp_meaning <- typgrp_meaning[FORTYPCD <- TYPGRPCD][, .SD[1], by = TYPGRPCD]
# Use a simple lookup from the first FORTYPCD that equals TYPGRPCD if present
typgrp_lookup <- ref[FORTYPCD %in% ref$TYPGRPCD, .(TYPGRPCD = FORTYPCD,
                                                    GROUP_NAME = MEANING)]
typgrp_wide <- merge(typgrp_wide, typgrp_lookup, by = "TYPGRPCD", all.x = TRUE)

# Write outputs
fwrite(fortyp_wide, file.path(OUT_DIR, "wa_donor_pool_forest_type_comparison.csv"))
fwrite(typgrp_wide, file.path(OUT_DIR, "wa_donor_pool_typgrp_comparison.csv"))

# Plot: top 12 forest type groups by subject share, side-by-side bars
plot_dt <- typgrp_wide[!is.na(GROUP_NAME)][order(-wa_pct)][1:12]
plot_long <- data.table::rbindlist(list(
  plot_dt[, .(GROUP_NAME, source = "WA subject",       pct = wa_pct)],
  plot_dt[, .(GROUP_NAME, source = "OR+ID+MT donor",   pct = donor_pct)]
))
plot_long[, GROUP_NAME := factor(GROUP_NAME, levels = plot_dt$GROUP_NAME)]

p <- ggplot(plot_long, aes(x = GROUP_NAME, y = pct, fill = source)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_manual(values = c("WA subject" = "#3a78a3",
                                "OR+ID+MT donor" = "#c0504d")) +
  coord_flip() +
  labs(
    title    = "WA subject vs OR+ID+MT donor forest type group share",
    subtitle = "Forest type groups by area share, baseline 1999-2008 forested conditions",
    x = NULL, y = "Share of forested area (%)",
    fill = "Source"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "wa_donor_pool_diagnostic.png"),
       plot = p, width = 9, height = 6, dpi = 150, bg = "white")

# Summary text
sink(file.path(OUT_DIR, "wa_donor_pool_diagnostic_summary.txt"))
cat("WA DONOR POOL DIAGNOSTIC\n")
cat("========================\n")
cat(sprintf("Baseline window: %d-%d (annualized inventory baseline window)\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS)))
cat(sprintf("WA subject conditions: %d (forested live, valid FORTYPCD)\n",
            nrow(sub_dt)))
cat(sprintf("Donor (OR+ID+MT) conditions: %d (forested live, valid FORTYPCD)\n",
            nrow(don_dt)))
cat("\nTop 12 forest type groups by WA subject area share:\n")
print(plot_dt[, .(GROUP_NAME, wa_pct = round(wa_pct, 3),
                  donor_pct = round(donor_pct, 3),
                  gap_pct = round(gap_pct, 3))])
cat("\nLargest underrepresented groups in donor pool (WA share - donor share):\n")
top_gap <- typgrp_wide[!is.na(GROUP_NAME)][order(-gap_pct)][1:5]
print(top_gap[, .(GROUP_NAME, wa_pct = round(wa_pct, 3),
                  donor_pct = round(donor_pct, 3),
                  gap_pct = round(gap_pct, 3))])
cat("\nLargest overrepresented groups in donor pool (donor share - WA share):\n")
typgrp_wide[, gap_neg := -gap_pct]
top_donor_skew <- typgrp_wide[!is.na(GROUP_NAME)][order(-gap_neg)][1:5]
print(top_donor_skew[, .(GROUP_NAME, wa_pct = round(wa_pct, 3),
                          donor_pct = round(donor_pct, 3),
                          gap_pct = round(gap_pct, 3))])
sink()

cat("Outputs written to:", OUT_DIR, "\n")
