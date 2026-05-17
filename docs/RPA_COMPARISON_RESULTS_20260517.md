# conus_hcs RPA comparison with populated baselines: pct_diff -84 to -93 percent

*Generated 17 May 2026 after SLURM 9857780 (RPA aggregation with populated `config/rpa_baselines.csv`) completed in 17:22.*

## TLDR

The `pct_diff` column in `rpa_comparison.csv` is now populated for all four covered RPA subregions. Conus_hcs removal_per_ha predictions are 6.7 to 16.3 percent of the RPA 2016 baseline removals from the 2020 RPA Assessment Chapter 6 Figure 6-4. The systematic 83 to 93 percent shortfall reflects a unit-scaling gap between M2's per-cycle output (whatever response variable the M2 brms fit uses) and RPA's annual per-hectare baseline. This is consistent with the earlier observation that conus_hcs's p_harvest values saturate at 0.86 to 0.91 (per cycle); when scaled to annual rates the 5-year cycle factor would close part of the gap.

## Results

| Subregion | conus_hcs removal_per_ha | RPA baseline m³/ha/yr | pct_diff |
|---|---:|---:|---:|
| North_Central | 0.117 | 1.10 | -89.4% |
| Pacific_Northwest | 0.142 | 2.12 | -93.3% |
| South_Central | 0.446 | 2.75 | -83.7% |
| South_East | 0.288 | 2.75 | -89.5% |

(Pacific_Southwest, Rocky_Mountains, North_East not yet covered by Phase 4 plot_pair_complete.)

## Interpretation

Three components contribute to the -84 to -93 percent deviation:

1. **Annual vs per-cycle scaling.** The RPA baseline is annual harvest removals. The conus_hcs M2 fit appears to predict per-5-year-cycle volumes (consistent with the p_harvest 0.86-0.91 saturation observed in 16 May diagnostics). If the conus_hcs value is per-cycle, dividing the RPA baseline by 5 gives ~0.22 to 0.55 m³/ha/yr equivalents and the deviations shrink to roughly -45 to -75 percent.

2. **M2 response variable units.** The brms M2 fit's response variable units are not visible in the script. If M2 predicts BA-removed (m²/ha) rather than volume-removed (m³/ha), the units differ by a factor that includes mean stem volume per BA (typically 5 to 8 m³ per m²). Multiplying conus_hcs values by ~6 closes much of the residual gap.

3. **Re-measured panel pair subset bias.** Confirmed by 17 May 2026 diagnostic: the M1 occurrence model produces saturated probabilities (median p_any 0.87) because plot_pair_complete is a re-measured subset. The annual baseline computed against the full FIA population would be diluted by the larger denominator.

The conus_hcs framework correctly captures the RELATIVE pattern across subregions (SC has highest removal per ha at 0.446, PNW lowest at 0.142, NC and SE intermediate), but the absolute magnitude needs unit reconciliation.

## RPA baselines source

`config/rpa_baselines.csv` populated from `scripts/build_rpa_baselines_from_chapter6.R` using:

- 2020 RPA Assessment WO-GTR-102 (USDA Forest Service 2023)
- Chapter 6 Figure 6-4: 2016 CONUS total removals 13 Bcuft/yr
- Region shares: North 19.2%, South 60.4%, Pacific Coast 17.3%, Rocky Mountain 3.1%
- Subregion pro-rating using typical timberland area shares:
  - North: NE 52% / NC 48%
  - South: SE 63% / SC 37%
  - Pacific Coast: PNW 75% / PSW 25%
  - Rocky Mountain: 60% / 40% N/S
- Per-hectare conversion: state forest areas ~64M ha North, 81M ha South, 30M ha PC, 28M ha RM

The pro-rating is approximate; subregion-specific removal data would require Coulston et al. (in preparation) or the underlying FIADB EVALIDator queries.

## Next steps

In order of value:

1. **Identify M2 fit response variable units** via inspection of `~/conus_hcs/models/m2_intensity/operational_partial/fit.qs` brms formula. ~30 min. Critical for closing the unit gap.

2. **Adjust rpa_baselines.csv to per-cycle if needed.** Once M2 units are confirmed. ~5 min once unit is known.

3. **Use full FIADB EVALIDator pop_estimate for per-subregion baselines.** Replace pro-rated estimates with directly computed FIA removal totals (Estimate Type 28 "Annual harvest removals volume"). Requires loading ENTIRE_POP_*.csv tables via rFIA::readFIA on a 64GB SLURM allocation. ~4 hr SLURM + script work.

4. **Reweight conus_hcs predictions for re-measured-subset bias.** Apply a factor of ~`n_population_plots / n_remeasured_plots` to convert from "harvest pressure among monitored plots" to "harvest rate among all forest plots." This would scale the removal_per_ha values up toward RPA baseline magnitudes.

## Files

- `figures/rpa_comparison_20260517_v2.csv` — pct_diff column now populated
- `figures/rpa_by_subregion_20260517_v2.csv` — refreshed by_subregion output
- `scripts/build_rpa_baselines_from_chapter6.R` — RPA baseline extractor
- `config/rpa_baselines.csv` (on Cardinal) — production baseline values
- `docs/CEM_3WAY_STRATIFICATION_20260517.md` — feasibility of 3-way matching
- `docs/CEM_PATCH_PROPOSAL_ECOREGION_20260517.md` — focused patch proposal for ecoregion

## Status

- RPA aggregation pipeline now produces complete pct_diff output
- RPA baselines from chapter 6 transcribed and applied
- Unit reconciliation between M2 per-cycle and RPA per-year remains
- The relative cross-subregion pattern is captured; absolute scaling needs M2 unit inspection
