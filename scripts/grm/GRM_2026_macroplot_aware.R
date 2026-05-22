# =============================================================================
# Title: FIA GRM plot summary, macroplot-aware gross growth
# Author: A. Weiskittel
# Date: 2026-05-22
# Description:
#   Builds plot-level Growth / Removal / Mortality (GRM) summaries from the FIA
#   TREE_GRM_COMPONENT and TREE tables. This is a refinement of GRM_2026.r that
#   makes the gross growth, removals, and mortality expansion macroplot-aware,
#   in response to John Shaw's email of 2026-05-22 ("FIA growth calcs").
#
#   John's point: when a tree crosses the 5 in subplot threshold, FIA estimates
#   its T1 and midpoint diameters so the ingrowth gets a gross growth value that
#   is added to the remeasured trees. The same is NOT done for trees crossing
#   the macroplot threshold (24 in or 30 in in the PNW). The original script
#   compounded this by expanding flux with the SUBPLOT design only
#   (SUBP_TPAGROW_UNADJ_AL_FOREST), so in macroplot states the entire macroplot
#   tree pool was dropped from gross growth, removals, and mortality.
#
#   Fix in this version: expand each flux with SUBPLOT + MACROPLOT design TPA
#   (see combine_designs). Microplot is deliberately excluded, because the 5 in
#   ingrowth trees are already booked on the subplot; adding the microplot pool
#   double counts them (verified on Maine data: adding microplot inflated gross
#   growth by ~146 percent, which is an artifact, not a correction).
#
#   Behavior by region:
#     Eastern states (no macroplot, e.g. Maine): MACR_* columns are absent, so
#       combine_designs falls back to subplot only and results are IDENTICAL to
#       GRM_2026.r. This script is a no-op there.
#     Western / PNW states (macroplot present): macroplot survivors are now
#       included in all three fluxes.
#
#   Residual limitation (NOT auto-fixed, see NOTE near the flux block): the
#   specific gross growth for trees that cross the macroplot threshold during
#   the period is still only as good as what FIA books in GROWTSAL_FOREST /
#   MACR_TPAGROW. If FIA leaves those ingrowth trees without a midpoint based
#   gross growth value, a downward bias remains. Reconstructing it from
#   TREE_GRM_BEGIN / TREE_GRM_MIDPT is sketched at the bottom and should be
#   validated on a macroplot state with John before trusting national totals.
#
# Dependencies (set data_dir below):
#   ENTIRE_TREE_GRM_COMPONENT.csv, ENTIRE_TREE.csv, ENTIRE_REF_SPECIES.csv,
#   leaf.longevity.values.FIA.code.csv, Shade_Tolerance_Edit.csv
# =============================================================================

library(data.table)

# --- Paths (no setwd; set once here) -----------------------------------------
# Point this at the folder holding the ENTIRE_* GRM exports and reference CSVs.
data_dir <- "D:/GRM"
out_dir  <- data_dir
f <- function(name) file.path(data_dir, name)

# --- Design-combining helper -------------------------------------------------
# Sum unadjusted per-acre TPA across the requested plot designs, treating
# absent columns and NA as 0. Subplot and macroplot are design-exclusive for a
# given tree, so summing them selects the correct design without double counting.
# Microplot is intentionally NOT combined here (it would double count 5 in
# ingrowth already carried on the subplot).
combine_designs <- function(dt, cols) {
  present <- intersect(cols, names(dt))
  if (length(present) == 0L) return(rep(0, nrow(dt)))
  m <- as.matrix(dt[, ..present])
  m[is.na(m)] <- 0
  as.numeric(rowSums(m))
}

grow_design_cols <- c("SUBP_TPAGROW_UNADJ_AL_FOREST", "MACR_TPAGROW_UNADJ_AL_FOREST")
remv_design_cols <- c("SUBP_TPAREMV_UNADJ_AL_FOREST", "MACR_TPAREMV_UNADJ_AL_FOREST")
mort_design_cols <- c("SUBP_TPAMORT_UNADJ_AL_FOREST", "MACR_TPAMORT_UNADJ_AL_FOREST")

z0 <- function(x) ifelse(is.na(x), 0, x)

# --- Optional: reconstruct gross growth for macroplot-threshold ingrowth ------
# John Shaw (2026-05-22): FIA estimates T1 and midpoint diameters for trees that
# cross the 5 in subplot threshold so the ingrowth gets a gross growth value, but
# does NOT do this for trees crossing the macroplot threshold (24 or 30 in). This
# scaffold mirrors the subplot treatment for macroplot ingrowth. It is OFF by
# default (do_reconstruct) and requires GRM data that RETAINS MACR_* and a
# populated SUBPTYP_* (see fia_grm_extract_macroplot.R; the current Cardinal
# exports drop both). Validate against an EVALIDator gross growth query for one
# PNW state before trusting any national totals it produces.
#
# Arguments:
#   dt            data.table/data.frame with SUBPTYP_BEGIN/END, DIA_END,
#                 GROWTSAL_FOREST, MACR_TPAGROW_UNADJ_AL_FOREST, REMPER
#   breakpoint_in macroplot threshold diameter (24 in interior West, 30 in coastal PNW)
#   vol_at_dia    function(diameter_in) returning gross cubic-foot stem volume;
#                 supply your VOLCFGRS allometry. If NULL the routine no-ops.
reconstruct_macro_ingrowth <- function(dt, breakpoint_in = 24, vol_at_dia = NULL) {
  needed <- c("SUBPTYP_BEGIN", "SUBPTYP_END", "DIA_END",
              "GROWTSAL_FOREST", "MACR_TPAGROW_UNADJ_AL_FOREST", "REMPER")
  add <- rep(0, nrow(dt))
  if (!all(needed %in% names(dt))) {
    message("reconstruct_macro_ingrowth: needs ", paste(setdiff(needed, names(dt)), collapse = ", "),
            "; skipping (re-pull GRM with macroplot columns).")
    return(add)
  }
  is_ing <- !is.na(dt$SUBPTYP_END) & dt$SUBPTYP_END == 3 &
            (is.na(dt$SUBPTYP_BEGIN) | dt$SUBPTYP_BEGIN != 3)
  target <- is_ing &
            (is.na(dt$GROWTSAL_FOREST) | dt$GROWTSAL_FOREST == 0) &
            z0(dt$MACR_TPAGROW_UNADJ_AL_FOREST) > 0 &
            !is.na(dt$REMPER) & dt$REMPER > 0
  if (!any(target)) return(add)
  if (is.null(vol_at_dia)) {
    message("reconstruct_macro_ingrowth: supply vol_at_dia(); ", sum(target),
            " macroplot ingrowth trees left unreconstructed.")
    return(add)
  }
  ann <- (vol_at_dia(dt$DIA_END[target]) - vol_at_dia(rep(breakpoint_in, sum(target)))) /
         dt$REMPER[target]
  add[target] <- pmax(ann, 0) * dt$MACR_TPAGROW_UNADJ_AL_FOREST[target]
  cat("reconstruct_macro_ingrowth: added gross growth for", sum(target),
      "macroplot ingrowth trees\n")
  add
}

# Toggle the ingrowth reconstruction (requires re-pulled MACR data + a vol model)
do_reconstruct <- FALSE

# --- Load GRM component table ------------------------------------------------
GRM.CMPN <- fread(f('ENTIRE_TREE_GRM_COMPONENT.csv'))

# Keep the columns we use, including MACR_* when the export carries them.
grm_keep <- c("TRE_CN", "PREV_TRE_CN", "DIA_BEGIN", "DIA_MIDPT", "DIA_END",
              "ANN_DIA_GROWTH", "ANN_HT_GROWTH",
              "MICR_COMPONENT_AL_FOREST", "SUBP_COMPONENT_AL_FOREST",
              "MACR_COMPONENT_AL_FOREST",
              grow_design_cols, remv_design_cols, mort_design_cols,
              "GROWTSAL_FOREST", "REMVTSAL_FOREST", "MORTTSAL_FOREST")
grm_keep <- intersect(grm_keep, names(GRM.CMPN))
GRM.CMPN <- subset(GRM.CMPN, select = grm_keep)

has_macr <- any(grepl("^MACR_TPA", names(GRM.CMPN)))
cat("Macroplot TPA columns present in this export:", has_macr, "\n")

# Drop GRM rows with no previous tree link
GRM.CMPN <- GRM.CMPN[!is.na(GRM.CMPN$PREV_TRE_CN), ]
GRM.CMPN$PREV_TRE_CN <- as.factor(GRM.CMPN$PREV_TRE_CN)

# --- Load and subset TREE table ----------------------------------------------
TREE <- fread(f('ENTIRE_TREE.csv'))
TREE <- subset(TREE, select = c(
  "CN", "PLT_CN", "PREV_TRE_CN", "INVYR", "STATECD", "UNITCD", "COUNTYCD",
  "PLOT", "SUBP", "TREE", "CONDID", "PREVCOND", "STATUSCD", "SPCD",
  "SPGRPCD", "DIA", "DIAHTCD", "HT", "HTCD", "ACTUALHT", "TREECLCD", "CR",
  "CCLCD", "VOLCFGRS", "TPA_UNADJ", "PREVDIA", "CARBON_AG", "VOLTSGRS"
))
TREE$PREV_TRE_CN <- as.factor(TREE$PREV_TRE_CN)

# --- Preserve ingrowth trees in TREE x GRM merge (FIX 1 from GRM_2026.r) ------
TREE.tbl <- data.table(TREE,     key = "PREV_TRE_CN")
TREE.GRM <- data.table(GRM.CMPN, key = "PREV_TRE_CN")

TREE2.remeas <- merge(
  TREE.tbl[!is.na(TREE.tbl$PREV_TRE_CN), ],
  TREE.GRM,
  by    = "PREV_TRE_CN",
  all.x = TRUE
)
TREE2.ingrowth <- TREE.tbl[is.na(TREE.tbl$PREV_TRE_CN), ]
TREE2 <- rbind(TREE2.remeas, TREE2.ingrowth, fill = TRUE)

cat("Trees in TREE table          :", nrow(TREE), "\n")
cat("Trees after TREE x GRM merge :", nrow(TREE2), "\n")
cat("  of which remeasured        :", nrow(TREE2.remeas), "\n")
cat("  of which ingrowth          :", nrow(TREE2.ingrowth), "\n")

# --- Derived standing-stock variables ----------------------------------------
TREE2$TPA_UNADJ <- ifelse(is.na(TREE2$TPA_UNADJ), 0, TREE2$TPA_UNADJ)
TREE2$CVR       <- TREE2$CARBON_AG / TREE2$VOLCFGRS

# --- Flux expansion: macroplot-aware (subplot + macroplot) -------------------
# NOTE (John Shaw 2026-05-22): combining subplot and macroplot recovers the
# macroplot tree pool that the original subplot-only code dropped. It does NOT,
# by itself, reconstruct gross growth for trees that cross the macroplot
# threshold mid-period if FIA never assigned them a midpoint-based growth value.
# That residual is documented at the bottom of this script.
grow_tpa <- combine_designs(TREE2, grow_design_cols)
remv_tpa <- combine_designs(TREE2, remv_design_cols)
mort_tpa <- combine_designs(TREE2, mort_design_cols)

TREE2$dVOL.LIVE <- ifelse(!is.na(TREE2$GROWTSAL_FOREST), TREE2$GROWTSAL_FOREST * grow_tpa, NA)
TREE2$dVOL.REMV <- ifelse(!is.na(TREE2$REMVTSAL_FOREST), TREE2$REMVTSAL_FOREST * remv_tpa, NA)
TREE2$dVOL.MORT <- ifelse(!is.na(TREE2$MORTTSAL_FOREST), TREE2$MORTTSAL_FOREST * mort_tpa, NA)

# Optional: add reconstructed gross growth for macroplot-threshold ingrowth.
# No-op unless do_reconstruct is TRUE AND the data carries MACR_/SUBPTYP/REMPER.
if (do_reconstruct) {
  TREE2$dVOL.LIVE <- z0(TREE2$dVOL.LIVE) +
    reconstruct_macro_ingrowth(TREE2, breakpoint_in = 24, vol_at_dia = NULL)
}

# Transparency: how much does the macroplot inclusion change gross growth here?
if (has_macr) {
  old_live <- sum(ifelse(!is.na(TREE2$GROWTSAL_FOREST),
                         TREE2$GROWTSAL_FOREST * combine_designs(TREE2, "SUBP_TPAGROW_UNADJ_AL_FOREST"),
                         NA), na.rm = TRUE)
  new_live <- sum(TREE2$dVOL.LIVE, na.rm = TRUE)
  cat(sprintf("Gross growth subplot-only : %.1f\n", old_live))
  cat(sprintf("Gross growth subp+macro   : %.1f  (+%.3f%% from macroplot)\n",
              new_live, 100 * (new_live - old_live) / old_live))
} else {
  cat("No macroplot columns: results identical to subplot-only GRM_2026.r\n")
}

TREE2$dCARB.LIVE <- ifelse(!is.na(TREE2$dVOL.LIVE), TREE2$dVOL.LIVE * TREE2$CVR, NA)
TREE2$dCARB.REMV <- ifelse(!is.na(TREE2$dVOL.REMV), TREE2$dVOL.REMV * TREE2$CVR, NA)
TREE2$dCARB.MORT <- ifelse(!is.na(TREE2$dVOL.MORT), TREE2$dVOL.MORT * TREE2$CVR, NA)

# Standing-stock variables (all trees, including ingrowth)
TREE2$BA   <- 0.005454 * TREE2$DIA^2 * TREE2$TPA_UNADJ
TREE2$VOL  <- TREE2$VOLCFGRS * TREE2$TPA_UNADJ
TREE2$SDI  <- (TREE2$DIA / 10)^1.605 * TREE2$TPA_UNADJ
TREE2$CARB <- TREE2$CARBON_AG * TREE2$TPA_UNADJ

# --- Species trait tables ----------------------------------------------------
SPCD <- read.csv(f('ENTIRE_REF_SPECIES.csv'))
SPCD$SG <- SPCD$WOOD_SPGR_GREENVOL_DRYWT
SPCD <- subset(SPCD, select = c('SPCD', 'SFTWD_HRDWD', 'SG'))

ll <- read.csv(f('leaf.longevity.values.FIA.code.csv'))
names(ll)[2] <- 'LL_mos'
ll <- subset(ll, select = c('SPCD', 'LL_mos'))
ll <- merge(ll, SPCD, by = 'SPCD', all = TRUE)

TOL <- read.csv(f('Shade_Tolerance_Edit.csv'))
TOL <- subset(TOL, select = c('SPCD', 'Shade_Tolerance'))
TOL <- merge(ll, TOL, by = 'SPCD', all = TRUE)

ll.HW <- mean(ll[ll$SFTWD_HRDWD == 'H', ]$LL_mos, na.rm = TRUE)
ll.SW <- mean(ll[ll$SFTWD_HRDWD == 'S', ]$LL_mos, na.rm = TRUE)
SG.HW <- mean(TOL[TOL$SFTWD_HRDWD == 'H', ]$SG,   na.rm = TRUE)
SG.SW <- mean(TOL[TOL$SFTWD_HRDWD == 'S', ]$SG,   na.rm = TRUE)
ST.HW <- mean(TOL[TOL$SFTWD_HRDWD == 'H', ]$Shade_Tolerance, na.rm = TRUE)
ST.SW <- mean(TOL[TOL$SFTWD_HRDWD == 'S', ]$Shade_Tolerance, na.rm = TRUE)

TREE2 <- merge(TREE2, TOL, by = 'SPCD', all.x = TRUE)
TREE2$LL_mos <- ifelse(
  is.na(TREE2$LL_mos) & TREE2$SFTWD_HRDWD == 'H', ll.HW,
  ifelse(is.na(TREE2$LL_mos) & TREE2$SFTWD_HRDWD == 'S', ll.SW, TREE2$LL_mos))
TREE2$SG <- ifelse(
  is.na(TREE2$SG) & TREE2$SFTWD_HRDWD == 'H', SG.HW,
  ifelse(is.na(TREE2$SG) & TREE2$SFTWD_HRDWD == 'S', SG.SW, TREE2$SG))
TREE2$Shade_Tolerance <- ifelse(
  is.na(TREE2$Shade_Tolerance) & TREE2$SFTWD_HRDWD == 'H', ST.HW,
  ifelse(is.na(TREE2$Shade_Tolerance) & TREE2$SFTWD_HRDWD == 'S', ST.SW, TREE2$Shade_Tolerance))
TREE2$BA.HW <- ifelse(TREE2$SFTWD_HRDWD == 'H', TREE2$BA, 0)

# Drop only trees genuinely missing DIA or TPA
n.before.nafilter <- nrow(TREE2)
TREE2 <- TREE2[!is.na(TREE2$DIA) & !is.na(TREE2$TPA_UNADJ), ]
cat("Trees removed by NA DIA/TPA filter:", n.before.nafilter - nrow(TREE2), "\n")
cat("Trees remaining for analysis       :", nrow(TREE2), "\n")
write.csv(TREE2, file.path(out_dir, 'TREE2_Claude.csv'), row.names = FALSE)

# Fix VOLCFGRS and CARBON_AG zeros/NAs before CVR
TREE2$VOLCFGRS  <- ifelse(is.na(TREE2$VOLCFGRS),  0, TREE2$VOLCFGRS)
TREE2$CARBON_AG <- ifelse(is.na(TREE2$CARBON_AG), 0, TREE2$CARBON_AG)
TREE2$CVR <- ifelse(TREE2$VOLCFGRS == 0, NA, TREE2$CARBON_AG / TREE2$VOLCFGRS)

TREE2$VOL  <- TREE2$VOLCFGRS  * TREE2$TPA_UNADJ
TREE2$CARB <- TREE2$CARBON_AG * TREE2$TPA_UNADJ

TREE2$dCARB.LIVE <- ifelse(!is.na(TREE2$dVOL.LIVE) & !is.na(TREE2$CVR), TREE2$dVOL.LIVE * TREE2$CVR, NA)
TREE2$dCARB.REMV <- ifelse(!is.na(TREE2$dVOL.REMV) & !is.na(TREE2$CVR), TREE2$dVOL.REMV * TREE2$CVR, NA)
TREE2$dCARB.MORT <- ifelse(!is.na(TREE2$dVOL.MORT) & !is.na(TREE2$CVR), TREE2$dVOL.MORT * TREE2$CVR, NA)

# --- Species-level size quantiles --------------------------------------------
library(plyr)
library(dplyr)
SPCD.sum <- ddply(TREE2, .(SPCD), summarize,
  DBH.p99  = quantile(DIA,            .99, na.rm = TRUE),
  HT.p99   = quantile(HT,             .99, na.rm = TRUE),
  VOL.p99  = quantile(VOLCFGRS,       .99, na.rm = TRUE),
  dDBH.p99 = quantile(ANN_DIA_GROWTH, .99, na.rm = TRUE),
  dHT      = quantile(ANN_HT_GROWTH,  .99, na.rm = TRUE)
)
write.csv(SPCD.sum, file.path(out_dir, 'SPCD.sum.csv'), row.names = FALSE)

# --- Top-height helper (vectorized) ------------------------------------------
TREE2 <- arrange(TREE2, STATECD, UNITCD, COUNTYCD, PLOT, INVYR, desc(DIA))
setDT(TREE2)
setorder(TREE2, STATECD, UNITCD, COUNTYCD, PLOT, INVYR, -DIA)

TREE2[, cum.EXPF := cumsum(TPA_UNADJ),
      by = .(STATECD, UNITCD, COUNTYCD, PLOT, INVYR)]
TREE2[, tree.inc := fcase(
  cum.EXPF - TPA_UNADJ < 40 & cum.EXPF <= 40, TPA_UNADJ,
  cum.EXPF - TPA_UNADJ < 40 & cum.EXPF > 40,  40 - (cum.EXPF - TPA_UNADJ),
  default = 0
)]
TREE2[, wt.HT := tree.inc * ifelse(is.na(HT), 0, HT)]
TREE2[, tree.inc.ht := tree.inc * ifelse(is.na(HT), 0, 1)]
topht <- TREE2[, .(
  TOPHT = ifelse(sum(tree.inc.ht) > 0, sum(wt.HT) / sum(tree.inc.ht), mean(HT, na.rm = TRUE))
), by = .(STATECD, UNITCD, COUNTYCD, PLOT, INVYR)]
TREE2[, c('cum.EXPF', 'tree.inc', 'wt.HT', 'tree.inc.ht') := NULL]
write.csv(topht, file.path(out_dir, 'topht.csv'), row.names = FALSE)

# --- Plot-level summaries ----------------------------------------------------
library(plyr)
GRM.PLT.sum <- ddply(
  TREE2,
  .(STATECD, UNITCD, COUNTYCD, PLOT, INVYR),
  summarize,
  TPA        = sum(TPA_UNADJ,  na.rm = TRUE),
  VOL        = sum(VOL,        na.rm = TRUE),
  SDI        = sum(SDI,        na.rm = TRUE),
  BAPA       = sum(BA,         na.rm = TRUE),
  CARB       = sum(CARB,       na.rm = TRUE),
  meanDBH    = mean(DIA,       na.rm = TRUE),
  sdDBH      = sd(DIA,         na.rm = TRUE),
  meanHT     = mean(HT,        na.rm = TRUE),
  sdHT       = sd(HT,          na.rm = TRUE),
  dVOL.LIVE  = sum(dVOL.LIVE,  na.rm = TRUE),
  dVOL.REMV  = sum(dVOL.REMV,  na.rm = TRUE),
  dVOL.MORT  = sum(dVOL.MORT,  na.rm = TRUE),
  dCARB.LIVE = sum(dCARB.LIVE, na.rm = TRUE),
  dCARB.REMV = sum(dCARB.REMV, na.rm = TRUE),
  dCARB.MORT = sum(dCARB.MORT, na.rm = TRUE),
  SG         = mean(SG,        na.rm = TRUE),
  LL         = mean(LL_mos,    na.rm = TRUE),
  mVOL       = mean(VOLCFGRS,  na.rm = TRUE),
  BA.HW      = sum(BA.HW,      na.rm = TRUE),
  ST         = mean(Shade_Tolerance, na.rm = TRUE)
)

# Unit conversions
GRM.PLT.sum$dVOL.LIVE.ft3.ac.yr <- GRM.PLT.sum$dVOL.LIVE
GRM.PLT.sum$dVOL.REMV.ft3.ac.yr <- GRM.PLT.sum$dVOL.REMV
GRM.PLT.sum$dVOL.MORT.ft3.ac.yr <- GRM.PLT.sum$dVOL.MORT
GRM.PLT.sum$dCARB.LIVE.t.ac.yr  <- GRM.PLT.sum$dCARB.LIVE / 2000
GRM.PLT.sum$dCARB.REMV.t.ac.yr  <- GRM.PLT.sum$dCARB.REMV / 2000
GRM.PLT.sum$dCARB.MORT.t.ac.yr  <- GRM.PLT.sum$dCARB.MORT / 2000
GRM.PLT.sum$dVOL.LIVE  <- GRM.PLT.sum$dVOL.REMV  <- GRM.PLT.sum$dVOL.MORT  <- NULL
GRM.PLT.sum$dCARB.LIVE <- GRM.PLT.sum$dCARB.REMV <- GRM.PLT.sum$dCARB.MORT <- NULL

GRM.PLT.sum$dVOL.LIVE.m3.ha.yr  <- GRM.PLT.sum$dVOL.LIVE.ft3.ac.yr  * 0.0699725
GRM.PLT.sum$dVOL.REMV.m3.ha.yr  <- GRM.PLT.sum$dVOL.REMV.ft3.ac.yr  * 0.0699725
GRM.PLT.sum$dVOL.MORT.m3.ha.yr  <- GRM.PLT.sum$dVOL.MORT.ft3.ac.yr  * 0.0699725
GRM.PLT.sum$dCARB.LIVE.t.ha.yr  <- GRM.PLT.sum$dCARB.LIVE.t.ac.yr   * 2.24719101
GRM.PLT.sum$dCARB.REMV.t.ha.yr  <- GRM.PLT.sum$dCARB.REMV.t.ac.yr   * 2.24719101
GRM.PLT.sum$dCARB.MORT.t.ha.yr  <- GRM.PLT.sum$dCARB.MORT.t.ac.yr   * 2.24719101

GRM.PLT.sum <- merge(GRM.PLT.sum, topht,
                     by    = c('STATECD', 'UNITCD', 'COUNTYCD', 'PLOT', 'INVYR'),
                     all.x = TRUE)
summary(GRM.PLT.sum)
write.csv(GRM.PLT.sum, file.path(out_dir, 'GRM.PLT.macroplot_aware.csv'), row.names = FALSE)

# =============================================================================
# NOTE / TODO: residual macroplot-threshold ingrowth (John Shaw 2026-05-22)
# -----------------------------------------------------------------------------
# Including MACR_TPAGROW recovers macroplot SURVIVORS. It does not, on its own,
# create a gross growth value for a tree that grew across the macroplot
# breakpoint (24/30 in) during the period if FIA never estimated its T1 and
# midpoint diameters. To mirror what FIA does at the 5 in subplot threshold:
#   1. Flag macroplot ingrowth: MACR_COMPONENT_AL_FOREST == "INGROWTH".
#   2. Pull DIA_BEGIN / DIA_MIDPT / DIA_END from TREE_GRM_COMPONENT (or the
#      TREE_GRM_BEGIN / TREE_GRM_MIDPT tables) for those trees.
#   3. Where the begin/midpoint volume is missing, estimate it from the breakpoint
#      diameter forward, compute the implied annual gross growth, and add it to
#      dVOL.LIVE for those records.
# This changes only macroplot states and should be validated against an EVALIDator
# gross growth query for one PNW state, with John, before national use.
# =============================================================================
