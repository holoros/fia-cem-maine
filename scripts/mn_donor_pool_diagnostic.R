#!/usr/bin/env Rscript
# mn_donor_pool_diagnostic.R
# Tabulate MN subject plot forest type distribution vs the MN donor pool
# (Lake States cohort: WI, MI, IA, IL, ND, SD) using the full CONUS
# ENTIRE_COND.csv now available at ~/FIA/.
#
# Tests the dominant candidate mechanism for the MN -23 percent statewide
# volume undercount documented in MN_VOLUME_GAP_REVISED_20260516.md after
# the DESIGNCD hypothesis was refuted.
#
# Run on Cardinal. Input: ~/FIA/ENTIRE_COND.csv (740MB, all CONUS).
# Outputs:
#   mn_donor_pool_forest_type_comparison.csv (per FORTYPCD)
#   mn_donor_pool_typgrp_comparison.csv      (per TYPGRPCD)
#   mn_donor_pool_diagnostic.png             (side-by-side bar)
#   mn_donor_pool_diagnostic_summary.txt

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

ENTIRE_COND <- "/users/PUOM0008/crsfaaron/FIA/ENTIRE_COND.csv"
REF_FORTYP  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/REF_FOREST_TYPE.csv"
OUT_DIR     <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/mn_donor_diagnostic_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Subject and donor per HANDOFF state_constants.csv
SUBJECT_STATECDS <- c(27L)                              # MN
# Lake States donor cohort: WI=55, MI=26, IA=19, IL=17, ND=38, SD=46
DONOR_STATECDS   <- c(55L, 26L, 19L, 17L, 38L, 46L)
BASELINE_YEARS   <- 1999:2008

cat("Reading ENTIRE_COND.csv (740MB)...\n")
ts <- Sys.time()
cond_all <- data.table::fread(
  ENTIRE_COND,
  select = c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
             "CONDPROP_UNADJ", "STDORGCD", "PLT_CN"),
  showProgress = FALSE
)
cat(sprintf("Read %d rows in %.1fs\n", nrow(cond_all),
            as.numeric(difftime(Sys.time(), ts, units = "secs"))))

# Filter to MN subject + Lake States donor pool
sub_dt <- cond_all[STATECD %in% SUBJECT_STATECDS]
don_dt <- cond_all[STATECD %in% DONOR_STATECDS]
cat(sprintf("MN subject raw: %d  Donor (Lake States) raw: %d\n",
            nrow(sub_dt), nrow(don_dt)))

# Forested baseline window filter
keep_filter <- function(dt) {
  dt[COND_STATUS_CD == 1 &
       INVYR %in% BASELINE_YEARS &
       !is.na(FORTYPCD) & FORTYPCD > 0]
}
sub_dt <- keep_filter(sub_dt)
don_dt <- keep_filter(don_dt)
cat(sprintf("After filter: MN %d, donor %d\n", nrow(sub_dt), nrow(don_dt)))

# Per-donor-state breakdown for context
per_donor <- don_dt[, .(
  n_cond = .N,
  pct_total = round(.N / nrow(don_dt), 3)
), by = STATECD][order(-n_cond)]
cat("\nDonor state breakdown:\n")
print(per_donor)

# Read forest type reference
ref <- data.table::fread(REF_FORTYP, showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
ref <- ref[, .(FORTYPCD, MEANING, TYPGRPCD)]

# Aggregate by FORTYPCD with area weighting
agg_fortyp <- function(dt, label) {
  dt[, .(
    n_cond  = .N,
    area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)
  ), by = FORTYPCD][
    , pct_area := area_ha / sum(area_ha)][
    , source := label]
}
sub_agg <- merge(agg_fortyp(sub_dt, "MN_subject"), ref, by = "FORTYPCD", all.x = TRUE)
don_agg <- merge(agg_fortyp(don_dt, "Lake_States_donor"), ref, by = "FORTYPCD", all.x = TRUE)

# Per-FORTYPCD comparison
fortyp_wide <- merge(
  sub_agg[, .(FORTYPCD, MEANING, TYPGRPCD,
              mn_n = n_cond, mn_area_ha = area_ha, mn_pct = pct_area)],
  don_agg[, .(FORTYPCD,
              donor_n = n_cond, donor_area_ha = area_ha, donor_pct = pct_area)],
  by = "FORTYPCD", all = TRUE
)
fortyp_wide[is.na(mn_pct),    mn_pct    := 0]
fortyp_wide[is.na(donor_pct), donor_pct := 0]
fortyp_wide[, gap_pct := mn_pct - donor_pct]
data.table::setorder(fortyp_wide, -mn_pct)
fwrite(fortyp_wide, file.path(OUT_DIR, "mn_donor_pool_forest_type_comparison.csv"))

# Per-TYPGRPCD comparison
typgrp_wide <- fortyp_wide[, .(
  n_types       = .N,
  mn_area_ha    = sum(mn_area_ha, na.rm = TRUE),
  donor_area_ha = sum(donor_area_ha, na.rm = TRUE),
  mn_pct        = sum(mn_pct, na.rm = TRUE),
  donor_pct     = sum(donor_pct, na.rm = TRUE)
), by = TYPGRPCD]
typgrp_wide[, gap_pct := mn_pct - donor_pct]
data.table::setorder(typgrp_wide, -mn_pct)

typgrp_names <- ref[FORTYPCD %in% ref$TYPGRPCD,
                     .(TYPGRPCD = FORTYPCD, GROUP_NAME = MEANING)]
typgrp_names <- unique(typgrp_names, by = "TYPGRPCD")
typgrp_wide <- merge(typgrp_wide, typgrp_names, by = "TYPGRPCD", all.x = TRUE)
fwrite(typgrp_wide, file.path(OUT_DIR, "mn_donor_pool_typgrp_comparison.csv"))

# Plot top 12 type groups by MN share
plot_dt <- typgrp_wide[!is.na(GROUP_NAME)][order(-mn_pct)][1:12]
plot_long <- data.table::rbindlist(list(
  plot_dt[, .(GROUP_NAME, source = "MN subject",                 pct = mn_pct)],
  plot_dt[, .(GROUP_NAME, source = "Lake States donor cohort",   pct = donor_pct)]
))
plot_long[, GROUP_NAME := factor(GROUP_NAME, levels = plot_dt$GROUP_NAME)]

p <- ggplot(plot_long, aes(x = GROUP_NAME, y = pct, fill = source)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_manual(values = c("MN subject" = "#3a78a3",
                                "Lake States donor cohort" = "#c0504d")) +
  coord_flip() +
  labs(
    title    = "MN subject vs Lake States donor cohort forest type group share",
    subtitle = "Baseline 1999-2008 forested conditions. Donors: WI, MI, IA, IL, ND, SD.",
    x = NULL, y = "Share of forested area (%)", fill = "Source"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "mn_donor_pool_diagnostic.png"),
       plot = p, width = 9, height = 6, dpi = 150, bg = "white")

# Summary
sink(file.path(OUT_DIR, "mn_donor_pool_diagnostic_summary.txt"))
cat("MN DONOR POOL DIAGNOSTIC\n")
cat("========================\n")
cat(sprintf("Baseline: %d-%d  forested conditions\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS)))
cat(sprintf("MN subject conditions:  %d\n", nrow(sub_dt)))
cat(sprintf("Donor (Lake States) :   %d\n", nrow(don_dt)))
cat("\nPer-donor-state breakdown:\n")
print(per_donor)
cat("\nTop 12 forest type groups by MN subject share:\n")
print(plot_dt[, .(GROUP_NAME, mn_pct = round(mn_pct, 3),
                  donor_pct = round(donor_pct, 3),
                  gap_pct = round(gap_pct, 3))])
cat("\nLargest underrepresented groups in donor pool (positive gap):\n")
top_gap <- typgrp_wide[!is.na(GROUP_NAME)][order(-gap_pct)][1:5]
print(top_gap[, .(GROUP_NAME, mn_pct = round(mn_pct, 3),
                  donor_pct = round(donor_pct, 3),
                  gap_pct = round(gap_pct, 3))])
cat("\nLargest overrepresented groups in donor pool (negative gap):\n")
top_over <- typgrp_wide[!is.na(GROUP_NAME)][order(gap_pct)][1:5]
print(top_over[, .(GROUP_NAME, mn_pct = round(mn_pct, 3),
                    donor_pct = round(donor_pct, 3),
                    gap_pct = round(gap_pct, 3))])
sink()

cat("\nOutputs at:", OUT_DIR, "\n")
