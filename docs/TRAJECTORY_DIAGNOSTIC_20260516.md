# Cycle 1 to 15 trajectory diagnostic across all p1 states

*Generated 16 May 2026 from `table_inventory_summary.csv` in all eight production output directories.*

## Three findings worth manuscript attention

### Finding 1: WA No_harvest volume declines (state-specific bug candidate)

Among the four states × two RCPs × five scenarios, exactly one combination shows volume declining under No_harvest (where the model is supposed to allow uninterrupted accumulation toward carrying capacity): WA in both RCPs.

| State | RCP | c1 No_harvest vol | c15 No_harvest vol | Change |
|---|---|---:|---:|---:|
| ME r21 | 4.5 | 1,608 | 1,958 | +22% |
| ME r21 | 8.5 | 1,617 | 2,376 | +47% |
| MN p1 | 4.5 | 1,302 | 1,758 | +35% |
| MN p1 | 8.5 | 1,303 | 1,768 | +36% |
| WA p1 | 4.5 | 3,279 | **1,946** | **-41%** |
| WA p1 | 8.5 | 3,282 | **2,193** | **-33%** |
| GA p1 | 4.5 | 1,378 | 4,196 | +204% |
| GA p1 | 8.5 | 1,381 | 5,096 | +269% |

WA is the only state where No_harvest produces a volume loss over 75 years. Three competing hypotheses:

1. **Disturbance dominates growth in WA.** The `state_constants.csv` row for WA has `fire_baseline_per_cycle` of 0.060 (10× ME). Under No_harvest the disturbance still fires, and the WA forests are exposed to compounding fire mortality across 15 cycles. If `fire_red = 0.40` (40 percent biomass retention) is applied to roughly 60 percent of plots per cycle, the multiplicative volume retention over 15 cycles is (0.4^9) × (1.0^6) = 2.6 × 10^-4, a near total volume wipeout. The actual c15 No_harvest at 1,946 cuft/ac is consistent with disturbance-dominated dynamics if growth runs roughly 5 to 10 cuft/ac/yr and disturbance removes 50 to 100 cuft/ac/yr. **This is the most likely explanation.**

2. **SDImax cap pulling values down.** State_constants.csv WA `sdimax_default_english` is 510 trees/ac. If c1 plots are above SDImax (e.g., overstocked PNW old growth), the model would force volume reduction to bring SDI within bound. But the cycle 1 baseline is exactly the FIA observed value, so the model shouldn't see it as out-of-bound. **Less likely.**

3. **Donor pool dynamics.** WA pulls donors from OR/ID/MT, which are drier and less productive than coastal WA. If donor plots dominate the imputed growth, projected biomass would converge toward the donor mean. **Quantifiable by computing per-cycle volume change segregated by donor state.** Worth a follow-up diagnostic.

**Recommendation:** if hypothesis 1 holds, the WA fire_baseline of 0.060 may itself be too high or the per-event biomass retention (0.40) too low. Documented in state_constants.csv with the note "WA wildfire 0.060/cycle is 10× ME (matching PNW DNR + USFS reality)." Per recent literature, wildfire affects roughly 1 to 2 percent of WA forest land annually depending on year, so 0.060/cycle (about 1.2 percent per year) is in the right magnitude. The 60 percent biomass loss per event may be the more aggressive assumption to revisit.

### Finding 2: TPA accumulation in cycle 15 is biophysically impossible

Across all four states the cycle 15 TPA is 10× to 150× the cycle 1 TPA, exceeding any biological carrying capacity by an order of magnitude.

| State | c1 TPA | c15 BAU TPA | c15 NoHarv TPA | Max ratio |
|---|---:|---:|---:|---:|
| ME r21 RCP 4.5 | 742 | 23,390 | 41,416 | 56× |
| MN p1 RCP 4.5 | 543 | 5,702 | 13,028 | 24× |
| WA p1 RCP 4.5 | 340 | 15,126 | **51,178** | **151×** |
| GA p1 RCP 4.5 | 498 | 4,782 | 23,059 | 46× |

Natural forests rarely exceed 5,000 trees/ac even in dense regenerating stands. 41,000 trees/ac in mature ME No_harvest is implausible by an order of magnitude. The TPA blow-up is universal but most severe in WA No_harvest. This suggests the projection engine accumulates regeneration (planted or natural recruits) without proper tree-level mortality or self-thinning.

The mechanism may be that `proj_tpa` is computed as the sum of all live trees imputed from donor plot matches, but the donor matching effectively double-counts seedlings/saplings across cycles. When a plot regenerates (TPA jumps from 100 to 5,000), the next cycle's CEM matching may use the high-TPA state to find new donors, and those donors contribute their own seedlings, compounding TPA without bound.

**Implication for manuscript:** late-cycle TPA values cannot be reported as headline metrics. Volume and basal area may be approximately correct (since they're area-based rather than count-based) but should be sanity-checked against literature carrying capacity per state. The Maine r21 publication may have side-stepped this by reporting volume and carbon rather than TPA, or by filtering to ≥5" d.b.h. trees only.

**Recommendation:** audit the `proj_tpa` computation in `cem_pipeline_patch/06_projection_engine.R`. Look for whether `proj_tpa` sums all imputed trees (correct interpretation) or sums only live large trees with implicit mortality applied (intended interpretation). The current values suggest the former.

### Finding 3: GA baseline timing explains some but not all of the RPA volume gap

GA cycle 1 (year 2004) BAU vol = 1,326 cuft/ac.
GA cycle 15 (year 2074) BAU vol = 2,067 cuft/ac.

Linear interpolation at cycle 5 (year 2024, the year of the latest RPA snapshot):

`vol_c5 ≈ 1,326 + (2,067 − 1,326) × 4/14 ≈ 1,538 cuft/ac`

FIA published GA all-live volume in the 2022 snapshot (FS-484): 66.91 Bcuft on 24.25 Mac forest land = **2,759 cuft/ac**.

Even at cycle 5 (the RPA-comparable year), the p1 projection is at 1,538 cuft/ac vs FIA's 2,759. Gap: -44%. Baseline timing closes about 6 percentage points of the original 50% gap (cycle 1 1,326 vs cycle 5 1,538), but the remaining 44% is structural.

For ME r21 the equivalent calculation:

`ME cycle 1 vol = 1,533, cycle 15 = 1,168, linear interp at c5 ≈ 1,533 + (1,168-1,533) × 4/14 = 1,429 cuft/ac`
`FIA 2021 ME live tree vol: 27.7 Bcuft / 17.52 Mac = 1,581 cuft/ac`
`Gap: -10%, within published sampling error`

ME tracks FIA within sampling error at cycle 5 (the comparable year). GA does not. The non-Maine structural over-prediction at the subject-plot scale (from the hindcast analysis) combined with state-aggregate under-prediction (this analysis) is the manuscript story: subject pool bias inflates the per-plot projection but the population-weighted state total still under-runs the FIA growth trajectory.

### Cross-state trajectory under BAU

| State | RCP | c1 vol | c15 vol | Δ | c1 BA | c15 BA | c1 carbon | c15 carbon |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| ME r21 | 4.5 | 1,533 | 1,168 | -24% | 89.5 | 57.8 | 43,970 | 32,087 |
| ME r21 | 8.5 | 1,542 | 1,399 | -9% | 90.0 | 67.8 | 44,240 | 37,892 |
| MN p1 | 4.5 | 1,241 | 944 | -24% | 68.7 | 39.6 | 33,650 | 22,375 |
| MN p1 | 8.5 | 1,242 | 946 | -24% | 68.8 | 39.9 | 33,677 | 22,596 |
| WA p1 | 4.5 | 3,133 | 1,310 | -58% | 109.9 | 39.5 | 62,569 | 25,111 |
| WA p1 | 8.5 | 3,136 | 1,451 | -54% | 110.0 | 42.8 | 62,642 | 27,668 |
| GA p1 | 4.5 | 1,326 | 2,067 | +56% | 67.4 | 53.1 | 35,214 | 42,636 |
| GA p1 | 8.5 | 1,328 | 2,449 | +84% | 67.6 | 60.5 | 35,281 | 49,641 |

GA is the only state where BAU volume increases (because southern pine plantations starting at low cycle 1 baseline accumulate to mature volumes by cycle 15). The other three states show declining volume under BAU, with WA most aggressive. The RCP 8.5 BAU trajectories are uniformly higher than RCP 4.5 across all states except MN, where the two RCPs are essentially identical (MN climate response is muted in the model, also noted in the production runs comparison).

## Implications for manuscript

1. **Bound the reporting horizon at cycle 5 to 7** (years 2024 to 2034) where TPA blow-up is still moderate. Cycle 15 figures are unreliable as headline metrics.
2. **WA needs a diagnostic round** to resolve the No_harvest decline before WA results enter the manuscript.
3. **GA baseline timing matters but is not the whole story.** Subject pool bias (from hindcast analysis) is the dominant signal.
4. **Reporting per-acre BA and volume is safer than reporting TPA**, given the count accumulation artifact.
5. **State-specific dynamics calibration is the next research priority.** Maine works (ME r21 within 10 percent of RPA at cycle 5); the multistate extension needs per-state regeneration and mortality tuning.

## Quick wins for immediate follow-up

* Pull cycles 2 to 14 for one state to fit a logistic curve and confirm the cycle 5 to 7 reporting horizon.
* Sanity check: does WA cycle 1 No_harvest TPA (348) match FIA published WA mean TPA? If yes, cycle 1 baseline is FIA-faithful and the bug is downstream.
* Sanity check: does ME r21 cycle 5 vol = 1,533 + (1,168 − 1,533)(4/14) ≈ 1,429 match the user's prior r21 cycle-5 inventory snapshot? Confirm the linear interpolation is approximately representative.

## Update: actual cycle 5 values pulled from ci_summaries.csv

The linear interpolation estimate was systematically low. Actual c5 BAU values from `ci_summaries.csv`:

| State | RCP | c1 vol | c5 vol (actual) | c5 vol (interp) | c15 vol |
|---|---|---:|---:|---:|---:|
| ME r21 | 4.5 | 1,533 | **1,749** | 1,429 | 1,168 |
| MN p1 | 4.5 | 1,241 | **1,408** | 1,156 | 944 |
| WA p1 | 4.5 | 3,133 | **3,012** | 2,612 | 1,310 |
| GA p1 | 4.5 | 1,326 | **1,984** | 1,538 | 2,067 |

Interpolation underestimates by 14 to 22 percent because the trajectory is not linear. The actual cycles 1 to 5 show growth (volume builds) before decline kicks in (cycles 5 onward as TPA artifacts emerge).

Re-doing the RPA comparison at cycle 5 (the year 2024 RPA-comparable vintage):

| State | c5 BAU vol (cuft/ac) | FIA all-live (cuft/ac) | Delta |
|---|---:|---:|---:|
| ME r21 RCP 4.5 | 1,749 | 1,581 | **+11%** |
| MN p1 RCP 4.5 | 1,408 | 1,183 | **+19%** |
| WA p1 RCP 4.5 | 3,012 | 4,318 | -30% |
| GA p1 RCP 4.5 | 1,984 | 2,759 | -28% |

**Reading:** at the cycle 5 horizon (manuscript-reportable vintage), all four states are within 30 percent of FIA published. ME and MN are slightly over (matching the per-acre publication direction). WA and GA are under by 28 to 30 percent.

TPA at cycle 5 (510 to 946 trees/ac) is biophysically plausible. The TPA blow-up to 41,000+ trees/ac is a late-cycle artifact (cycles 10+) tied to SDImax cap not capping TPA. **Confirms cycle 5 is the right manuscript reporting horizon.**

## proj_tpa code audit finding

Located the TPA accumulation bug at `cem_pipeline_patch/06_projection_engine.R` lines 742-763, function `apply_sdimax_cap`. The function correctly reduces `proj_BA, proj_volcfnet, proj_volcsnet, proj_drybio, proj_carbon` by `sdi_ratio` when projected SDI exceeds SDImax. But `proj_tpa` is not included in the reduction. SDI grows without bound while BA and volume are clipped.

Mathematically, SDI = TPA × (QMD/10)^1.605. If SDI > SDImax and we want to cap it, we must reduce TPA, QMD, or both. The current code reduces BA and volume (implicitly reducing QMD), but leaves TPA free to accumulate. This produces the "more, smaller trees" interpretation that's biophysically wrong — natural self-thinning kills small trees first while surviving trees grow bigger.

**Proposed Layer 4 patch:**

```r
# In apply_sdimax_cap, line 754-758, ADD:
proj_tpa      = proj_tpa      * sdi_ratio,
```

The trade-off: this would also reduce projected TPA at the SDImax cap, matching natural self-thinning where mortality removes small trees. The total biomass would be carried on fewer larger trees; per-acre volume might increase rather than decrease at the cap.

A cleaner formulation: cap TPA at SDImax (with QMD fixed):

```r
# Replace the current 5-line block with:
mutate(
  ratio_for_BA = pmin(1, sdimax_eng / pmax(0.1, proj_sdi)),
  ratio_for_tpa = ratio_for_BA,  # mortality removes small trees first
  proj_tpa      = proj_tpa * ratio_for_tpa,
  proj_BA       = proj_BA * sqrt(ratio_for_BA),       # less aggressive on BA
  proj_volcfnet = proj_volcfnet * sqrt(ratio_for_BA),
  proj_volcsnet = if ("proj_volcsnet" %in% names(df)) proj_volcsnet * sqrt(ratio_for_BA) else proj_volcsnet,
  proj_drybio   = proj_drybio * sqrt(ratio_for_BA),
  proj_carbon   = proj_carbon * sqrt(ratio_for_BA)
)
```

The `sqrt(ratio)` distribution lets the cap split the impact between TPA (count) and BA-equivalents (size). At ratio = 0.5 (50 percent excess SDI), TPA drops by 50 percent and BA drops by ~30 percent. This is consistent with self-thinning dynamics.

**Recommendation:** apply the minimal one-line patch first to confirm TPA capping works, then evaluate the sqrt variant if BA/vol need preservation. Both fixes should land before any cycle 10+ figures enter the manuscript.
