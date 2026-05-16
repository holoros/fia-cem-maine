# Critical unit bug in analysis tooling: proj_carbon is lb/ac not kg/ac

*Generated 15 May 2026. Documents a discovery that reframes the multistate hindcast finding.*

## The bug

While investigating the apparent +65 to +145 percent over prediction of the multistate p1 hindcasts, traced the discrepancy to a unit confusion in my own analysis tooling. The `proj_carbon` column in `per_plot_projections.rds`, and the `mean_carbon_mean` column in `table_inventory_summary.csv`, are in **pounds per acre** (lb/ac), not kilograms per acre (kg/ac).

The origin: `R/01_data_prep.R` builds the baseline carbon attribute as

```r
carbon_ag = sum(TPA_UNADJ * CARBON_AG, na.rm = TRUE)
```

where `CARBON_AG` is the FIA tree-level carbon stock column documented in the FIA database manual as "Aboveground carbon, dry weight, of this tree, in pounds." `TPA_UNADJ` is trees per acre. The product is pounds per acre.

`R/06_projection_engine.R` line 804 then projects forward as

```r
proj_carbon = carbon_ag * gr_carbon * .cm
```

which preserves the lb/ac unit.

## What was wrong in my analysis

**Hindcast script (`scripts/hindcast_multistate.R`):** Used `KGAC_TO_MMT_via_EXPNS = 1e-9` for the projected statewide aggregation, treating `proj_carbon` as kg/ac. The correct factor is `LB_TO_MMT = 4.53592e-10`. Ratio of the two is exactly 2.20, matching the lb to kg conversion. This produced spurious over predictions of:

- WA: +201 MMT residual (+65 percent of obs mean) at year 2019
- MN: +125 MMT bias (+108 percent) across cycles 1 through 5
- GA: +359 MMT bias (+145 percent) across cycles 1 through 5

**Validation template (`scripts/validate_template.R`):** Computed `total_carbon_tgc <- per_ac_carbon * forest_area_mac * 1e6 / 1e9`, again treating per acre carbon as kg. Same 2.2x inflation. This caused the validation memos to report inflated statewide totals (MN 586, WA 1377, GA 875 TgC) and to either pass against bounds that were similarly inflated (when those bounds came from analogous wrong calculations) or fail against correct EVALIDator references.

## Corrected magnitudes

Applying the lb to MMT conversion correctly:

| State | Validation memo (wrong) | Corrected | FIA full panel observed |
|---|---:|---:|---:|
| MN | 586 TgC | 266 TgC | ~220 TgC |
| WA | 1,377 TgC | 624 TgC | ~650 TgC |
| GA | 875 TgC | 397 TgC | ~410 TgC |
| ME r21 | 778 TgC | 353 TgC | TBD via diagnostic |

The corrected projected statewide totals now match FIA full panel within 4 to 21 percent across the three multistate p1 states, a much more publishable agreement. WA matches FIA to 4 percent. GA matches to 3 percent. MN is 21 percent over but in the same magnitude band.

## Reapplied hindcast results (in flight, ME r21 diagnostic landed)

SLURM job 9602288 reruns all six multistate p1 hindcasts plus the ME r21 diagnostic with the corrected lb to MMT conversion.

The ME r21 diagnostic actually completed under a separate cancelled job 9601589 before the scancel landed, using the **buggy** script. That result is informative as a confirmation pass: it shows proj_subj/obs_subj ratio of 2.20 at cycle 1 (2004), matching the lb to kg conversion factor exactly. Dividing the buggy proj_subj by 2.2 gives:

| Year | Obs subj (MMT) | Buggy proj | Corrected proj | Corrected residual | Pct |
|---:|---:|---:|---:|---:|---:|
| 2004 | 256.6 | 564.0 | 256.3 | -0.3 | -0.1% |
| 2009 | 167.2 | 250.9 | 114.0 | -53.2 | -32% |
| 2014 | 126.5 | 263.7 | 119.9 | -6.6 | -5% |
| 2019 | 109.9 | 252.3 | 114.7 | +4.8 | +4% |
| 2024 | 108.8 | 270.1 | 122.8 | +14.0 | +13% |

Corrected ME r21 RMSE estimate: ~25 MMT, bias ~-8 MMT. This is very close to the canonical ME r11 reference of RMSE 16 MMT and bias -2 MMT. The cycle 1 (2004) value matches to within 0.1 percent, which is the most informative diagnostic: the projection's BASELINE produces values that match FIA observed for the same plots almost exactly when the unit is correctly handled.

Once the v2 job finishes, the formal hindcast memos for all 7 (4 states × 2 RCPs + ME r21) will land with corrected values.

## Implications for prior reporting

Earlier session memos and the HANDOFF treated the validation memo `total_carbon_tgc` numbers as true projected statewide carbon. They were over reported by 2.2x. The flag of "WA total carbon overshoot vs EVALIDator" in the prior validation REVIEW was an artifact of the unit bug, not a real projection issue.

The hindcast finding that "multistate p1 over predicts FIA observed by 60 to 140 percent" should be retracted; this was the same unit bug in the hindcast tooling.

The Layer 2 patch validation (gr_ratio 0.012 to 0.429) is independent of this bug and remains valid.

## Lessons

1. Always check column units before computing comparisons. The `mean_carbon_mean` column has no unit attached; assumed kg from the typical metric convention but FIA standard for biomass is pounds.
2. Cross check derived statewide totals against an independent source (FIA full panel, EVALIDator). The 2.2x inflation would have been caught immediately if I had derived FIA full panel from my own observed side and compared.
3. The validation template's statewide bounds were calibrated against inflated computations and should be regenerated against FIA-derived truth, which I've done as part of the fix.

## Action items (autopilot)

1. Hindcast script patched: `LB_TO_MMT` everywhere instead of `1e-9`. Deployed to Cardinal.
2. Validation template patched: `total_carbon_tgc` formula corrected, STATE_PROFILES bounds rebased on FIA full panel observed.
3. Re-hindcast job 9602288 submitted; will land in roughly 50 minutes.
4. Existing memos (`VALIDATION_*.md`, `HINDCAST_*.md`) will be replaced when the rerun produces new ones. Until then, treat their statewide carbon numbers as 2.2x inflated.
5. The synthesis memo `VALIDATION_SYNTHESIS_20260513.md` retracts the over prediction finding; updated separately.
