## build_yield_curve_strata.R
## Phase 1.5 from LANDOWNER_INTEGRATION_STRATEGY.md (addendum):
## Build the 6 forest-type × 3 ecoregion × 6 owner-class = 108-cell
## stratification table for Maine, with FIA plot counts per cell.
##
## Cells with n < 30 will be flagged for collapse before yield curve fitting.
##
## Inputs : config/fia_plots_with_owner.csv (HCB owner class per plot)
##          config/sdimax_brms_plot.csv (carries FORTYPCD)
##          (plus county to ecoregion map below)
## Outputs: config/maine_yield_curve_strata.csv

suppressPackageStartupMessages({
  if (requireNamespace("dplyr", quietly = TRUE)) {
    library(dplyr); library(readr); library(tidyr)
    USE_TIDY <- TRUE
  } else {
    USE_TIDY <- FALSE
  }
})

base <- if (Sys.getenv("CONFIG_DIR") != "") Sys.getenv("CONFIG_DIR") else
        file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
cat(sprintf("Using config_dir = %s\n", base))

own <- read.csv(file.path(base, "fia_plots_with_owner.csv"),
                stringsAsFactors = FALSE)
sdi <- read.csv(file.path(base, "sdimax_brms_plot.csv"),
                stringsAsFactors = FALSE)
sdi <- sdi[sdi$STATECD == 23L, ]

cat(sprintf("Maine plots in own: %d, in sdi: %d\n", nrow(own), nrow(sdi)))

## ---- Forest-type group (6 buckets aligned with strategy doc) ----------
ft_group <- function(fortypcd) {
  out <- ifelse(is.na(fortypcd), "Other",
         ifelse(fortypcd >= 121 & fortypcd <= 128, "Spruce-fir",
         ifelse(fortypcd >= 800 & fortypcd <= 809, "Northern hardwood",
         ifelse(fortypcd >= 900 & fortypcd <= 919, "Aspen-birch",
         ifelse(fortypcd >= 700 & fortypcd <= 799, "Mixedwood",
         ifelse(fortypcd >= 100 & fortypcd <= 119, "White/Red pine",
         ifelse(fortypcd >= 400 & fortypcd <= 599, "Oak/Pine/Hemlock",
         "Other")))))))
  out
}

## ---- Ecoregion (3-zone aggregate; matches libcbm Maine AIDB) ----------
me_ecoregion <- function(countycd) {
  ifelse(countycd %in% c(3L, 21L), "ME_NH",     # Northern Highlands
  ifelse(countycd %in% c(7L, 17L, 25L), "ME_NCZ",  # Northern Central Zone
  "ME_APH"))                                       # Acadian Plains/Hills
}

## ---- Build stratification ---------------------------------------------
own$ft_group  <- ft_group(own$FORTYPCD)
own$ecoregion <- me_ecoregion(own$COUNTYCD)

# Drop plots flagged Non-Forest or Water by HCB raster
own_forest <- own[own$hcb_class %in% 3:8, ]
cat(sprintf("Forest plots after HCB filter: %d\n", nrow(own_forest)))

own_forest$owner_label <- factor(own_forest$hcb_class,
                                 levels = c(3, 4, 5, 6, 7, 8),
                                 labels = c("NIPF", "Industrial", "Tribal",
                                            "Federal", "State", "Local"))

## ---- Tabulate ---------------------------------------------------------
agg <- aggregate(PLT_CN ~ ft_group + ecoregion + owner_label,
                 data = own_forest, FUN = length)
names(agg)[ncol(agg)] <- "n_plots"
agg <- agg[order(agg$ecoregion, agg$ft_group, agg$owner_label), ]
agg$flag <- ifelse(agg$n_plots < 30, "<30 (collapse)", "ok")

write.csv(agg, file.path(base, "maine_yield_curve_strata.csv"),
          row.names = FALSE)

cat("\n=== Maine yield-curve stratification (108 cells expected) ===\n")
cat(sprintf("Cells written: %d (sparse cells where n=0 dropped)\n", nrow(agg)))
cat("\nPopulated cells with n >= 30:\n")
ok <- agg[agg$n_plots >= 30, ]
cat(sprintf("  %d cells; total plots = %d\n",
            nrow(ok), sum(ok$n_plots)))

cat("\nTop 20 cells by sample size:\n")
print(head(agg[order(-agg$n_plots), ], 20), row.names = FALSE)

cat("\nCells flagged for collapse:\n")
print(head(agg[agg$flag == "<30 (collapse)", ], 20), row.names = FALSE)
