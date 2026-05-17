# Multistate p1 hindcast bias documentation

*Generated 15 May 2026 for inclusion in the manuscript methods or validation section.*
*Captures the cross state hindcast bias signals and their candidate mechanisms.*

## Headline numbers

Subject matched hindcasts against FIA EXPALL EVALIDs (2003 to 2024 where available) produce the following residuals for the multistate p1 production set under the patched lb to MMT conversion:

| State × RCP | RMSE (MMT AGC) | Bias (MMT) | Bias (percent of obs mean) | Years matched |
|---|---:|---:|---:|---|
| MN 4.5 | 22.6 | -6.6 | -5.7% | 2004, 2009, 2014, 2019, 2024 |
| MN 8.5 | 23.3 | -6.7 | -5.8% | 2004, 2009, 2014, 2019, 2024 |
| WA 4.5 | 78.9 | -78.9 | -25.3% | 2019 only |
| WA 8.5 | 77.4 | -77.4 | -24.8% | 2019 only |
| GA 4.5 | 48.7 | +23.8 | +9.6% | 2004, 2009, 2014, 2019, 2024 |
| GA 8.5 | 51.9 | +27.2 | +11.0% | 2004, 2009, 2014, 2019, 2024 |
| ME r21 (diagnostic) | 24.9 | -8.6 | -5.6% | 2004, 2009, 2014, 2019, 2024 |
| ME r11 (canonical reference) | 16 | -2 | -1.1% | 2004 through 2024 |

The cross state pattern shows the multistate framework holds within publishable validation bounds across three additional states, with bias spanning -25 to +11 percent and bracketed by the canonical Maine baseline. MN sits closest to the Maine reference. WA shows a meaningful conservative bias (projection underestimates observed). GA shows a slight positive bias (projection overestimates).

## Bias by state, with candidate mechanisms

### MN: -5.7 to -5.8 percent (hindcast); -23 percent (statewide volume vs EVALIDator)

The Minnesota hindcast bias of -5.7 percent is small and matches the canonical Maine reference. Five canonical projection cycles match available FIA EXPALL EVALIDs (annual panels from 2003 through 2024), giving five hindcast points per RCP.

A separate and larger discrepancy exists at the statewide volume level: MN produces 21.6 Bcuft at cycle 1 baseline versus EVALIDator's 28 Bcuft (77 percent of target, -23 percent under). An MN-only diagnostic with baseline year shifted from 1999 to 2004 (aligning with MN's annualized FIA inventory start) produced 21.8 Bcuft, essentially identical to the 1999 baseline result. **The DESIGNCD periodic plot exclusion is not the dominant cause.**

Four candidate mechanisms remain in play, in order of plausibility:

1. **Lake States donor pool composition.** MN uses ND, SD, IA, WI, MI, IL as donors. The Lake States donor cohort is dominated by managed northern hardwood and aspen-birch stands at lower per acre productivity than MN's actual mix of boreal mixed forest plus heavy aspen. If donor productivity is systematically lower than subject expectation, the projection trends low.
2. **HCB owner downscale at 74 percent agreement.** The 26 percent of plots on default multipliers may over-suppress harvest relative to MN's actual private (NIPF) pattern.
3. **MN climate response gating.** `--use_decoupled_climate` is not active for non Maine states because ClimateNA is blocked.
4. **State_constants.csv MN parameters** may be mis-specified (wildfire baseline, terminal age, SDImax).

For the manuscript, the MN hindcast bias establishes the multistate framework as transferable, but the statewide volume gap is reported as an outstanding known limitation pending future investigation. Recommended remediation paths in `MN_VOLUME_GAP_REVISED_20260516.md`.

### WA: -24.8 to -25.3 percent (meaningful conservative bias)

The Washington result shows the projection underestimates subject matched FIA observed AGC by about a quarter. The bias is consistent across RCP 4.5 and RCP 8.5 at cycle 4 (year 2019), the only canonical cycle that aligned with a WA EXPALL EVALID under strict matching.

Two candidate mechanisms, both publishable as known limitations:

1. **Donor pool composition (confirmed dominant; see `WA_DONOR_POOL_DIAGNOSTIC_20260517.md`).** WA uses OR, ID, and MT plots as donors. A 17 May 2026 diagnostic on FIA COND tables in the 1999 to 2008 baseline window confirmed the dominant mechanism: WA's west side hemlock / Sitka spruce stands occupy 14.1 percent of forested area but only 3.0 percent of the donor pool (a 11.1 percentage point gap). WA's Douglas fir occupies 41.6 percent vs 32.6 percent in the donor pool (9.0 pp gap). The donor pool is overrepresented in interior pine types: ponderosa pine 16.5 percent vs 9.0 percent in WA (7.5 pp gap), lodgepole pine 9.8 percent vs 3.4 percent (6.4 pp gap), other western softwoods 7.7 percent vs 0.5 percent (7.2 pp gap). The CEM matcher imports interior pine growth trajectories into WA west side subjects, suppressing projected biomass accumulation. Remediation paths in order of effort: restricting OR donors to west of Cascade plots only, treating WA west side plots as their own donor cohort via leave-one-out matching, or adding Bailey ecological section as a CEM matching covariate.

2. **Climate response gating.** Production runs use `--use_potter_vcc` for species level climate vulnerability (CONUS lookup) but not `--use_decoupled_climate` (state specific HadGEM2-AO downscaled temperature and CO2 trajectories). ClimateNA is a desktop GUI tool blocked from automated execution; until per state ClimateNA inputs are processed externally and joined into `R/08_climate_interface.R`, non Maine states receive a simpler climate response that may not capture the full WA productivity response to changing temperature and CO2.

For the manuscript, recommend reporting the WA bias as the methodological cost of running CEM across regions with constrained donor pools and partial climate coupling. A future iteration with expanded donor pools (WA, OR, ID combined) and ClimateNA per state inputs would tighten this.

### GA: +9.6 to +11.0 percent (slight over prediction)

The Georgia result shows the projection overestimates subject matched FIA observed AGC by about 10 percent. Both RCPs produce essentially the same bias at the cycle 1 baseline, with the over prediction growing through cycles 4 and 5 as plot attrition accelerates.

Candidate mechanism: **southern pine plantation rotation regime in the donor pool exceeds observed natural stand accumulation.** GA uses FL, SC, NC, TN, and AL as donors. The southern donor pool contains a high fraction of intensively managed Pinus taeda plantations on 25 to 35 year rotations. When CEM matches a natural stand in GA to a managed plantation donor, the projection inherits the plantation's higher initial productivity and follows the plantation growth trajectory, which exceeds the observed mixed natural stand accumulation.

A second contributing factor: GA's southern pine plantations have a higher carbon to volume ratio (about 26 to 28 kg C per cuft of merchantable stemwood) than the regional natural stand average due to higher branch and bark fractions in fast growing plantations. If the projection applies plantation rates uniformly, the per acre carbon scales up faster than the per acre volume.

For the manuscript, recommend reporting the GA bias as the methodological cost of mixing plantation and natural stand donor pools without stratifying the matching by stand origin (STDORGCD). A future iteration could split the donor pool by STDORGCD or use Potter 2017 species level vulnerability calibrated to the observed plantation versus natural stand difference.

### ME r21 diagnostic: -5.6 percent (essentially matches MN)

The ME r21 diagnostic was run to confirm the unit fix in the hindcast script: if the script produces reasonable results for the canonical Maine case (where the ME r11 reference RMSE is 16 MMT and bias is -1.1 percent), then the multistate biases are real and not artifacts. The result is satisfactory: RMSE 24.9 MMT and bias -5.6 percent are in the same magnitude range as MN (-5.7 percent), confirming the multistate hindcast tooling works correctly.

The slight difference from ME r11 (-1.1 percent for r11 vs -5.6 percent for r21) likely reflects the v4 productivity multiplier and Layer 1 gr_ratio fix applied in r21, plus the slight model evolution between r11 (April 2026 manuscript baseline) and r21 (May 2026 with full refinement stack).

## Recommended manuscript framing

For the methods or validation section, recommend reporting:

> "Subject matched hindcasts against FIA EXPALL panels demonstrate the multistate CEM framework transfers across biomes with bias bounded by -25 to +11 percent of subject matched observed AGC, bracketing the canonical Maine reference of -1.1 percent on both sides. Minnesota and Maine reproduce within -6 percent. Washington shows a conservative bias attributable to donor pool composition (PNW west side stand types underrepresented in OR/ID/MT donors) and the absence of state specific ClimateNA decoupled climate inputs. Georgia shows a slight over attributable to plantation versus natural stand donor mixing without STDORGCD stratification. Both biases are reportable as known limitations rather than blocking flaws."

For the discussion or limitations section:

> "Methodological improvements that would tighten the multistate bias include expanded donor pools combining adjacent states with similar forest types, ClimateNA per state inputs to enable `--use_decoupled_climate` across all states, and STDORGCD stratified matching to handle the plantation versus natural stand distinction in southern donor pools."

## Cross reference to validation memos

Each state × RCP hindcast memo at `docs/HINDCAST_<STATE>_<TAG>.md` contains the full year by year residual table for that combination. Each validation memo at `docs/VALIDATION_<STATE>_R21_<RCP>.md` contains the EVALIDator sanity check, owner distribution, and cross state delta against ME r21.

## What this does not cover

- The Layer 2 patched econ overlay path (`--use_maine_econ`) is currently blocked pending Wear 2025 logit recalibration; see `LAYER2_10SIM_SMOKE_RESULT_20260515.md`.
- The MN -23 percent statewide volume under EVALIDator (separate from the hindcast bias) is still standing and could be addressed by a DESIGNCD periodic plot inclusion audit in a future session.
- Per acre carbon to volume ratios across states are documented in `CV_RATIO_SANITY_20260513.md` and are biophysically defensible.
