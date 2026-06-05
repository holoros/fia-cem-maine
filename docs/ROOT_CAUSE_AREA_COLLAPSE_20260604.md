# Root cause: CEM forward trajectories crash from condition/area loss, not forest decline

**Date:** 2026-06-04
**Author:** A. Weiskittel (Cowork autopilot)
**Trigger:** PERSEUS explorer Maine CEM managed-harvest AGC crashes (280 -> ~50 Tg), the lone outlier among engines (CBM rises, YC/FVS peak then decline gently).

## The finding (confirmed)

The crash is an artifact of **declining condition count / EXPNS-weighted area**, not declining carbon density. Decomposing the Maine state AGC into area x density (run `state_rcp45_hadgem2_wear_econ_r19`):

| scenario | cyc | n_conditions | area | AGC | AGC/area |
|---|---|---|---|---|---|
| BAU | 1 | 2,843 | 5,526 | 237 | 0.043 |
| BAU | 5 | 1,694 | 3,418 | 169 | 0.049 |
| BAU | 9 | 1,155 | 2,380 | 107 | 0.045 |
| BAU | 15 | **658** | 1,356 | 46 | 0.034 |
| No_harvest | 1 | 2,892 | 5,619 | 247 | 0.044 |
| No_harvest | 15 | 1,108 | 2,270 | 97 | 0.043 |

Carbon density (AGC/area) is **stable** (~0.043 throughout, both scenarios). The total area and condition count collapse ~75% (BAU) / ~60% (No_harvest). AGC = area x density, so AGC crashes because area crashes. The forest is not declining; the projection is losing plots. This is why CEM is the outlier: the other engines do not drop conditions.

## Mechanism (partly confirmed, partly open)

Instrumented 1 to 2 sim ME debug runs (logging conditions in vs out of `project_one_cycle`):

- **Clean BAU, no bootstrap:** 10,017 -> 9,237 at cycle 1 (-8%), then stable cycles 2 to 4. A one-time loss in the projection assembly (matched + unmatched in = 10,017; projected out = 9,237).
- **With `--bootstrap_plots --bootstrap_frac 0.9`:** 9,015 -> 7,320 at cycle 1 (-19%), then stable cycles 2 to 5. The bootstrap resamples **with replacement**, creating duplicate conditions that collapse back toward unique inside the projection, an extra ~11% loss on top of the base.

So two confirmed contributors: (1) a one-time cycle-1 drop in the projection assembly, and (2) bootstrap-with-replacement duplicate collapse. **But these are one-time in the short debug, while the production run declines continuously (2,843 -> 658, ~0.9/cycle compounding).** The continuous compounding is not reproduced by the short BAU debug, so it involves a flag or scenario interaction not in the debug config (the production runs add `--use_owner_stratification --use_county_harvest --use_v4_prod_mult --use_owner_balanced` and the full harvest scenario_set). That last piece is the open item.

## Why the hindcasts still passed

The hindcasts (2004 to 2024, cycles 1 to 5) validated well (ME RMSE 16, GA +0.3%, WA -22.9%) because the area collapse compounds: early cycles are only mildly affected, and the hindcast subject-matching compares like with like. The damage is in the **forward** trajectory (2024 to 2074), which every CEM production run gets wrong because of this artifact.

## Impact

Every CEM production run uses `--bootstrap_plots`, so all forward trajectories (ME, WA prodW, GA plantTerm) carry the area-collapse artifact. The hindcast-era bias numbers are roughly sound; the forward trajectory shape is not. **This gates PERSEUS publication of the CEM forward series and supersedes the earlier slow-regrowth / SDImax hypothesis** (those affect density, which is stable; the bug is area).

## Fix path

1. **Reproduce the continuous decline** with the full production flag set under instrumentation (one ~30 min ME job with all flags + 15 cycles) to pin the per-cycle loss to a specific join/step (prime suspects: the `--use_v4_prod_mult` cell_key join via `yc_plot_membership`, owner stratification, or the harvest condition handling).
2. **Fix condition retention.** The projection must carry every condition forward each cycle. For the bootstrap, either resample without replacement (0.9n unique, slight CI narrowing) or attach a unique replicate id so duplicates do not collapse in joins/group_bys.
3. **Re-run** the focal-state production trajectories after the fix; only then ingest forward series into PERSEUS.

## Status of the two ME diagnostics (SDImax-off, prodW)

Still running, but they target carbon density, which is not the problem. Their value now is the prodW run also refreshes the (stale) PERSEUS Maine data; the SDImax comparison is secondary. The real fix is condition retention, not the density-throttling stack.
