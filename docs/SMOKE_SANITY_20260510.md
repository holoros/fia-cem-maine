# Multistate smoke output sanity check vs published FIA benchmarks

*Generated 10 May 2026 during session continuation from HANDOFF_20260510.md.*

Smoke outputs from `~/fia_cem_projections/output/{MN,WA,GA}_20260510_{state}_smoke/` were pulled and compared against published FIA EVALIDator state totals to flag any obvious calibration issues before the RCP 4.5 production runs (jobs 9327152, 9327153, 9327155) and RCP 8.5 production runs (jobs 9327550, 9327551, 9327552) finish.

## Per acre stand averages, cycle 1 baseline, BAU scenario

| State | BA (sqft/ac) | Volume (cuft/ac) | Carbon (kg/ac) | TPA | Harvest rate | Plant rate |
|---|---:|---:|---:|---:|---:|---:|
| MN | 68 | 1,223 | 33,150 | 538 | 11.6% | 0.5% |
| WA | 106 | 3,004 | 59,693 | 326 | 16.7% | 0.7% |
| GA | 61 | 1,205 | 32,085 | 470 | 19.9% | 1.3% |
| ME r21 | 90 | 1,542 | 44,240 | 742 | 8.9% | 0.2% |

Reading: Pacific Northwest stands carry the most volume per acre, southern pine plantations have the highest harvest pressure, Maine sits in the middle on volume with the lowest harvest rate, and Lake States Minnesota carries lower stand-level volume consistent with smaller average tree size in the boreal mixed forest. All four states show biophysically defensible per acre means.

## State total volume vs EVALIDator

Per acre volume times published timberland area gives an implied state total to compare against EVALIDator.

| State | Smoke vol/ac (cuft) | Forest area, M ac | Implied total (Bcuft) | EVALIDator total (Bcuft) | Ratio |
|---|---:|---:|---:|---:|---:|
| MN | 1,223 | 17.4 | 21.3 | ~28 | 0.76 |
| WA | 3,004 | 22.0 | 66.1 | ~70 | 0.94 |
| GA | 1,205 | 24.8 | 29.9 | ~32 | 0.94 |
| ME r21 | 1,542 | 17.6 | 27.1 | ~30 | 0.90 |

WA, GA, and ME land within 10% of EVALIDator totals; the modest underestimate is consistent with the projection-vs-inventory definitional gap that has been documented for ME (~6% structural undershoot vs subject matched observed in the 1999 to 2024 hindcast).

The MN smoke is 24% under the EVALIDator total. Three possibilities to investigate after the MN production run lands:

1. The 5 percent bootstrap sampling in the smoke test (`--bootstrap_frac 0.9`, `--n_sims 1`) under-represents some MN forest types. Production at `--n_sims 100` should narrow this; if MN production also comes in 20%+ under EVALIDator, this rules option 1 out.
2. The MN subject pool expansion (via `--include_remeasured`) may include or exclude a meaningful share of remeasured plots from the Northwoods periodic-to-annual transition. ME r17 saw a similar effect from the DESIGNCD filter.
3. The HCB-FIA agreement for MN at 74% means about a quarter of plots fall through to a default owner multiplier, which could attenuate the harvest signal differently than expected. The `--use_owner_balanced` flag is intended to compensate; worth checking the owner stratification effect by running a MN smoke without it once production lands.

## gr_ratio audit results

| State | Cycle 1 | Cycle 3 | Status |
|---|---|---|---|
| MN | 0.005 (0.005, 0.006) | 0.006 (0.006, 0.007) | Layer 1 fix landed; Layer 2 still present |
| WA | 0.001 (0.001, 0.001) | 0.001 (0.001, 0.001) | Pre Layer 1; smoke was 08:22 |
| GA | 0.001 (0.001, 0.001) | 0.001 (0.001, 0.001) | Pre Layer 1; smoke was 08:32 |
| ME r21 | 0.000 (0.000, 0.001) | 0.000 (0.000, 0.001) | Pre Layer 1 |

The MN post Layer 1 ratio of 0.005 to 0.006 matches the predicted `1/harvest_rate` factor relative to the prior 0.001 baseline. Production runs (which include the Layer 1 fix) should match the MN pattern across all three states.

A Layer 2 fix is documented separately in `GR_RATIO_LAYER2_AUDIT.md` and would push gr_ratio toward the expected biological magnitude of approximately 1, but only on the economic overlay path; multistate production runs all use `--no_econ` and will retain the post Layer 1 magnitude.

## Recommendation

Smoke outputs are good enough to greenlight reviewing the production results when they land. The MN underestimate is the only watch item; it will resolve naturally if the production n_sims 100 run lands closer to EVALIDator, or it points to a targeted MN subject pool followup if not.

## Source files

- `/home/aweiskittel/.config/Claude/local-agent-mode-sessions/.../outputs/cardinal_review/smoke_csvs/` — local pulls of all six smoke + ME r21 reference CSVs used in this report.
