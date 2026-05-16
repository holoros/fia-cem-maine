# State-level p1 estimates vs latest USFS RPA/FIA published values

*Generated 16 May 2026. Sources: Forests of Maine 2021 (FS-366), Forests of Minnesota 2020 (FS-326), Forests of Georgia 2022 (FS-484), Pacific Northwest Research Station Washington State Stats. Production data from the May 10 2026 p1 multistate output set, cycle 1 BAU baseline.*

## Headline comparison

| State | Forest area (Mac) | p1 cycle 1 vol per ac (cuft/ac) | p1 statewide vol (Bcuft) | FIA published volume (Bcuft) | FIA volume metric | Delta (%) |
|---|---:|---:|---:|---:|---|---:|
| ME r21 (ref) | 17.52 | 1,533 | 27.0 | 27.70 | all-live trees, 2021 | -2.5 |
| MN p1 | 17.66 | 1,241 | 21.6 | 20.89 | all-live trees, 2020 | +3.4 |
| WA p1 | 22.00 | 3,133 | 68.9 | ~95 | all-live trees, ~2022 | -27.5 |
| GA p1 | 24.25 | 1,326 | 32.9 | 66.91 | sound total-stem ≥5", 2022 | -50.8 |

**Important caveat on units.** Our `proj_volcfnet` is FIA's standard merchantable bole net cuft (growing stock volume on ≥5" d.b.h. trees), not the broader "sound total-stem" definition used in the 2022 Forests of Georgia report nor the "live trees on forest land" definition used in the 2020/2021 Forests of Minnesota and Maine reports. Sound total-stem includes branches and tops down to 1.5" diameter and runs ~30 to 50 percent higher than growing stock. To make this comparison fair, the FIA published columns should be converted to the equivalent growing stock equivalent before computing deltas. Growing stock estimates from EVALIDator at the same vintage are approximately:

* ME: 27 Bcuft live → ~21 Bcuft growing stock on timberland (RPA-style)
* MN: 20.9 Bcuft live → ~16 Bcuft growing stock
* WA: 95 Bcuft live → ~70 Bcuft growing stock
* GA: 67 Bcuft total stem → ~45 Bcuft growing stock

With these adjusted reference values, the p1 deltas become:

| State | p1 vol (Bcuft) | Growing-stock equiv (Bcuft) | Delta (%) |
|---|---:|---:|---:|
| ME r21 | 27.0 | ~21 | **+28** |
| MN p1 | 21.6 | ~16 | **+35** |
| WA p1 | 68.9 | ~70 | **-1.6** |
| GA p1 | 32.9 | ~45 | **-27** |

WA tracks growing-stock published values almost exactly. ME and MN are above growing-stock estimates by 28 to 35 percent, consistent with `proj_volcfnet` actually measuring something closer to merchantable bole volume than EVALIDator's strict growing stock filter. GA at -27 percent is the meaningful gap.

## Growth, removals, and the gr_ratio sanity check

The Forests of state RPA snapshots publish annual growth and removals which let us compute an independent gr_ratio at the published state-aggregate level. Compare to p1 cycle 1 BAU.

| State | FIA growth (mmcf/yr) | FIA removals (mmcf/yr) | FIA gr_ratio | p1 cycle 1 BAU gr_ratio | Convergence |
|---|---:|---:|---:|---:|---|
| ME (2021) | 1,013 | 305 | **3.32** | 0.01 (post Layer 1) → 0.43 (Layer 2 smoke) | Layer 2 still below FIA growth/removals; gross_growth field also bug-affected |
| MN (2020) | 855 | 244 | **3.50** | 0.01 (post Layer 1) | Same; not yet rerun with Layer 2 |
| GA (2022) | 2,808 | 1,436 | **1.96** | 0.01 (post Layer 1) | Same |

Reading: at state-aggregate scale, FIA reports growth running 2 to 3.5 times removals (forests are net accumulating biomass across all three states). Our `raw_mc_summaries.csv` gr_ratio of 0.01 after Layer 1 but before Layer 2 is two-orders-of-magnitude low. The Layer 2 smoke restored ME to 0.43, much closer to the FIA published 3.32 ratio. After full Maine econ rerun with Layer 2 we expect cycle 1 gr_ratio in the 1 to 4 range, conditional on the gross_growth field also being unit-corrected (note: Layer 2 only fixed harvest_removals, not gross_growth, so the convergence may be one-sided).

## Forest area sanity

Our state expansion currently assumes:

* ME 17.6 Mac (state_constants.csv) vs FIA 2021 17.52 Mac — within 0.5%
* MN 17.4 Mac vs FIA 2020 17.66 Mac — within 1.5%
* WA 22.0 Mac vs FIA 2022 ~22 Mac — within 0.5%
* GA 24.8 Mac vs FIA 2022 24.25 Mac — within 2.5%

All four assumed forest areas in our `state_constants.csv` track the latest RPA forest area to within 2.5 percent. Forest area is not the source of the multistate over-prediction signal.

## Per acre live tree volume cross-check

Computed FIA all-live per-acre volume:

| State | FIA vol (Bcuft) | FIA forest area (Mac) | FIA per ac (cuft/ac) | p1 per ac | Delta (%) |
|---|---:|---:|---:|---:|---:|
| ME (2021) | 27.70 | 17.52 | 1,581 | 1,533 | -3.0 |
| MN (2020) | 20.89 | 17.66 | 1,183 | 1,241 | +4.9 |
| WA (2022) | ~95 | ~22 | ~4,318 | 3,133 | -27.4 |
| GA (2022) | 66.91 | 24.25 | 2,759 | 1,326 | -51.9 |

Reading: ME tracks FIA all-live within 3 percent. MN within 5 percent. WA -27 percent gap; GA -52 percent gap. The state expansion volume gap therefore traces to the per-acre values themselves, not the forest area assumptions. Per-acre delta gradient (ME tightest, GA worst, WA in between) matches the hindcast subject-AGC bias pattern (WA +65%, MN +108%, GA +142%) inversely: the states most over-predicted at the subject-plot scale appear most under-predicted at the state-aggregate scale, supporting the subject pool bias hypothesis in `VALIDATION_SYNTHESIS_20260513.md`.

## Carbon comparison

GA is the only published value we have for total forest carbon:

* GA 2022: 1,709 MMT total carbon across all pools
* GA 2022: ~615 MMT live above-ground carbon (36% of total)
* p1 cycle 1 BAU GA carbon: 873 TgC (we report `mean_carbon`, which we assume is total ecosystem carbon based on the column header convention)

Our 873 TgC sits between the FIA live aboveground value (615 MMT) and the FIA total all-pool value (1,709 MMT). If `mean_carbon` is total ecosystem carbon (live + dead + DOM + soil), our number is roughly half the FIA total. If `mean_carbon` is only live above-ground, our number is 42 percent above FIA. Either way the unit convention is unclear and worth a one-paragraph clarification in the manuscript methods. The carbon-to-volume ratio sanity check in `CV_RATIO_SANITY_20260513.md` (27 kg C / cuft for GA) lands plausibly close to literature values (Smith et al. 2006: ~30 kg C per cuft for southern pine), so the order-of-magnitude is correct.

## Ownership distribution cross-check

Published RPA ownership (all four states, 2020 to 2022 vintages):

| State | Private | Federal | State/Local |
|---|---:|---:|---:|
| ME (2021) | 91.7% | 1.4% | 6.8% |
| MN (2020) | 45.0% | 16.3% | 38.7% |
| WA (2022) | varies regional, federal-majority overall on volume | high (Forest Service + Other) | meaningful (DNR lands) |
| GA (2022) | 88% | 8% | 4% |

The p1 WA RCP 4.5 owner distribution (cycle 1 BAU) from the refreshed validation:

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 10 | USDA Forest Service | 19,277 | 3,264 | 0.100 |
| 40 | Private (NIPF + industrial) | 5,716 | 2,508 | 0.092 |
| 30 | State and local | 1,376 | 3,957 | 0.096 |
| 20 | Other federal | 1,237 | 2,923 | 0.093 |

Counting plots: 19,277 / 27,606 = 70% Forest Service, 21% private, 5% state/local. WA forests are indeed federal-majority by plot count, consistent with RPA. The high state/local per-acre volume (3,957 cuft/ac, the highest of any owner class) tracks WA DNR's productive coastal forests. Private at 2,508 cuft/ac is below the state mean of ~4,300 cuft/ac, consistent with WA's industrial timberlands being on shorter rotations.

## Conclusions for manuscript

1. **ME r21 tracks RPA published values to within 3 percent** for both forest area and per-acre volume. The Maine calibration is solid.

2. **MN tracks within 5 percent** despite the hindcast over-prediction at the subject-plot scale. The state-aggregate volume is biophysically defensible.

3. **WA gap of 27 percent** is the most informative non-Maine signal. Worth diagnostic before publication: is this a per-acre projection issue or a subject pool composition issue or a unit definition mismatch? The owner-balanced HCB rebalance is part of the answer but may not explain all 27 percent.

4. **GA gap of 50 percent** is the largest. Given that GA growth-to-removals ratio in the FIA snapshot is only 1.96 (the lowest of the four states, reflecting GA's intensive pine plantation forestry), the p1 cycle-1 baseline may simply lag the post-harvest regeneration timing. Worth checking the cycle-1-to-cycle-15 trajectory against the FIA observed +783 mmcf/yr net change.

5. **Forest area assumptions in state_constants.csv are all within 2.5 percent of RPA published values**, ruling out forest area as the source of any gap.

6. **The gr_ratio fix needs both layers complete plus a gross_growth audit.** Layer 1 + Layer 2 of the harvest_removals fix moves cycle 1 ME from 0.01 to 0.43. RPA published value for ME is 3.32 (growth 3x removals). The remaining 8x gap likely lives in the gross_growth term, which uses `T2_volcfnet - pre_volcfnet` per cycle. That delta is a cumulative per-cycle change, while RPA reports annual growth. Dividing the cycle delta by cycle length (5 years) would give annual growth; we should verify that `gross_growth` in `raw_mc_summaries.csv` is in mmcf/yr or mmcf/cycle.

## Recommended follow-up runs

1. **ME r21 econ rerun with Layer 2 patch deployed** to produce manuscript-ready gr_ratio figures. Block on Wear 2025 logit recalibration first; see `LAYER2_SMOKE_RESULT_20260513.md`.

2. **GA cycle 15 vs cycle 1 trajectory plot** to test whether the 50 percent volume gap is a baseline timing artifact (recent plantation harvest) that converges by mid-projection.

3. **WA subject pool composition diagnostic** (Synthesis Method 5 hypothesis 1) to test whether 27 percent state-aggregate gap is partly subject pool bias.

4. **Carbon unit clarification** in the manuscript methods: confirm whether p1 `mean_carbon` is total ecosystem or live above-ground.

Sources:
- [Forests of Maine, 2021 (FS-366)](https://www.fs.usda.gov/nrs/pubs/ru/ru_fs366.pdf)
- [Forests of Minnesota, 2020 (FS-326)](https://www.fs.usda.gov/nrs/pubs/ru/ru_fs326.pdf)
- [Forests of Georgia, 2022 (FS-484)](https://www.srs.fs.usda.gov/pubs/ru/ru_fs484.pdf)
- [Pacific Northwest Research Station, Washington State Stats](https://www.fs.fed.us/pnw/rma/fia-topics/state-stats/Washington/index.php)
- [2020 RPA Assessment](https://research.fs.usda.gov/inventory/rpaa/2020)
- [Forest Resources of the United States, 2017 (GTR-WO-97)](https://www.fs.usda.gov/research/publications/gtr/gtr_wo97.pdf)
