#!/usr/bin/env Rscript
# wa_westside_donor_prototype.R
# Prototype WA west-of-Cascade donor pool restriction (Remediation Path 1
# from WA_DONOR_POOL_DIAGNOSTIC_20260517.md). Use OR_PLOT.LON to filter
# the OR donor pool to plots west of -122 degrees longitude (rough
# Cascades crest cutoff for OR). Optionally include WA west-side plots
# themselves as donors via leave-one-out.
#
# Compares three donor pool configurations against WA subject:
#   1. Current donor pool (OR + ID + MT, all areas)
#   2. WestSide OR only (OR plots with LON < -122)
#   3. WestSide OR + WA westside (broadest west-coast Doug-fir/hemlock pool)
#
# Outputs:
#   wa_westside_donor_comparison.csv     (per typgrp share by donor pool config)
#   wa_westside_donor_gap_table.csv      (gap by donor pool config)
#   wa_westside_donor_prototype.png      (cascading bars: 3 donor pools vs WA subject)

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

FIA_DIR <- "/users/PUOM0008/crsfaaron/fia_data"
CFG_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config"
OUT_DIR <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/wa_westside_donor_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

BASELINE_YEARS  <- 1999:2008
CASCADE_LON_CUT <- -122.0   # rough Cascades crest for OR and WA

read_cond <- function(state) {
  fp <- file.path(FIA_DIR, paste0(state, "_COND.csv"))
  if (!file.exists(fp)) return(NULL)
  hdr <- names(data.table::fread(fp, nrows = 0, showProgress = FALSE))
  cols <- intersect(c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
                       "PLT_CN", "CONDPROP_UNADJ", "STDORGCD"), hdr)
  dt <- data.table::fread(fp, select = cols, showProgress = FALSE)
  if (!"CONDPROP_UNADJ" %in% names(dt)) dt[, CONDPROP_UNADJ := 1.0]
  if (!"STDORGCD"       %in% names(dt)) dt[, STDORGCD       := NA_integer_]
  dt[, source_state := state]
  dt
}

read_plot <- function(state) {
  fp <- file.path(FIA_DIR, paste0(state, "_PLOT.csv"))
  if (!file.exists(fp)) return(NULL)
  hdr <- names(data.table::fread(fp, nrows = 0, showProgress = FALSE))
  cols <- intersect(c("CN", "STATECD", "LAT", "LON"), hdr)
  dt <- data.table::fread(fp, select = cols, showProgress = FALSE)
  data.table::setnames(dt, "CN", "PLT_CN")
  dt
}

cat("Reading COND + PLOT for WA, OR, ID, MT...\n")
cond_wa <- read_cond("WA"); plot_wa <- read_plot("WA")
cond_or <- read_cond("OR"); plot_or <- read_plot("OR")
cond_id <- read_cond("ID"); plot_id <- read_plot("ID")
cond_mt <- read_cond("MT"); plot_mt <- read_plot("MT")

# Join COND to PLOT for LON; missing PLOT or LON => NA
join_lon <- function(cond, plot_dt) {
  if (is.null(plot_dt)) return(cond[, LON := NA_real_])
  merge(cond, plot_dt[, .(PLT_CN, LON)], by = "PLT_CN", all.x = TRUE)
}
cond_wa <- join_lon(cond_wa, plot_wa)
cond_or <- join_lon(cond_or, plot_or)
cond_id <- join_lon(cond_id, plot_id)
cond_mt <- join_lon(cond_mt, plot_mt)

# Baseline + forested filter
filter_keep <- function(dt) {
  dt[COND_STATUS_CD == 1 & INVYR %in% BASELINE_YEARS &
       !is.na(FORTYPCD) & FORTYPCD > 0]
}
cond_wa <- filter_keep(cond_wa)
cond_or <- filter_keep(cond_or)
cond_id <- filter_keep(cond_id)
cond_mt <- filter_keep(cond_mt)

# Subject: all WA forested. Donor configurations.
sub_full <- cond_wa
donor_config_1 <- rbind(cond_or, cond_id, cond_mt)
donor_config_2 <- cond_or[!is.na(LON) & LON < CASCADE_LON_CUT]
donor_config_3 <- rbind(donor_config_2, cond_wa[!is.na(LON) & LON < CASCADE_LON_CUT])

# Load FIA forest type reference for TYPGRPCD
ref <- data.table::fread(file.path(CFG_DIR, "REF_FOREST_TYPE.csv"),
                          showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
ref <- ref[, .(FORTYPCD, TYPGRPCD)]

agg_typgrp <- function(dt, label) {
  if (nrow(dt) == 0) return(NULL)
  dt <- merge(dt, ref, by = "FORTYPCD", all.x = TRUE)
  agg <- dt[, .(n_cond = .N,
                 area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)),
             by = TYPGRPCD][
    , pct_area := area_ha / sum(area_ha)][
    , source := label]
  agg
}
sub_agg <- agg_typgrp(sub_full,        "WA_subject")
d1_agg  <- agg_typgrp(donor_config_1,  "donor_full_OR_ID_MT")
d2_agg  <- agg_typgrp(donor_config_2,  "donor_OR_westside_only")
d3_agg  <- agg_typgrp(donor_config_3,  "donor_OR_west_plus_WA_west")

cat("Donor pool sizes by config (forested baseline conds):\n")
cat(sprintf("  current OR+ID+MT:        %d\n", nrow(donor_config_1)))
cat(sprintf("  OR west of Cascades:     %d\n", nrow(donor_config_2)))
cat(sprintf("  OR west + WA west:       %d\n", nrow(donor_config_3)))

# Group-name lookup
typgrp_lookup <- ref[FORTYPCD %in% ref$TYPGRPCD,
                      .(TYPGRPCD = FORTYPCD)]
# Use canonical names from REF_FOREST_TYPE rows where FORTYPCD == TYPGRPCD
ref_full <- data.table::fread(file.path(CFG_DIR, "REF_FOREST_TYPE.csv"),
                                showProgress = FALSE)
data.table::setnames(ref_full, "VALUE", "FORTYPCD")
typgrp_names <- ref_full[FORTYPCD %in% ref_full$TYPGRPCD,
                          .(TYPGRPCD = FORTYPCD, GROUP_NAME = MEANING)]
typgrp_names <- unique(typgrp_names, by = "TYPGRPCD")

merge_named <- function(agg) {
  if (is.null(agg)) return(agg)
  merge(agg, typgrp_names, by = "TYPGRPCD", all.x = TRUE)
}
sub_agg <- merge_named(sub_agg)
d1_agg  <- merge_named(d1_agg)
d2_agg  <- merge_named(d2_agg)
d3_agg  <- merge_named(d3_agg)

# Long comparison
all_agg <- rbind(sub_agg, d1_agg, d2_agg, d3_agg)
fwrite(all_agg, file.path(OUT_DIR, "wa_westside_donor_comparison.csv"))

# Gap table for top 8 by WA share
top_groups <- sub_agg[!is.na(GROUP_NAME)][order(-pct_area)][1:8]
gap_tab <- data.table::CJ(TYPGRPCD = top_groups$TYPGRPCD,
                            config = c("donor_full_OR_ID_MT",
                                       "donor_OR_westside_only",
                                       "donor_OR_west_plus_WA_west"))
gap_tab <- merge(gap_tab,
                  top_groups[, .(TYPGRPCD, GROUP_NAME, wa_pct = pct_area)],
                  by = "TYPGRPCD")
for (cfg in c("donor_full_OR_ID_MT", "donor_OR_westside_only",
              "donor_OR_west_plus_WA_west")) {
  cfg_agg <- switch(cfg,
                     donor_full_OR_ID_MT        = d1_agg,
                     donor_OR_westside_only     = d2_agg,
                     donor_OR_west_plus_WA_west = d3_agg)
  if (is.null(cfg_agg)) next
  m <- cfg_agg[, .(TYPGRPCD, donor_pct = pct_area)]
  gap_tab[config == cfg, donor_pct := m$donor_pct[match(gap_tab$TYPGRPCD[gap_tab$config == cfg], m$TYPGRPCD)]]
}
gap_tab[is.na(donor_pct), donor_pct := 0]
gap_tab[, gap_pct := wa_pct - donor_pct]
fwrite(gap_tab, file.path(OUT_DIR, "wa_westside_donor_gap_table.csv"))

# Plot: top 8 groups, side by side bars per donor config
plot_long <- rbind(
  sub_agg[!is.na(GROUP_NAME)][order(-pct_area)][1:8][
    , .(GROUP_NAME, source = "WA subject",          pct = pct_area)],
  d1_agg[!is.na(GROUP_NAME)][TYPGRPCD %in% top_groups$TYPGRPCD][
    , .(GROUP_NAME, source = "OR+ID+MT donor (current)",     pct = pct_area)],
  d2_agg[!is.na(GROUP_NAME)][TYPGRPCD %in% top_groups$TYPGRPCD][
    , .(GROUP_NAME, source = "OR west-of-Cascades",          pct = pct_area)],
  d3_agg[!is.na(GROUP_NAME)][TYPGRPCD %in% top_groups$TYPGRPCD][
    , .(GROUP_NAME, source = "OR west + WA west (best case)", pct = pct_area)]
)
plot_long[, GROUP_NAME := factor(GROUP_NAME, levels = top_groups$GROUP_NAME)]
plot_long[, source := factor(source, levels = c(
  "WA subject", "OR+ID+MT donor (current)",
  "OR west-of-Cascades", "OR west + WA west (best case)"
))]

p <- ggplot(plot_long, aes(x = GROUP_NAME, y = pct, fill = source)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.8) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_manual(values = c(
    "WA subject"                     = "#1f3a4d",
    "OR+ID+MT donor (current)"       = "#c0504d",
    "OR west-of-Cascades"            = "#d4a76a",
    "OR west + WA west (best case)"  = "#6a9c5a"
  )) +
  coord_flip() +
  labs(
    title    = "WA donor pool remediation: cascading restriction tightens forest type match",
    subtitle = "Top 8 forest type groups by WA subject area share, baseline 1999-2008 forested conds",
    x = NULL, y = "Share of forested area (%)", fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title       = element_text(face = "bold"),
        legend.position  = "bottom")

ggsave(file.path(OUT_DIR, "wa_westside_donor_prototype.png"),
       plot = p, width = 10, height = 7, dpi = 150, bg = "white")

# Summary text
sink(file.path(OUT_DIR, "wa_westside_donor_prototype_summary.txt"))
cat("WA WEST-OF-CASCADE DONOR PROTOTYPE\n")
cat("==================================\n")
cat(sprintf("Cascade LON cutoff: %.1f deg W\n", CASCADE_LON_CUT))
cat(sprintf("WA subject (forested baseline) conds: %d\n", nrow(sub_full)))
cat(sprintf("Donor config 1 (current OR+ID+MT):    %d conds\n", nrow(donor_config_1)))
cat(sprintf("Donor config 2 (OR westside only):     %d conds\n", nrow(donor_config_2)))
cat(sprintf("Donor config 3 (OR west + WA west):   %d conds\n", nrow(donor_config_3)))
cat("\nGap table by donor config for top 8 WA groups:\n")
print(gap_tab[order(GROUP_NAME, config),
              .(GROUP_NAME, config,
                wa_pct = round(wa_pct, 3),
                donor_pct = round(donor_pct, 3),
                gap_pct = round(gap_pct, 3))])
cat("\nTotal absolute gap (sum of |gap_pct| over top 8 groups):\n")
print(gap_tab[, .(total_abs_gap = round(sum(abs(gap_pct)), 3)), by = config])
sink()

cat("Outputs at:", OUT_DIR, "\n")
