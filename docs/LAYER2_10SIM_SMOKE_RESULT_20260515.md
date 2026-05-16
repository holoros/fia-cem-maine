# Layer 2 10 sim smoke: Wear 2025 logit recalibration needed before ME econ reruns

*Generated 15 May 2026. Resolves the question raised by the 1 sim Layer 2 smoke about whether the 83.7 percent cycle 1 harvest rate was variance or genuine calibration debt.*

## Headline

**It is genuine calibration debt, not variance.** A 10 sim ME BAU smoke with `--use_maine_econ` and the Layer 2 patched code produces cycle 1 harvest rate of 0.8359 with a tight confidence interval of [0.8342, 0.8367] across 10 sims. The result is essentially deterministic at this scale, ruling out the smoke artifact hypothesis from the 1 sim test.

## Implication

**Do not submit ME r21 econ reruns yet.** Submitting `submit_rcp45_wear_econ_r21.sh` and the RCP 8.5 sibling with the Layer 2 patch currently active would consume roughly 40 hours of compute to produce projections with 80+ percent annual harvest rates that contradict observed Maine harvest behavior (about 9 to 10 percent annual under BAU and 6 to 8 percent for non commercial private). The output would not be usable for the manuscript without further intervention.

## What happened

The Layer 2 patch documented in `GR_RATIO_LAYER2_AUDIT.md` removed a spurious `tpa_live` factor from `vol_removed_total` in `R/03_harvest_choice.R` line 409. The fix is mathematically correct: `volcfnet` is already cuft per acre from the aggregation in `R/01_data_prep.R` line 149, so multiplying by trees per acre again was a unit error inflating removal volume by roughly 400 to 600x for Maine.

Downstream of `vol_removed_total`, the Wear 2025 economic harvest logit consumes `removal_revenue = vol_removed_total * sawtimber_price + ...`. Before the patch, revenue per acre was inflated by the same 400 to 600x factor. The Wear 2025 logit intercept and `dVAL` coefficient were calibrated against published FIA per acre value distributions; with revenue 400 to 600x too high, the logit's decision boundary landed at an apparently reasonable harvest probability of about 9 to 10 percent.

After the patch, revenue is at the correct magnitude. The logit now sees revenue values within the range it was calibrated for, but the decision boundary has shifted such that almost every plot crosses the harvest threshold (logit > 0.5 maps to harvest in this implementation, and almost every economic value at the correct scale exceeds that threshold for the BAU scenario).

In other words: the prior bug had been compensating by accident for a Wear 2025 logit calibration issue that is now exposed.

## What needs to happen before econ reruns

Three candidate paths, in order of effort:

1. **Verify the Wear 2025 coefficients in `R/03_harvest_choice.R` lines 28 to 60.** Confirm they match Wear and Coulston (2025) Tables 1 and 2 exactly. If a coefficient was mistranscribed earlier, fixing it might shift the decision boundary back into the right range.

2. **Audit the `dVAL` term computation.** The Wear 2025 logit takes `dVAL` (the change in stand value between baseline and harvest year) as a key input. If `dVAL` is computed differently than Wear and Coulston used in their calibration (different volume aggregation, different prices, different time horizon), the coefficient calibration will not transfer.

3. **Recalibrate the Wear 2025 logit against observed Maine harvest panels.** Fit intercept and slope to match observed harvest rate of about 0.10 per cycle. This is a one to two day analytical task using FIA TREE_GRM_COMPONENT data.

Option 1 is the cheapest and worth trying first. Option 3 is the most defensible for the manuscript if the Wear 2025 published coefficients turn out to be the issue.

## Multistate runs are unaffected

The six p1 multistate production runs (MN, WA, GA × RCP 4.5 and RCP 8.5) all use `--no_econ` and `--skip_supply`, which bypass the Wear 2025 logit entirely. They use the fixed harvest rate branch at `cfg$harvest$use_fixed_harvest_rate = TRUE` with `--fixed_harvest_rate 0.10`. The Layer 2 patch does not affect these runs, and the validation work showing they PASS 8 of 8 across all six is unchanged.

The Layer 2 patch only matters for the ME r21 econ reruns and any future state level economic scenario work. Those reruns are now blocked pending the Wear 2025 logit investigation.

## Validation that the patch itself is correct

The Layer 2 patch fixes a real unit error. Two pieces of evidence:

1. The 1 sim smoke gr_ratio cycle 1 BAU jumped from 0.012 (pre patch, with bug) to 0.429 (post patch), a factor of 36. This matches the predicted recovery from the tpa_live inflation.
2. The 10 sim smoke confirms the patched gr_ratio is in the expected biological magnitude range and is reproducible (tight CI), so the patch is not introducing variance.

The patch is correct. The downstream consequence on Wear 2025 logit decisions is what needs further work.

## Recommendation: pivot the econ track

Hold the ME r21 econ reruns until the Wear 2025 logit investigation completes. Suggested sequence for the next session:

1. Check the Wear 2025 coefficients against the paper Tables 1 and 2 (Northeast region, comm/otherpr/public owners). Compare line by line. About 30 minutes.
2. If coefficients match, audit `dVAL` computation in `R/03_harvest_choice.R` around line 90 to 110. Compare to the Wear and Coulston (2025) methods text. About 2 hours.
3. If both check out, the logit needs recalibration. Build the FIA TREE_GRM_COMPONENT extraction for ME, fit intercept and dVAL slope to observed harvest rate. About 1 to 2 days.
4. Once the logit produces realistic harvest rates at the corrected revenue scale, submit ME r21 econ reruns.

In the meantime, the multistate p1 set is publishable as the non econ portion of the manuscript. The econ overlay results would be a separate Maine specific result that joins the manuscript later (or appears in a follow up paper) once the Wear 2025 calibration is resolved.
