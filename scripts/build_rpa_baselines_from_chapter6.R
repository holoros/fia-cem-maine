#!/usr/bin/env Rscript
# build_rpa_baselines_from_chapter6.R
# Populate ~/conus_hcs/config/rpa_baselines.csv using region-level removal
# baselines transcribed from Chapter 6 of the 2020 RPA Assessment
# (WO-GTR-102, July 2023), Figures 6-4 and 6-25 plus chapter text.
#
# Region-level 2016 baseline removals (per chapter text near Figure 6-4):
#   Total CONUS 2016: 13 Bcuft/yr (down from 1996 peak 15.9, was 14.1 in 1976)
#   Pacific Coast share: 17.3%
#   North share: 19.2%
#   Rocky Mountain share: 3.1%
#   South share: 100 - 17.3 - 19.2 - 3.1 = 60.4%
#
# Region totals (Bcuft/yr in 2016):
#   North:           2.496
#   South:           7.852
#   Pacific Coast:   2.249
#   Rocky Mountain:  0.403
#
# Subregion pro-rating uses approximate forest-area shares within each
# region from the Coulston Chapter 6 text on timberland volumes by RPA
# region, plus state shares (NE: ME+NH+VT+MA+CT+RI+NY+PA+NJ; NC: WI+MI+IA+IL+IN+OH+MO+MN+ND+SD).
#
# Output: ~/conus_hcs/config/rpa_baselines.csv

suppressPackageStartupMessages({
  library(data.table)
})

# 2016 CONUS total
TOTAL_2016 <- 13.0  # billion cubic feet per year

# Per-region 2016 removal shares (from Chapter 6 text)
region_share <- list(
  "North"          = 0.192,
  "South"          = 0.604,
  "Pacific Coast"  = 0.173,
  "Rocky Mountain" = 0.031
)
region_bcuft <- lapply(region_share, function(s) s * TOTAL_2016)

# Subregion pro-rating within region based on typical timberland area shares
# (from Coulston Ch6 text and prior FIA region inventory reports):
#   North: NE ~52%, NC ~48% (NE has more total timberland from NY+PA)
#   South: SE ~63%, SC ~37% (SE: GA+FL+AL+SC+NC+VA+TN+KY; SC: TX+OK+AR+LA+MS)
#   Pacific Coast: PNW ~75%, PSW ~25% (PNW: WA+OR+ID+MT cooperatively
#     considered; PSW: CA+NV+UT+AZ; though FIA classifies ID/MT in RM)
#   Rocky Mountain: RM_North 60%, RM_South 40% (approximate)
subreg <- data.table::data.table(
  rpa_subregion         = c("North_East", "North_Central",
                              "South_East", "South_Central",
                              "Pacific_Northwest", "Pacific_Southwest",
                              "Rocky_Mountains_North", "Rocky_Mountains_South"),
  rpa_region            = c("North", "North",
                              "South", "South",
                              "Pacific Coast", "Pacific Coast",
                              "Rocky Mountain", "Rocky Mountain"),
  within_region_share   = c(0.52, 0.48,
                              0.63, 0.37,
                              0.75, 0.25,
                              0.60, 0.40)
)
subreg[, rpa_baseline_removal_bcuft_yr :=
        within_region_share * unlist(region_bcuft[rpa_region])]

# Also provide per-hectare equivalent. CONUS forest area ~310 million ha
# (~755 million acres); per-region forest area approximate:
#   North 64 million ha, South 81 million ha, PC 30 million ha, RM 28 million ha
region_ha <- list(
  "North"          = 64e6,
  "South"          = 81e6,
  "Pacific Coast"  = 30e6,
  "Rocky Mountain" = 28e6
)
subreg[, region_ha := unlist(region_ha[rpa_region])]
subreg[, subreg_ha := within_region_share * region_ha]
# Convert Bcuft to m^3: 1 Bcuft = 0.02832 * 1e9 m^3 = 2.832e7 m^3
subreg[, rpa_baseline_removal_m3_per_ha :=
        rpa_baseline_removal_bcuft_yr * 2.832e7 / subreg_ha]

cat("RPA region 2016 removal baselines from Chapter 6:\n")
print(data.table::data.table(
  region = names(region_share),
  share  = unlist(region_share),
  bcuft  = unlist(region_bcuft)
))
cat("\nSubregion pro-rated baselines:\n")
print(subreg[, .(rpa_subregion, rpa_region, within_region_share,
                  bcuft_yr = round(rpa_baseline_removal_bcuft_yr, 3),
                  m3_per_ha = round(rpa_baseline_removal_m3_per_ha, 4))])

# Output in the format the conus_hcs RPA aggregation expects:
# columns: rpa_subregion, rpa_baseline_removal
# Use m3 per ha as the comparable unit
out <- subreg[, .(rpa_subregion,
                   rpa_baseline_removal = rpa_baseline_removal_m3_per_ha,
                   rpa_baseline_removal_bcuft_yr = rpa_baseline_removal_bcuft_yr,
                   source = "USDA 2023 RPA Assessment WO-GTR-102 Ch6 Figure 6-4 (2016 baseline) pro-rated within region by approximate timberland area share")]

OUT_PATH <- "/users/PUOM0008/crsfaaron/conus_hcs/config/rpa_baselines.csv"
fwrite(out, OUT_PATH)
cat(sprintf("\nWrote: %s\n", OUT_PATH))

# Also keep a local debug copy in the diagnostic output dir
DEBUG_OUT <- "/users/PUOM0008/crsfaaron/conus_hcs/output/rpa_baselines_debug_20260517.csv"
fwrite(subreg, DEBUG_OUT)
cat(sprintf("Wrote debug detail: %s\n", DEBUG_OUT))
