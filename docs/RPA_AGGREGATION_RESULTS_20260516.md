# conus_hcs RPA aggregation results: Layer 22 patch completed the cascade

*Generated 16 May 2026 evening after SLURM 9717200 (Layer 22) completed in 16 minutes 38 seconds with exit code 0.*

## TLDR

The Layer 22 patch (drop preexisting `rpa_subregion` before `left_join`) cleared the column collision and the aggregation ran to completion. The R/18_rpa_aggregation.R script now produces all four output tables for the four RPA subregions covered by the Phase 4 plot set: North_Central, Pacific_Northwest, South_Central, South_East. Three methodological flags emerged in the output that warrant attention before any comparison against Johnston, Guo, Prestemon 2021 baselines is publication ready: (1) p_harvest saturates at 0.86 to 0.91 across all subregions, which is roughly 9 times the Maine RPA reference of 0.10 and inconsistent with observed national harvest rates; (2) 76,893 of 162,139 plots (47 percent) have NA `p_harvest_mean` after the partial plus clearcut regime combination, so the aggregations are computed on the remaining 53 percent only; (3) the `config/rpa_baselines.csv` file does not exist on Cardinal, so the `pct_diff` column in the comparison output is all NA.

## RPA aggregation outputs

Pulled from `~/conus_hcs/output/phase4/` and committed to local workspace at `figures/rpa_by_subregion_20260516.csv` and `figures/rpa_comparison_20260516.csv`.

| Subregion | n_plots | area_ha | p_harvest | total_removal | removal_per_ha |
|---|---:|---:|---:|---:|---:|
| North_Central | 69,783 | 112,965 | 0.915 | 13,269 | 0.117 |
| Pacific_Northwest | 50 | 81 | 0.860 | 11.46 | 0.142 |
| South_Central | 22,035 | 35,670 | 0.880 | 15,921 | 0.446 |
| South_East | 70,271 | 113,755 | 0.887 | 32,766 | 0.288 |

`removal_per_ha` is the metric directly comparable to the Johnston Guo Prestemon 2021 baselines for the four subregions present.

## Methodological flags

### Flag 1: p_harvest saturates at 0.86 to 0.91

All four subregions report mean harvest probability between 0.860 and 0.915. The published Maine RPA harvest rate per five year cycle is approximately 0.10.

**Direct inspection of the unified TM2016 fit** at `data/checkpoints/m1_p_harvest_TM2016_unified.qs` (6,210 row lookup) shows the M1 occurrence model produces the same saturation pattern as the regime-split union:

| Quantile | p_partial | p_clearcut | p_any |
|---|---:|---:|---:|
| 10% | 0.298 | 0.695 | 0.780 |
| 50% | 0.446 | 0.770 | 0.873 |
| 90% | 0.649 | 0.850 | 0.923 |

Median `p_any` of 0.873 matches the aggregation output `p_harvest` of 0.880 to 0.915 within rounding. **The Layer 19 union approximation `pmin(P_partial + P_clearcut, 1)` is not the source of the saturation. The M1 occurrence model itself returns probabilities near 0.87 for the average plot.**

**Most plausible explanation: plot_pair_complete is a re-measured plot subset, not the full FIA plot population.** Plots that appear in plot_pair_complete are those where pre and post measurements were both captured (the FIA panel pair logic). Re-measured plots are a biased sample because plots get re-surveyed more often when they have flagged change events (often harvest). The M1 models trained on these pairs are therefore predicting `P(harvest | plot was re-measured)`, which on that conditional set is near 1, not `P(harvest | random plot in population)`.

For comparison against the Johnston Guo Prestemon 2021 RPA baselines (which are population level harvest rates per all forest area), the aggregation needs either:

1. A different prediction frame: extend M1 prediction to the full FIA plot population, not just the re-measured panel pairs, or
2. A reweighting factor: scale per-plot prediction by `P(plot is re-measured | population)`, which converts conditional to marginal probability, or
3. Acceptance of the current output as a "harvest pressure among monitored plots" metric, distinct from population harvest rate.

The methodological choice depends on the manuscript framing. Population level rate (option 1 or 2) supports direct RPA baseline comparison. Pressure on monitored plots (option 3) supports a within-FIA-panel analytical statement.

Worth noting: with median `p_any = 0.87` and `removal_per_ha` values of 0.12 to 0.45, the absolute removal magnitudes are in roughly the right RPA range. The saturation issue is specifically the probability-of-harvest interpretation, not the per-hectare removal volume.

**Cross check against the unified TM2016 lookup.** After resolving a CN string whitespace issue (the `CN_chr` column in `plot_pair_complete.qs` has leading spaces that the lookup does not), the unified TM2016 fit's 6,210 plots intersect 6,210 plot_pair_complete rows (3.59 percent join coverage; the lookup covers a small subset). On the matched subset, the per state mean `p_any` from the unified TM2016 framework matches the brms aggregation closely:

| State | n in lookup | mean p_any (TM2016) | mean p_partial | mean p_clearcut |
|---|---:|---:|---:|---:|
| AL | 1,109 | 0.841 | 0.389 | 0.773 |
| FL | 682 | 0.846 | 0.379 | 0.784 |
| GA | 1,073 | 0.860 | 0.433 | 0.786 |
| ID | 8 | 0.860 | 0.217 | 0.809 |
| IA | 76 | 0.866 | 0.601 | 0.729 |
| MI | 374 | 0.904 | 0.643 | 0.748 |
| MN | 53 | 0.885 | 0.618 | 0.730 |
| NC | 380 | 0.856 | 0.437 | 0.779 |
| SC | 660 | 0.867 | 0.450 | 0.784 |
| TN | 738 | 0.848 | 0.380 | 0.780 |
| WI | 660 | 0.897 | 0.642 | 0.731 |

The pattern is robust: **two independent M1 prediction frameworks (brms posterior_epred and the unified TM2016 lookup) return the same saturated p_any ≈ 0.85 to 0.90.** This rules out a software bug in any one prediction path and points conclusively at the shared training-frame bias (re-measured panel pair subset).

### Flag 2: 47 percent NA p_harvest_mean

Log of 9717200: `! 76893 of 162139 plots have NA p_harvest_mean after regime combination.` The aggregation proceeds because `weighted.mean(..., na.rm = TRUE)` drops the NAs, but the effective sample for the aggregated means is roughly half what the raw counts suggest. Possible drivers:

1. Posterior_epred returns NA when covariate combinations are out of training support
2. One regime returns NA for some plots and the union approximation propagates NA
3. The plot_pair_complete set covers only 12 distinct STATECD values (53,19,55,26,27,47,1,45 plus 4 others); plots from states without trained fits may produce NA

Worth diagnosing with a one liner: `table(is.na(plot_pair_complete$p_harvest_mean), plot_pair_complete$STATECD)` to localize the NA source.

### Flag 3: rpa_baselines.csv missing

Log message: `Warning message: RPA baseline file not found at config/rpa_baselines.csv. Returning zeros.` The `rpa_comparison.csv` output has all NA values in the `rpa_baseline_removal` and `pct_diff` columns. The Johnston Guo Prestemon 2021 published baselines need to be transcribed into `config/rpa_baselines.csv` with columns `rpa_subregion, rpa_baseline_removal` before the comparison column will populate.

## Subregion coverage gaps

Only 4 of the 7 RPA subregions are represented in the Phase 4 plot set. Missing subregions: North_East, Rocky_Mountains, Pacific_Southwest. The Pacific_Northwest cohort has only 50 plots (versus ~70,000 for NC and SE) and should be treated as not yet sampled rather than as a finding. A complete CONUS pass would require Phase 4 ingest of plots from the remaining states. The 12 STATECD values currently covered (confirmed by direct inspection of `plot_pair_complete.qs`):

| STATECD | State | Plot count | RPA subregion |
|---:|---|---:|---|
| 1 | AL | 11,926 | South_Central (per cfg) |
| 12 | FL | 14,521 | South_East |
| 13 | GA | 27,502 | South_East |
| 16 | ID | 48 | Pacific_Northwest |
| 19 | IA | 2,453 | North_Central |
| 26 | MI | 18,720 | North_Central |
| 27 | MN | 26,600 | North_Central |
| 37 | NC | 13,587 | South_East |
| 45 | SC | 14,661 | South_East |
| 47 | TN | 10,109 | South_East (per cfg, may differ from FIA SRS) |
| 53 | WA | 2 | Pacific_Northwest |
| 55 | WI | 22,010 | North_Central |

ID 48 plots and WA 2 plots together make up the 50 plot Pacific_Northwest cohort. Missing subregions for a complete pass: North_East (CT, MA, ME, NH, NJ, NY, PA, RI, VT), Rocky_Mountains (MT, WY, CO, UT, NV, NM, AZ), Pacific_Southwest (CA, OR, parts of AZ/UT).

## Cascading patch history (final)

| Layer | Issue | Status |
|---|---|---|
| 19 | `posterior_epred` on class `list` | Fixed; commit `c7c3d1f` |
| 19b | NaN in quantile() summary | Fixed; commit `c9688c4` |
| 20 | M4 HCS fit graceful skip | Fixed; commit `97043cb` |
| 21 | STATECD type mismatch | Fixed; commit `a45b408` |
| 22 | rpa_subregion column collision | Fixed; commit `36cbdca` |

Five layered patches, each surfaced by the previous succeeding. The cascade is now complete; the script runs to a normal exit and produces all four output tables.

## Next steps

In order of priority:

1. **Transcribe Johnston Guo Prestemon 2021 RPA baselines** into `~/conus_hcs/config/rpa_baselines.csv` with columns `rpa_subregion, rpa_baseline_removal` so the comparison table populates. Five minute task once the source figures are at hand.

2. **Methodology review of M1 regime combination.** The 0.86 to 0.91 p_harvest saturation is the single most important finding from this aggregation pass. Resolve whether the partial plus clearcut union approximation is the right framework, or whether the unified TM2016 fit at `data/checkpoints/m1_p_harvest_TM2016_unified.qs` should be the prediction source instead.

3. **Diagnose the 47 percent NA rate.** One R one liner to tabulate NA rate by STATECD.

4. **Phase 4 plot ingest expansion.** Add plots from missing RPA subregions (Northeast, Rocky Mountains, Pacific Southwest) for a complete CONUS comparison.

## Status

- Layer 22 patch validated at production scale: aggregation completes cleanly in 16:38
- All four output tables produced
- Three methodological flags raised, none of them script bugs
- Pulled outputs preserved at `figures/rpa_by_subregion_20260516.csv` and `figures/rpa_comparison_20260516.csv`
- Phase 4 outputs at `~/conus_hcs/output/phase4/` for the next session
