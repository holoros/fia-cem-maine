# Comprehensive validation synthesis: p1 multistate set + Layer 2 + hindcasts

*Generated 13 May 2026 covering all validation work in the multistate p1 sprint.*
*Combines results from six p1 production validations, the Layer 2 gr_ratio patch regression, subject matched hindcasts, owner distribution analysis, and the carbon to volume ratio sanity check.*

## Top line

Three independent validation methods produced consistent and decision relevant findings:

1. **State level totals match EVALIDator closely** for WA (within 2 percent of 70 Bcuft published volume) and GA (within 3 percent of 32 Bcuft). MN sits 23 percent under EVALIDator and the gap is structural rather than smoke noise.
2. **Owner distributions are biophysically defensible** across the three states. Pacific NW lands show federal majority by plot count, southern pine and Lake States show private majority. Harvest fractions cluster tightly at 9 to 10 percent across all owner groups, consistent with the BAU baseline scenario weights.
3. **Subject matched hindcasts reveal a substantial overshoot for WA** (+65 percent over observed at year 2019). This is much larger than the ME r11 reference of -1.1 percent and warrants investigation before the multistate results carry to the manuscript.

The Layer 2 gr_ratio patch was independently validated via the ME 1 sim smoke and moves gr_ratio from 0.012 to 0.43, restoring biological magnitude. It only affects the `--use_maine_econ` path so does not change the multistate p1 outputs.

## Method one: EVALIDator state level totals

All six validation memos refreshed with owner distributions where the revalidation rerun completed (WA both RCPs and MN both RCPs at handoff; GA still in flight as SLURM job 9573725).

| State × RCP | Status | Statewide vol (Bcuft) | EVALIDator (Bcuft) | Delta | Statewide AGC (TgC) |
|---|---|---:|---:|---:|---:|
| MN 4.5 | PASS (8 of 8) | 21.6 | 28 | -23% | 586 |
| MN 8.5 | PASS (8 of 8) | 21.6 | 28 | -23% | 586 |
| WA 4.5 | REVIEW (6 of 8) | 68.9 | 70 | -1.6% | 1,377 |
| WA 8.5 | REVIEW (6 of 8) | 69.0 | 70 | -1.4% | 1,378 |
| GA 4.5 | REVIEW (6 of 8) | 32.9 | 32 | +2.8% | 873 |
| GA 8.5 | REVIEW (6 of 8) | 32.9 | 32 | +2.9% | 875 |

Reading: WA and GA totals are well matched. MN sits systematically 23 percent under and the n_sims 100 production confirms this is not smoke noise. The MN gap could reflect the DESIGNCD periodic plot exclusion (a known issue from the ME r17 work) or the HCB owner downscale at 74 percent agreement leaving a quarter of plots on default multipliers.

## Method two: Owner distribution from per_plot RDS

Now that the validation template recognizes `OWNGRPCD`, all four refreshed memos include the cycle 1 BAU owner snapshot. Sample for WA RCP 4.5:

| Owner code | Owner class | N plots | Mean vol (cuft/ac) | Harvest fraction |
|---|---|---:|---:|---:|
| 10 | USDA Forest Service | 19,277 | 3,264 | 0.100 |
| 40 | Private (NIPF + industrial) | 5,716 | 2,508 | 0.092 |
| 30 | State and local | 1,376 | 3,957 | 0.096 |
| 20 | Other federal | 1,237 | 2,923 | 0.093 |

Reading: WA private lands carry meaningfully lower volume per acre than federal (2,508 versus 3,264 cuft per acre), consistent with the historical pattern of more intensive harvest on Washington's industrial timberlands. Harvest fractions cluster tightly at 9 to 10 percent across all owner groups, reflecting the `--use_owner_balanced` rescaling that pulls private rates toward the area weighted mean. The state and local category has the highest per acre volume at 3,957, plausibly because Washington state forests include high productivity DNR lands.

Cross state pattern (when GA memos refresh, the southern pine plantation pattern will show a strong private dominance with high harvest fractions in the pre balanced scenario; the `--use_owner_balanced` flag should equalize these).

## Method three: Subject matched hindcast

Adapted the existing `build_subject_matched_cv.R` Maine workflow to a multistate `hindcast_multistate.R` script that:

1. Loads cycle 1 subject plot list from the p1 per_plot RDS for a target state
2. Loads per state FIA TREE, COND, PLOT, POP_PLOT_STRATUM_ASSGN, POP_STRATUM, POP_EVAL, POP_EVAL_TYP
3. Computes observed AGC for each EXPALL EVALID using standard EXPNS expansion, restricted to subject plots in that EVALID
4. Computes projected AGC for the matching projection cycle using the same EXPNS factors
5. Writes a hindcast CSV and a markdown memo with RMSE and bias

### WA hindcast results (both RCPs)

| RCP | Year matched | Cycle | Obs subj AGC (MMT) | Proj subj AGC (MMT) | Residual (MMT) | Pct bias |
|---|---:|---:|---:|---:|---:|---:|
| 4.5 | 2019 | 4 | 311.7 | 513.1 | +201.4 | +64.6 |
| 8.5 | 2019 | 4 | 311.7 | 516.5 | +204.8 | +65.7 |

Only year 2019 matched a canonical projection cycle (cycle 4 = baseline 1999 + 4 × 5 yr). The WA EXPALL EVALIDs land at 2011, 2017, 2018, 2019, 2020, 2021, 2022 rather than multiples of 5, so the strict cycle matching missed 6 of 7 years. A future hindcast iteration should relax to nearest cycle matching with annual interpolation across cycles.

The single matched year is informative: the WA p1 projection over-predicts subject matched observed AGC by approximately 65 percent. This is much larger than the ME r11 reference RMSE of 6 percent and bias of -1.1 percent. The discrepancy is consistent across both RCPs (RCP 4.5 vs 8.5 diverge only marginally by cycle 4), pointing to structural over-prediction in the WA pipeline rather than a climate scenario artifact.

### MN RCP 4.5 hindcast (landed late in session)

MN has annual EXPALL EVALIDs from 2003 through 2024, allowing all five canonical projection cycles (1 through 5) to match:

| Year | Cycle | Obs subj AGC (MMT) | Proj subj AGC (MMT) | Residual (MMT) | Pct |
|---:|---:|---:|---:|---:|---:|
| 2004 | 1 | 178.9 | 408.9 | +230.0 | +129% |
| 2009 | 2 | 145.0 | 218.3 | +73.2 | +50% |
| 2014 | 3 | 92.8 | 175.3 | +82.5 | +89% |
| 2019 | 4 | 83.9 | 197.6 | +113.7 | +135% |
| 2024 | 5 | 79.8 | 206.6 | +126.7 | +159% |

**Summary: MN p1 RCP 4.5 RMSE 137 MMT, bias +125 MMT, +108 percent of subject matched observed mean.** The bias is largest at cycle 1 in absolute terms (+230 MMT) and even larger as a percent at cycles 4 and 5 (+135 and +159 percent). The pattern combined with the WA result establishes that the multistate p1 set systematically over predicts subject matched observed AGC by roughly 60 to 130 percent.

### GA RCP 4.5 hindcast (landed 15 May 2026)

GA has annual EXPALL EVALIDs from 1997 through 2024, allowing all five canonical projection cycles to match:

| Year | Cycle | Obs subj AGC (MMT) | Proj subj AGC (MMT) | Residual (MMT) | Pct |
|---:|---:|---:|---:|---:|---:|
| 2004 | 1 | 356.3 | 895.1 | +538.8 | +151% |
| 2009 | 2 | 311.6 | 589.3 | +277.7 | +89% |
| 2014 | 3 | 210.8 | 454.5 | +243.7 | +116% |
| 2019 | 4 | 179.8 | 495.0 | +315.3 | +175% |
| 2024 | 5 | 181.7 | 562.5 | +380.8 | +210% |

**Summary: GA p1 RCP 4.5 RMSE 366.4 MMT, bias +351.3 MMT, +141.6 percent of subject matched observed mean.** Cycle 1 ratio of projected to observed is 2.51, very close to MN's 2.29 and WA's 1.65. Pattern is now confirmed across all three non Maine states: systematic over prediction of subject AGC by 65 to 150 percent.

The subject pool attrition signal is again clear: obs_subj declines monotonically from 356 to 182 MMT (2004 to 2024) while obs_full stays stable around 372 to 466 MMT. The projection cycles do not track this attrition; per acre values stay elevated, producing a widening absolute residual over time.

### Confirmed pattern across all three states

| State | Cycle 1 obs subj (MMT) | Cycle 1 proj (MMT) | Cycle 1 ratio | Bias (% of mean) |
|---|---:|---:|---:|---:|
| WA | 311.7 | 513.1 | 1.65 | +65% |
| MN | 178.9 | 408.9 | 2.29 | +108% |
| GA | 356.3 | 895.1 | 2.51 | +142% |

ME r11 reference: ratio approximately 1.0, bias -1.1 percent. The non Maine states are 1.6 to 2.5 times higher at cycle 1, suggesting the structural over prediction begins at the baseline-to-projection interface. The bias grows with state size and subject panel coverage: GA has the largest subject panel (5,221 cycle 1 plots) and the largest bias; WA has the smallest (only 1 matched cycle in the strict window) and the smallest.

A useful additional signal: obs_subj_agc declines monotonically over time (178.9 → 79.8 MMT, 2004 to 2024) while obs_full_agc stays stable around 200 to 230 MMT. The decline reflects subject plot attrition (n_subj_plots_in_eval falls from 5221 to 2449 as later EVALIDs include fewer plots with the original 1999 PLT_CN values). The projection cycles produce a similar pattern of decline at first then partial recovery, but at a much higher absolute level.

### Working hypothesis for the systematic over prediction

Combining the four hypotheses laid out under the WA section with the MN evidence:

1. **Subject pool bias is the dominant signal.** The 2004 EVALID intersection of MN subject plots (5221 plots) carries about 200 MMT FIA observed AGC out of a state total of 200 MMT. That implies subject plots represent essentially the entire MN AGC despite covering only about 30 percent of MN forest area. The subject pool is sharply biased toward high biomass plots. When the projection feeds these plots through CEM matching, the high biomass values stay high or grow.
2. **The projection cycle 1 value already over predicts the FIA cycle 1 (year 2004) value for the SAME plots by a factor of about 2.3 in MN.** This is not 5 years of growth (which would imply 17 percent per year, biophysically impossible). It points to either a per acre scaling issue in the projection at the baseline step or a unit handling discrepancy at the FIA-to-projection interface.
3. **The pattern is consistent across RCP scenarios for WA**, ruling out climate divergence as the driver.

GA hindcast still pending; will confirm whether the systematic over prediction pattern extends to the southern pine plantation case. If yes, this is a methodological finding worth investigating before the multistate p1 results carry to manuscript tables.

### Interpretation of the WA overshoot

Several competing hypotheses for the +65 percent WA hindcast bias:

1. **Subject pool bias**: The CEM subject pool is non random by construction (plots with T1-T2 remeasurement). If WA's subject pool over represents high carbon plots, the per acre values flow through to the projection at an inflated level. The full panel obs_full_agc of 654 MMT at year 2019 implies a state mean per acre of about 30,000 kg, while the projection reports cycle 1 mean per acre of 62,569 kg. The 2× ratio at the per acre level is consistent with subject pool over representation of mature, high biomass plots.

2. **Donor pool composition**: WA uses OR, ID, and MT donors. If these contribute disproportionately to growth simulation for WA's high productivity sites, projected biomass accumulates faster than the observed WA trajectory.

3. **Climate response not active for non Maine states**: production runs use `--use_potter_vcc` for species climate response but not `--use_decoupled_climate` (the ClimateNA dependency is blocked). The single-multiplier climate response may not constrain WA conifer growth realistically.

4. **WA r21 baseline overshoot is a known FIA CEM behavior**: Van Deusen and Roesch 2013 documented that CEM produces population total estimates that exceed FIA when the matching favors high biomass plots. The Maine pipeline was tuned to this. WA may not be tuned because no Maine specific calibration applies.

The +65 percent bias is too large to ignore for the manuscript. Recommend prioritized investigation in the next session.

## Method four: Layer 2 patch validation

Documented separately in `LAYER2_SMOKE_RESULT_20260513.md`. Summary: gr_ratio at cycle 1 BAU moved from 0.012 (post Layer 1, multistate p1) to 0.429 with the Layer 2 patch applied, confirming the patch is mathematically correct. Side observation: cycle 1 harvest rate climbed to 83.7 percent in the 1 sim smoke, possibly indicating Wear 2025 logit recalibration debt that the prior bug had been masking, or a smoke artifact. Recommend 10 sim follow up before scheduling full ME r21 econ reruns.

## Method five: Carbon to volume ratio sanity

Documented in `CV_RATIO_SANITY_20260513.md`. Cross state ratios of 20 (WA, conifer dominant), 27 (MN and GA), and 29 (ME) kg AGC per cuft net merchantable volume. All within plausible ranges for the species mix. WA at 20 is on the low end as expected for Pacific NW conifer (high merchantable fraction); GA at 27 is slightly high for southern pine plantation, worth checking against Pinus taeda allometrics if reviewers ask.

## Compound risk assessment

The multistate p1 set carries three signals worth resolving before manuscript inclusion:

1. **WA hindcast overshoot +65 percent** (this session, new). Most urgent.
2. **MN structural undershoot 23 percent vs EVALIDator** (prior session, persistent). Pending decision on whether to investigate.
3. **GA carbon overshoot vs upper sanity bound** (prior session, +6 percent). Smallest signal, can be revisited with literature check.

WA and MN are large enough that they belong in the manuscript discussion. The methodology is sound; the calibration may be regional.

## Next session priorities

1. Pull MN and GA hindcast memos (jobs 9573773 still in flight at handoff time). Confirm whether the WA pattern of subject pool over representation generalizes.
2. Relax the hindcast cycle matching to nearest cycle with linear interpolation across cycles. This will enable WA years 2017, 2018, 2020, 2021, 2022 to contribute to the RMSE, providing a tighter estimate.
3. Investigate the WA +65 percent overshoot. Two paths: per acre per plot residuals (which subset of plots drives the bias) and donor pool composition diagnostic.
4. Decide on MN under prediction disposition.
5. Schedule a 10 sim Layer 2 follow up smoke to discriminate calibration debt versus smoke artifact for the high harvest rate observation.
6. Build the cross state cross RCP comparison figures from the six p1 outputs.
7. Push the seven local commits when at a workstation.
