## yc_01_collapse_strata.R  (Yield-Curve Phase 2, step 1)
##
## Take the 108-cell stratification from maine_yield_curve_strata.csv and
## collapse Tribal + Federal + Local → Public-Other so we get to 4 owner
## classes (NIPF, Industrial, State, Public-Other) × 6 forest types ×
## 3 ecoregions = 72 cells. Then enumerate each FIA plot → cell.
##
## Inputs : config/maine_yield_curve_strata.csv  (108-cell counts)
##          config/fia_plots_with_owner.csv      (per-plot owner)
## Outputs: config/yc_strata_72cell.csv          (72-cell counts)
##          config/yc_plot_membership.csv        (per-plot cell key)

suppressPackageStartupMessages({})

base <- if (Sys.getenv("CONFIG_DIR") != "") Sys.getenv("CONFIG_DIR") else
        file.path(Sys.getenv("HOME"), "fia_cem_projections", "config")
cat(sprintf("Using config_dir = %s\n", base))

# 108-cell counts already populated
strata108 <- read.csv(file.path(base, "maine_yield_curve_strata.csv"),
                      stringsAsFactors = FALSE)
cat(sprintf("Loaded %d 108-cell rows\n", nrow(strata108)))

# Plot-level owner data
own <- read.csv(file.path(base, "fia_plots_with_owner.csv"),
                stringsAsFactors = FALSE)
own <- own[own$hcb_class %in% 3:8, ]
cat(sprintf("Forest plots in own table: %d\n", nrow(own)))

# Forest-type group function (same logic as build_yield_curve_strata.R)
ft_group <- function(fortypcd) {
  ifelse(is.na(fortypcd), "Other",
  ifelse(fortypcd >= 121 & fortypcd <= 128, "Spruce-fir",
  ifelse(fortypcd >= 800 & fortypcd <= 809, "Northern hardwood",
  ifelse(fortypcd >= 900 & fortypcd <= 919, "Aspen-birch",
  ifelse(fortypcd >= 700 & fortypcd <= 799, "Mixedwood",
  ifelse(fortypcd >= 100 & fortypcd <= 119, "White/Red pine",
  ifelse(fortypcd >= 400 & fortypcd <= 599, "Oak/Pine/Hemlock",
  "Other"))))))) }

# Ecoregion (3-zone)
me_ecoregion <- function(countycd) {
  ifelse(countycd %in% c(3L, 21L), "ME_NH",
  ifelse(countycd %in% c(7L, 17L, 25L), "ME_NCZ",
  "ME_APH")) }

# Owner collapse: Tribal + Federal + Local → Public-Other; keep
# NIPF, Industrial, State as standalones.
collapse_owner <- function(hcb_class) {
  ifelse(hcb_class == 3, "NIPF",
  ifelse(hcb_class == 4, "Industrial",
  ifelse(hcb_class == 7, "State",
  "Public-Other"))) }   # 5, 6, 8 → Public-Other

own$ft_group   <- ft_group(own$FORTYPCD)
own$ecoregion  <- me_ecoregion(own$COUNTYCD)
own$owner4     <- collapse_owner(own$hcb_class)

own$cell_key   <- paste(own$ft_group, own$ecoregion, own$owner4, sep = "|")

# ---- 72-cell strata table -------------------------------------------
agg <- aggregate(PLT_CN ~ ft_group + ecoregion + owner4, data = own, FUN = length)
names(agg)[ncol(agg)] <- "n_plots"
agg$cell_key <- paste(agg$ft_group, agg$ecoregion, agg$owner4, sep = "|")
agg$flag     <- ifelse(agg$n_plots < 30, "<30 (collapse)", "ok")
agg <- agg[order(-agg$n_plots), ]
write.csv(agg, file.path(base, "yc_strata_72cell.csv"), row.names = FALSE)

cat(sprintf("\n=== 72-cell strata: %d populated cells, %d with n>=30 ===\n",
            nrow(agg), sum(agg$n_plots >= 30)))
cat("\nTop 25 cells by sample size:\n")
print(head(agg, 25), row.names = FALSE)

cat(sprintf("\nTotal forest plots in 72-cell space: %d\n",
            sum(agg$n_plots)))
cat(sprintf("Plots in well-sampled cells (n>=30): %d (%.1f%%)\n",
            sum(agg$n_plots[agg$n_plots >= 30]),
            100 * sum(agg$n_plots[agg$n_plots >= 30]) / sum(agg$n_plots)))

# ---- Plot membership lookup ------------------------------------------
membership <- own[, c("STATECD", "UNITCD", "COUNTYCD", "PLOT", "PLT_CN",
                      "INVYR", "FORTYPCD", "OWNCD", "OWNGRPCD",
                      "hcb_class", "ft_group", "ecoregion", "owner4",
                      "cell_key")]
write.csv(membership, file.path(base, "yc_plot_membership.csv"),
          row.names = FALSE)
cat(sprintf("\nWrote yc_plot_membership.csv (%d rows)\n", nrow(membership)))
