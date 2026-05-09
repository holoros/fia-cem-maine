## build_sdimax_l3_ecoregion_table.R
## Aggregate plot-specific BRMS SDImax estimates (Weiskittel et al.) by EPA
## Omernik Level III ecoregion and FIA forest type group, across the four
## target states ME (23), MN (27), WA (53), GA (13).
##
## Multistate replacement for build_sdimax_ecoregion_table.R, which uses
## a Maine-specific county-to-ecoregion crosswalk and a Maine-specific
## FORTYPCD-to-fortype-group lookup. This version uses:
##
##   ecoregion key   = us_l3code (from fia_plots_hcb_l3.csv)
##   fortype group   = FIA TYPGRPCD (from ENTIRE_COND.csv), the national
##                     forest-type-group classification
##
## Inputs (on Cardinal):
##   ~/fia_cem_projections/config/brms_SDImax_plot.csv  CONUS BRMS posteriors
##                                                      (STATECD, UNITCD,
##                                                       COUNTYCD, PLOT, ID,
##                                                       SDImax.mean,
##                                                       SDImax.median)
##                                                      Units: trees per hectare.
##   ~/fia_cem_projections/config/fia_plots_hcb_l3.csv  Plot-keyed HCB x L3
##                                                      crosswalk (built today
##                                                      by build_hcb_l3_crosswalk.R)
##   ~/fia_cem_projections/config/REF_FOREST_TYPE.csv   FIA reference: FORTYPCD
##                                                      (VALUE) to TYPGRPCD
##                                                      (and MEANING string).
##
## Outputs:
##   config/sdimax_by_l3_ecoregion.csv          by L3 ecoregion alone
##   config/sdimax_by_l3_typgroup.csv           by L3 ecoregion x TYPGRPCD
##   config/sdimax_by_typgroup.csv              by TYPGRPCD alone (national)
##   config/sdimax_by_l3_typgroup_compact.csv   filtered to n_plots >= 5
##
## Usage on Cardinal:
##   module load gcc/12.3.0 R/4.4.0
##   Rscript scripts/build_sdimax_l3_ecoregion_table.R
##
## Conversion: SDImax_english (trees per acre) = SDImax_metric (trees per
## hectare) * 0.40468564 (one acre is 0.40468564 hectares).

suppressPackageStartupMessages({
  library(data.table); library(dplyr); library(readr)
})

CONFIG_DIR <- file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
BRMS_CSV    <- file.path(CONFIG_DIR, "brms_SDImax_plot.csv")
HCB_L3_CSV  <- file.path(CONFIG_DIR, "fia_plots_hcb_l3.csv")
FT_REF_CSV  <- file.path(CONFIG_DIR, "REF_FOREST_TYPE.csv")

stopifnot(file.exists(BRMS_CSV), file.exists(HCB_L3_CSV), file.exists(FT_REF_CSV))

TARGETS <- c(ME = 23L, MN = 27L, WA = 53L, GA = 13L)
M_TO_E  <- 0.40468564  # acres per hectare

cat("============================================\n")
cat("  SDImax by L3 ecoregion x forest-type group\n")
cat(sprintf("  States   : %s (STATECDs %s)\n",
            paste(names(TARGETS), collapse = ", "),
            paste(TARGETS, collapse = ", ")))
cat(sprintf("  BRMS CSV : %s\n", BRMS_CSV))
cat(sprintf("  HCB x L3 : %s\n", HCB_L3_CSV))
cat("============================================\n\n")

## ---- Load BRMS plot SDImax (CONUS) -------------------------------------
cat("Loading BRMS plot SDImax...\n")
brms <- data.table::fread(
  BRMS_CSV,
  select = c("STATECD", "UNITCD", "COUNTYCD", "PLOT",
             "SDImax.mean", "SDImax.median"),
  data.table = FALSE,
  showProgress = FALSE
)
names(brms)[names(brms) == "SDImax.mean"]   <- "sdimax_m_mean"
names(brms)[names(brms) == "SDImax.median"] <- "sdimax_m_median"
brms <- brms[brms$STATECD %in% TARGETS, ]
cat(sprintf("  retained %d BRMS plot rows across STATECDs %s\n",
            nrow(brms),
            paste(sort(unique(brms$STATECD)), collapse = ", ")))

if (nrow(brms) == 0) {
  stop("BRMS plot file has no rows for target states; cannot proceed.")
}

## English-units conversion (per acre).
brms$sdimax_e_mean   <- brms$sdimax_m_mean   * M_TO_E
brms$sdimax_e_median <- brms$sdimax_m_median * M_TO_E

## ---- Load HCB x L3 crosswalk -------------------------------------------
cat("Loading HCB x L3 crosswalk...\n")
hcb_l3 <- data.table::fread(HCB_L3_CSV, data.table = FALSE,
                            showProgress = FALSE)
cat(sprintf("  %d plot rows; columns: %s\n",
            nrow(hcb_l3), paste(names(hcb_l3), collapse = ", ")))

## ---- Load FORTYPCD -> TYPGRPCD reference -------------------------------
## REF_FOREST_TYPE.csv has a duplicated header row in the source; skip it.
cat("Loading FORTYPCD -> TYPGRPCD reference...\n")
ft_ref_raw <- data.table::fread(FT_REF_CSV, data.table = FALSE,
                                showProgress = FALSE)
ft_ref <- ft_ref_raw |>
  dplyr::filter(VALUE != "VALUE") |>
  dplyr::transmute(FORTYPCD = suppressWarnings(as.integer(VALUE)),
                   TYPGRPCD = suppressWarnings(as.integer(TYPGRPCD)),
                   fortype_label = MEANING) |>
  dplyr::filter(!is.na(FORTYPCD))
cat(sprintf("  reference: %d FORTYPCD rows; %d unique TYPGRPCDs\n",
            nrow(ft_ref), length(unique(ft_ref$TYPGRPCD))))

## ---- Join everything ---------------------------------------------------
## Match on STATECD, UNITCD, COUNTYCD, PLOT (BRMS uses these) since BRMS
## file has no PLT_CN. Then map FORTYPCD -> TYPGRPCD via reference.
brms_joined <- brms |>
  dplyr::left_join(
    hcb_l3 |> dplyr::select(STATECD, UNITCD, COUNTYCD, PLOT, PLT_CN,
                            us_l3code, us_l3name, FORTYPCD,
                            hcb_class, OWNGRPCD),
    by = c("STATECD", "UNITCD", "COUNTYCD", "PLOT")
  ) |>
  dplyr::left_join(ft_ref, by = "FORTYPCD")

cat(sprintf("Joined: %d rows; %d with us_l3code; %d with TYPGRPCD\n",
            nrow(brms_joined),
            sum(!is.na(brms_joined$us_l3code)),
            sum(!is.na(brms_joined$TYPGRPCD))))

## ---- TYPGRPCD label crosswalk (FIA national standard) ------------------
typgroup_lookup <- tibble::tribble(
  ~TYPGRPCD, ~typgroup_label,
  100L, "White-red-jack pine",
  120L, "Spruce-fir",
  140L, "Longleaf-slash pine",
  160L, "Loblolly-shortleaf pine",
  170L, "Other eastern softwoods",
  180L, "Pinyon-juniper",
  200L, "Douglas-fir",
  220L, "Ponderosa pine",
  240L, "Western white pine",
  260L, "Fir-spruce-mountain hemlock",
  280L, "Lodgepole pine",
  300L, "Hemlock-Sitka spruce",
  320L, "Western larch",
  340L, "Redwood",
  360L, "Other western softwoods",
  380L, "Exotic softwoods",
  400L, "Oak-pine",
  500L, "Oak-hickory",
  600L, "Oak-gum-cypress",
  700L, "Elm-ash-cottonwood",
  800L, "Maple-beech-birch",
  900L, "Aspen-birch",
  910L, "Alder-maple",
  920L, "Western oak",
  940L, "Tanoak-laurel",
  950L, "Other western hardwoods",
  960L, "Other hardwoods",
  980L, "Tropical hardwoods",
  990L, "Exotic hardwoods",
  999L, "Nonstocked"
)
brms_joined <- brms_joined |>
  dplyr::left_join(typgroup_lookup, by = "TYPGRPCD") |>
  dplyr::mutate(typgroup_label = ifelse(is.na(typgroup_label),
                                        sprintf("TYPGRPCD %d", TYPGRPCD),
                                        typgroup_label))

## ---- State name lookup (for output readability) ------------------------
state_name <- c("13" = "GA", "23" = "ME", "27" = "MN", "53" = "WA")
brms_joined$state_abbr <- state_name[as.character(brms_joined$STATECD)]

## ---- Summary helper ----------------------------------------------------
sdimax_summary <- function(d, by) {
  d <- d[!is.na(d$sdimax_m_mean), ]
  spl <- split(d, d[, by, drop = FALSE], drop = TRUE)
  if (length(spl) == 0) return(data.frame())
  rows <- lapply(seq_along(spl), function(i) {
    s <- spl[[i]]
    keys <- s[1, by, drop = FALSE]
    cbind(keys,
          n_plots         = nrow(s),
          sdimax_m_mean   = round(mean(s$sdimax_m_mean,   na.rm = TRUE), 0),
          sdimax_m_median = round(median(s$sdimax_m_mean, na.rm = TRUE), 0),
          sdimax_m_p10    = round(quantile(s$sdimax_m_mean, 0.10,
                                            na.rm = TRUE, names = FALSE), 0),
          sdimax_m_p90    = round(quantile(s$sdimax_m_mean, 0.90,
                                            na.rm = TRUE, names = FALSE), 0),
          sdimax_e_mean   = round(mean(s$sdimax_e_mean,   na.rm = TRUE), 0),
          sdimax_e_median = round(median(s$sdimax_e_mean, na.rm = TRUE), 0),
          sdimax_e_p10    = round(quantile(s$sdimax_e_mean, 0.10,
                                            na.rm = TRUE, names = FALSE), 0),
          sdimax_e_p90    = round(quantile(s$sdimax_e_mean, 0.90,
                                            na.rm = TRUE, names = FALSE), 0))
  })
  do.call(rbind, rows)
}

## ---- (1) by L3 ecoregion alone -----------------------------------------
eco <- sdimax_summary(brms_joined, c("us_l3code", "us_l3name"))
eco <- eco[order(-eco$n_plots), ]
write_csv(eco, file.path(CONFIG_DIR, "sdimax_by_l3_ecoregion.csv"))
cat(sprintf("\nWrote sdimax_by_l3_ecoregion.csv: %d rows\n", nrow(eco)))

## ---- (2) by L3 ecoregion x TYPGRPCD ------------------------------------
eco_ft <- sdimax_summary(
  brms_joined,
  c("us_l3code", "us_l3name", "TYPGRPCD", "typgroup_label"))
eco_ft <- eco_ft[order(eco_ft$us_l3code, -eco_ft$n_plots), ]
write_csv(eco_ft, file.path(CONFIG_DIR, "sdimax_by_l3_typgroup.csv"))
cat(sprintf("Wrote sdimax_by_l3_typgroup.csv: %d rows\n", nrow(eco_ft)))

## ---- (2b) Compact (n >= 5) ---------------------------------------------
eco_ft_compact <- eco_ft[eco_ft$n_plots >= 5, ]
write_csv(eco_ft_compact,
          file.path(CONFIG_DIR, "sdimax_by_l3_typgroup_compact.csv"))
cat(sprintf("Wrote sdimax_by_l3_typgroup_compact.csv: %d rows (filtered n>=5)\n",
            nrow(eco_ft_compact)))

## ---- (3) by TYPGRPCD alone (national) ----------------------------------
ft <- sdimax_summary(brms_joined, c("TYPGRPCD", "typgroup_label"))
ft <- ft[order(-ft$n_plots), ]
write_csv(ft, file.path(CONFIG_DIR, "sdimax_by_typgroup.csv"))
cat(sprintf("Wrote sdimax_by_typgroup.csv: %d rows\n", nrow(ft)))

## ---- (4) by state x L3 (for report tables) ------------------------------
st_eco <- sdimax_summary(brms_joined,
                         c("state_abbr", "STATECD", "us_l3code", "us_l3name"))
st_eco <- st_eco[order(st_eco$state_abbr, -st_eco$n_plots), ]
write_csv(st_eco, file.path(CONFIG_DIR, "sdimax_by_state_l3.csv"))
cat(sprintf("Wrote sdimax_by_state_l3.csv: %d rows\n", nrow(st_eco)))

## ---- Console summary ---------------------------------------------------
cat("\n=== L3 ecoregion summary (top 15 by n_plots) ===\n")
print(head(eco, 15), row.names = FALSE)

cat("\n=== State x L3 ecoregion summary ===\n")
print(st_eco, row.names = FALSE)

cat("\n=== TYPGRPCD national summary (top 10) ===\n")
print(head(ft, 10), row.names = FALSE)

cat("\nDone.\n")
