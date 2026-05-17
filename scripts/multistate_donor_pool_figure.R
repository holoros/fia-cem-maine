#!/usr/bin/env Rscript
# multistate_donor_pool_figure.R
# Build a 4-panel unified donor pool composition figure for the manuscript.
# Panels: ME (canonical, near-zero gap expected), MN, WA, GA.
#
# Run on Cardinal using the full CONUS ENTIRE_COND.csv at ~/FIA/.
# Outputs:
#   multistate_donor_pool_comparison.csv (all 4 states + donor pools, TYPGRPCD)
#   multistate_donor_pool_4panel.png

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

ENTIRE_COND <- "/users/PUOM0008/crsfaaron/FIA/ENTIRE_COND.csv"
REF_FORTYP  <- "/users/PUOM0008/crsfaaron/fia_cem_projections/config/REF_FOREST_TYPE.csv"
OUT_DIR     <- "/users/PUOM0008/crsfaaron/fia_cem_projections/output/multistate_donor_pool_20260517"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Subject and donor cohorts per state_constants and HANDOFFs
STATE_DEFS <- list(
  ME = list(subject = c(23L),
             donor = c(33L, 50L, 25L, 9L, 44L, 36L, 42L)),  # NH VT MA CT RI NY PA
  MN = list(subject = c(27L),
             donor = c(55L, 26L, 19L, 17L, 38L, 46L)),       # WI MI IA IL ND SD
  WA = list(subject = c(53L),
             donor = c(41L, 16L, 30L)),                       # OR ID MT
  GA = list(subject = c(13L),
             donor = c(12L, 45L, 37L, 47L, 1L))               # FL SC NC TN AL
)

BASELINE_YEARS <- 1999:2008

cat("Reading ENTIRE_COND.csv...\n")
cond <- data.table::fread(
  ENTIRE_COND,
  select = c("STATECD", "INVYR", "COND_STATUS_CD", "FORTYPCD",
             "CONDPROP_UNADJ"),
  showProgress = FALSE
)
cond <- cond[COND_STATUS_CD == 1 & INVYR %in% BASELINE_YEARS &
              !is.na(FORTYPCD) & FORTYPCD > 0]
cat(sprintf("Forested baseline conds: %d\n", nrow(cond)))

ref <- data.table::fread(REF_FORTYP, showProgress = FALSE)
data.table::setnames(ref, "VALUE", "FORTYPCD")
typgrp_names <- ref[FORTYPCD %in% ref$TYPGRPCD,
                     .(TYPGRPCD = FORTYPCD, GROUP_NAME = MEANING)]
typgrp_names <- unique(typgrp_names, by = "TYPGRPCD")
cond <- merge(cond, ref[, .(FORTYPCD, TYPGRPCD)], by = "FORTYPCD", all.x = TRUE)
cond[is.na(TYPGRPCD), TYPGRPCD := -1]

agg_typgrp <- function(dt, label) {
  dt[, .(area_ha = sum(CONDPROP_UNADJ * 0.404686, na.rm = TRUE)),
     by = TYPGRPCD][
    , pct_area := area_ha / sum(area_ha)][
    , source := label]
}

# Build per-state subject + donor comparisons
all_rows <- list()
for (st in names(STATE_DEFS)) {
  sub_dt <- cond[STATECD %in% STATE_DEFS[[st]]$subject]
  don_dt <- cond[STATECD %in% STATE_DEFS[[st]]$donor]
  sub_agg <- agg_typgrp(sub_dt, paste0(st, "_subject"))
  don_agg <- agg_typgrp(don_dt, paste0(st, "_donor"))
  sub_agg[, state := st]; sub_agg[, side := "subject"]
  don_agg[, state := st]; don_agg[, side := "donor"]
  all_rows[[paste0(st, "_sub")]] <- sub_agg
  all_rows[[paste0(st, "_don")]] <- don_agg
  cat(sprintf("%s: subject %d conds, donor %d conds\n",
              st, nrow(sub_dt), nrow(don_dt)))
}
all_dt <- data.table::rbindlist(all_rows, fill = TRUE)
all_dt <- merge(all_dt, typgrp_names, by = "TYPGRPCD", all.x = TRUE)
all_dt <- all_dt[!is.na(GROUP_NAME)]
fwrite(all_dt, file.path(OUT_DIR, "multistate_donor_pool_comparison.csv"))

# For each state, take top 8 type groups by subject share for the panel
plot_data <- list()
for (st in names(STATE_DEFS)) {
  sub <- all_dt[state == st & side == "subject"][order(-pct_area)][1:8]
  don <- all_dt[state == st & side == "donor" & TYPGRPCD %in% sub$TYPGRPCD]
  sub_long <- sub[, .(state, GROUP_NAME,
                       source = paste0(st, " subject"), pct = pct_area)]
  don_long <- don[, .(state, GROUP_NAME,
                       source = paste0(st, " donor pool"), pct = pct_area)]
  plot_data[[st]] <- rbind(sub_long, don_long)
  plot_data[[st]][, GROUP_NAME := factor(GROUP_NAME, levels = rev(sub$GROUP_NAME))]
}
combined <- data.table::rbindlist(plot_data, fill = TRUE)
combined[, state := factor(state, levels = c("ME", "MN", "WA", "GA"))]
combined[, kind := ifelse(grepl("subject", source), "Subject", "Donor pool")]
combined[, kind := factor(kind, levels = c("Subject", "Donor pool"))]

# Subject/donor side-by-side for each state, by group, faceted
p <- ggplot(combined, aes(x = GROUP_NAME, y = pct, fill = kind)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                      expand = c(0, 0)) +
  scale_fill_manual(values = c("Subject" = "#3a78a3",
                                "Donor pool" = "#c0504d")) +
  facet_wrap(~ state, scales = "free", ncol = 2) +
  coord_flip() +
  labs(
    title    = "Donor pool composition mismatch by state (multistate p1)",
    subtitle = "Top 8 forest type groups by subject area share. Donor pool drawn from neighboring states per state_constants.csv.",
    x = NULL, y = "Share of forested area (%)", fill = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title       = element_text(face = "bold"),
        strip.background = element_rect(fill = "#f0f0f0", color = NA),
        strip.text       = element_text(face = "bold"),
        legend.position  = "bottom")

ggsave(file.path(OUT_DIR, "multistate_donor_pool_4panel.png"),
       plot = p, width = 12, height = 9, dpi = 150, bg = "white")

cat("\nOutputs at:", OUT_DIR, "\n")
