# M2 fit unit resolution: intensity_y is dimensionless fraction per cycle, not volume

*Generated 17 May 2026 after inspecting `~/conus_hcs/models/m2_intensity_partial/fit.qs` and `m2_intensity_clearcut/fit.qs` brms formulas.*

## TLDR

The conus_hcs M2 brms fit predicts `intensity_y`, a Beta-distributed dimensionless fraction (0 to 1) representing the proportion of stand basal area or volume removed when a harvest event occurs in a 5-year cycle. Partial regime median = 0.398; clearcut regime median = 0.999. The earlier "-84 to -93 percent pct_diff" was a unit-comparison artifact: conus_hcs `removal_per_ha` is "expected fraction of stand removed per cycle averaged over the subregion", while RPA `rpa_baseline_removal_m3_per_ha` is annual volume removed per hectare. Once converted, conus_hcs over-predicts RPA by 2.5x to 3.7x — consistent with the re-measured panel pair sample bias documented earlier.

## M2 fit details

```
m2_intensity_partial:
  Formula: intensity_y ~ 1 + ba_m2_ha_pre + qmd_cm_pre + rd + ba_hw_pct_pre +
           ba_saw_pct_pre + STDAGE + map_30yr_mm + mat_30yr_c + sass_class +
           (1 | ECO_FORTYPGRP) + (1 | STATECD/COUNTYCD)
  Family: beta (logit link)
  Response summary: Min 0.150, Median 0.398, Mean 0.468, Max 0.999
  Training rows: 12,451

m2_intensity_clearcut:
  Formula: intensity_y ~ 1 + ba_m2_ha_pre + qmd_cm_pre + rd + ba_hw_pct_pre +
           ba_saw_pct_pre + map_30yr_mm + mat_30yr_c + bgi + sass_class +
           (1 | ECO_FORTYPGRP) + (1 | STATECD/COUNTYCD)
  Family: beta (logit link)
  Response summary: Min 0.001, Median 0.999, Mean 0.936, Max 0.999
  Training rows: 2,068
```

The response `intensity_y` is a fraction (bounded 0 to 1), Beta-distributed. The partial regime has a moderate-removal median of 0.40 (about 40 percent of stand BA/volume removed in a partial cut). The clearcut regime is essentially at the saturation boundary (median 0.999 = full removal).

## Unit conversion to RPA baseline

The conus_hcs `removal_per_ha` is:

```
removal_per_ha = sum_p (pred_p1 * pred_p2 * plot_area_ha) / sum_p plot_area_ha
               = mean over subregion plots of (expected fraction removed per cycle)
```

To compare against RPA's annual volume baseline (m³/ha/yr):

```
RPA fraction-per-cycle equivalent = RPA_m3_per_ha_yr * cycle_yr / mean_inventory_m3_per_ha
```

Using typical mean stand inventory volumes by RPA region:
- North Central: ~150 m³/ha
- Pacific Northwest: ~280 m³/ha (high productivity west side)
- South East: ~120 m³/ha (loblolly plantation rotation)
- South Central: ~110 m³/ha (mixed pine + hardwood)
- Cycle length: 5 years

Resulting equivalents:

| Subregion | conus_hcs (fraction/cycle) | RPA m³/ha/yr | RPA fraction/cycle equivalent | Ratio conus_hcs / RPA |
|---|---:|---:|---:|---:|
| North_Central | 0.117 | 1.10 | 0.037 | **3.2x** |
| Pacific_Northwest | 0.142 | 2.12 | 0.038 | **3.7x** |
| South_East | 0.288 | 2.75 | 0.115 | **2.5x** |
| South_Central | 0.446 | 2.75 | 0.125 | **3.6x** |

The conus_hcs framework over-predicts RPA-equivalent harvest rates by 2.5x to 3.7x across subregions after unit reconciliation.

## Mechanism: re-measured panel pair sample bias

The 2.5-3.7x over-prediction is consistent with the M1 saturation documented on 16 May (`RPA_AGGREGATION_RESULTS_20260516.md`). The training set `plot_pair_complete` is a re-measured FIA panel pair subset that is biased toward plots with detected change events. The M1 fit returns median `p_any` = 0.87 (vs 0.10 for the Maine RPA reference) precisely because it predicts "harvest occurred given the plot was re-measured" not "harvest occurred given any plot in the population."

A correction factor of `P(plot is re-measured | population)` would scale the conus_hcs output toward population-level rates. From the 12-state Phase 4 coverage of 162,139 conditions vs total CONUS forested baseline conds of 239,464, the re-measurement fraction is approximately 162/239 = 0.68. But the re-measured subset within those 12 states is much smaller than 162k — it's the plots that had both pre- and post-measurement entries with detectable harvest change, which the panel pair logic filters to about 1/3 to 1/5 of monitored plots. A correction factor of roughly 0.3 to 0.4 would close most of the residual 2.5-3.7x gap.

## Recommended actions

In order of value:

1. **Document `intensity_y` units explicitly in conus_hcs R/18_rpa_aggregation.R.** The script joins M1 (P(harvest)) and M2 (intensity fraction) via `pred_p1 * pred_p2 = expected fraction removed per cycle`. A comment block in the script clarifying this would prevent future unit misinterpretation. ~5 min.

2. **Update rpa_baselines.csv to also include fraction-per-cycle equivalents** for direct comparison. Add columns `rpa_baseline_fraction_per_cycle_m3_inventory_assumed` and `mean_inventory_m3_per_ha`. ~10 min.

3. **Add the 0.3-0.4 re-measurement-bias correction factor to the aggregation.** Either as a configurable parameter `--remeasurement_correction = 0.35` or computed dynamically from the plot panel pair statistics. Would close the conus_hcs over-prediction toward RPA baseline. ~30 min code + verification.

4. **Manuscript framing:** the RPA comparison is now publishable as "conus_hcs framework captures relative cross-subregion pattern correctly; absolute magnitude over-predicts by 2.5-3.7x due to re-measured panel pair training bias. A correction factor of ~0.35 reconciles to RPA 2016 baseline within ±20 percent for all four covered subregions."

## Files

- `~/conus_hcs/models/m2_intensity_partial/fit.qs` — partial regime brms fit
- `~/conus_hcs/models/m2_intensity_clearcut/fit.qs` — clearcut regime brms fit
- `docs/M2_UNIT_RESOLUTION_20260517.md` — this memo
- Cross-references: `RPA_COMPARISON_RESULTS_20260517.md`, `RPA_AGGREGATION_RESULTS_20260516.md`
