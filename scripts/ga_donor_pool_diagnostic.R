#!/usr/bin/env Rscript
# ga_donor_pool_diagnostic.R
# Tabulate GA subject STDORGCD distribution vs the GA donor pool
# (FL, SC, NC, TN, AL) STDORGCD distribution. If donor pool overrepresents
# planted stands (STDORGCD == 1) relative to GA subject mix, that confirms
# the mechanism behind the GA +10 percent over-prediction bias.
#
# Run on Cardinal. Inputs from ~/fia_data/<STATE>_COND.csv.
#
# Outputs:
#   ga_donor_pool_stdorgcd_comparison.csv (STDORGCD share comparison)
#   ga_donor_pool_diagnostic.png
#   ga_donor_pool_diagnostic_summary.txt

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

FIA_DIR <- "/users/PUOM0008/crsfaaron/fia_data"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/ga_donor_diagnostic_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

SUBJECT_STATES <- c("GA")
DONOR_STATES   <- c("FL", "SC", "NC", "TN", "AL")
BASELINE_YEARS <- 1999:2008

read_cond <- function(state) {
  fp <- file.path(FIA_DIR, paste0(state, "_COND.csv"))
  if (!file.exists(fp)) {
    warning("Missing COND for ", state)
    return(NULL)
  }
  hdr <- names(data.table::fread(fp, nrows = 0, showProgress = FALSE))
  wanted <- c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
              "STDORGCD", "CONDPROP_UNADJ")
  cols <- intersect(wanted, hdr)
  dt <- data.table::fread(fp, select = cols, showProgress = FALSE)
  if (!"CONDPROP_UNADJ" %in% names(dt)) dt[, CONDPROP_UNADJ := 1.0]
  if (!"STDORGCD"       %in% names(dt)) dt[, STDORGCD       := NA_integer_]
  dt[, source_state := state]
  dt[]
}

cat("Reading COND files...\n")
sub_dt <- data.table::rbindlist(lapply(SUBJECT_STATES, read_cond), fill = TRUE)
don_dt <- data.table::rbindlist(lapply(DONOR_STATES,   read_cond), fill = TRUE)

keep <- function(dt) {
  dt[COND_STATUS_CD == 1 &
       INVYR %in% BASELINE_YEARS &
       !is.na(FORTYPCD) & FORTYPCD > 0]
}
sub_dt <- keep(sub_dt)
don_dt <- keep(don_dt)

cat(sprintf("GA subject (forested, %d-%d): %d conds\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS), nrow(sub_dt)))
cat(sprintf("Donor (FL+SC+NC+TN+AL) (forested, %d-%d): %d conds\n",
            min(BASELINE_YEARS), max(BASELINE_YEARS), nrow(don_dt)))

# STDORGCD: 0 = natural origin, 1 = clear evidence of artificial regen (plantation)
classify <- function(dt, label) {
  dt[, stdorg_class := dplyr::case_when(
    is.na(STDORGCD)    ~ "unknown",
    STDORGCD == 0L     ~ "natural",
    STDORGCD == 1L     ~ "planted",
    TRUE               ~ "other"
  )]
  agg <- dt[, .(
    n_cond  = .N,
    area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)
  ), by = .(stdorg_class)][
    , pct_area := area_ha / sum(area_ha)][
    , source := label]
  agg
}
sub_agg <- classify(sub_dt, "GA_subject")
don_agg <- classify(don_dt, "FL_SC_NC_TN_AL_donor")

comparison <- merge(
  sub_agg[, .(stdorg_class, ga_n = n_cond, ga_pct = pct_area)],
  don_agg[, .(stdorg_class, donor_n = n_cond, donor_pct = pct_area)],
  by = "stdorg_class", all = TRUE
)
comparison[is.na(ga_pct),    ga_pct    := 0]
comparison[is.na(donor_pct), donor_pct := 0]
comparison[, gap_pct := ga_pct - donor_pct]

fwrite(comparison, file.path(OUT_DIR, "ga_donor_pool_stdorgcd_comparison.csv"))

# Per state breakdown for donors
per_state_donor <- don_dt[, .(
  n_cond = .N,
  pct_planted = round(sum(STDORGCD == 1L, na.rm = TRUE) / .N, 3),
  pct_natural = round(sum(STDORGCD == 0L, na.rm = TRUE) / .N, 3),
  pct_unknown = round(sum(is.na(STDORGCD)) / .N, 3)
), by = .(source_state)]
fwrite(per_state_donor, file.path(OUT_DIR, "ga_donor_per_state_stdorgcd.csv"))

# Plot side-by-side
plot_long <- data.table::rbindlist(list(
  comparison[, .(stdorg_class, source = "GA subject", pct = ga_pct)],
  comparison[, .(stdorg_class, source = "FL+SC+NC+TN+AL donor", pct = donor_pct)]
))

p <- ggplot(plot_long, aes(x = stdorg_class, y = pct, fill = source)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_manual(values = c("GA subject" = "#3a78a3",
                                "FL+SC+NC+TN+AL donor" = "#c0504d")) +
  labs(
    title    = "GA subject vs FL+SC+NC+TN+AL donor stand origin share",
    subtitle = "STDORGCD: 0 = natural, 1 = planted. Baseline 1999-2008 forested conditions.",
    x = NULL, y = "Share of forested area (%)",
    fill = "Source"
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(OUT_DIR, "ga_donor_pool_diagnostic.png"),
       plot = p, width = 7, height = 5, dpi = 150, bg = "white")

sink(file.path(OUT_DIR, "ga_donor_pool_diagnostic_summary.txt"))
cat("GA DONOR POOL STDORGCD DIAGNOSTIC\n")
cat("=================================\n")
cat(sprintf("Baseline: %d-%d\n", min(BASELINE_YEARS), max(BASELINE_YEARS)))
cat(sprintf("GA subject conditions: %d\n", nrow(sub_dt)))
cat(sprintf("Donor (FL+SC+NC+TN+AL): %d\n", nrow(don_dt)))
cat("\nSTDORGCD comparison:\n")
print(comparison)
cat("\nPer-state donor STDORGCD breakdown:\n")
print(per_state_donor)
cat("\nGAP interpretation: positive ga_pct gap means GA has more of that class than donor pool.\n")
cat("Negative gap (donor > GA) for STDORGCD == 1 (planted) supports the +10% over bias mechanism.\n")
sink()

cat("Outputs at:", OUT_DIR, "\n")

# ---- FORTYPCD-based plantation proxy (since donor STDORGCD is missing) ----
cat("\nRunning FORTYPCD-based plantation proxy diagnostic...\n")

# FIA loblolly/slash/longleaf pine types: 161 loblolly, 162 shortleaf,
# 163 Virginia, 164 sand, 165 longleaf, 166 longleaf/slash, 167 slash,
# 168 spruce, 169 sand pine, 170 white pine, 171 eastern white, 173 pitch.
# In the SE, types 161 (loblolly), 167 (slash), 141 longleaf/slash, 165
# longleaf are most often intensively managed plantations.
PLANTATION_INDICATIVE_TYPES <- c(
  141, # longleaf / slash pine
  142, # slash pine
  161, # loblolly pine
  167, # loblolly / shortleaf pine
  165, # longleaf pine
  166, # longleaf / loblolly
  168  # short leaf / scrub oak
)

classify_planttype <- function(dt, label) {
  dt[, plant_class := ifelse(FORTYPCD %in% PLANTATION_INDICATIVE_TYPES,
                              "pine_plantation_indicative",
                              "other_forest_type")]
  agg <- dt[, .(
    n_cond = .N,
    area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)
  ), by = .(plant_class)][
    , pct_area := area_ha / sum(area_ha)][
    , source := label]
  agg
}
sub_pt <- classify_planttype(sub_dt, "GA_subject")
don_pt <- classify_planttype(don_dt, "FL_SC_TN_AL_donor")

planttype_comp <- merge(
  sub_pt[, .(plant_class, ga_n = n_cond, ga_pct = pct_area)],
  don_pt[, .(plant_class, donor_n = n_cond, donor_pct = pct_area)],
  by = "plant_class", all = TRUE
)
planttype_comp[is.na(ga_pct), ga_pct := 0]
planttype_comp[is.na(donor_pct), donor_pct := 0]
planttype_comp[, gap_pct := ga_pct - donor_pct]
fwrite(planttype_comp, file.path(OUT_DIR, "ga_donor_pool_plantation_proxy.csv"))

cat("\nPlantation-indicative forest type share (FORTYPCD 141,142,161,165-168):\n")
print(planttype_comp)

