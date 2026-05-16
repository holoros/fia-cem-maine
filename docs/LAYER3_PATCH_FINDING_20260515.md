# Layer 3 patch: same tpa_live bug at EV computation, line 108

*Generated 15 May 2026. Discovered during the Wear 2025 logit audit that the user requested as a follow up to the Layer 2 10 sim smoke finding.*

## Discovery

Code review of `R/03_harvest_choice.R` around the Wear 2025 economic harvest logit revealed that `compute_ending_value()` at line 108 contains the **same `tpa_live` double counting bug** that the Layer 2 patch fixed at line 409.

```r
# R/03_harvest_choice.R line 99 to 108 (pre Layer 3):
compute_ending_value <- function(cond_data, prices, harvested) {

  cond_data |>
    mutate(
      # Ending value is volume at time 2 * prices
      EV = coalesce(T2_volcfnet, volcfnet) * (
        prices$sawtimber$softwood * 0.5 + prices$pulpwood$softwood * 0.5
      ) * tpa_live           # <-- BUG: T2_volcfnet is already per acre
    )
}
```

`T2_volcfnet` is built in `R/01_data_prep.R` line 149 via `sum(TPA_UNADJ * VOLCFNET)`, where `TPA_UNADJ` is the FIA expansion adjustment factor multiplied by `VOLCFNET` per tree to give per acre net volume. The aggregated `T2_volcfnet` is therefore in cuft/ac. Multiplying by `tpa_live` (trees per acre) gives cuft·trees per acre squared, the same unit error as line 409.

## Why this explains the Layer 2 10 sim smoke result

The 10 sim ME BAU smoke under `--use_maine_econ` with the Layer 2 patch produced cycle 1 harvest rate of 0.8359, tight CI across sims. The Layer 2 patch fixed `vol_removed_total` so `REV_harvest` is now at correct per acre magnitude (about $1,500 to $3,000 per acre for mature Maine sawtimber stands). But `EV` is still inflated by the Layer 3 bug (tpa_live ~400 to 600 for Maine), so `EV` runs around $500,000 to $1,500,000 per acre instead of $1,000 to $3,000.

`dVAL` from `compute_dval` is `abs(REV_harvest + delta * (EV_harvest - EV_noharvest))`. The EV term dominates dVAL at inflated scale; dVAL lands at roughly $400,000 to $1,000,000 per acre instead of about $200 to $500 per acre.

The Wear 2025 logit term is `dVAL_coef * dVAL = 0.0017 * dVAL`. With dVAL at the inflated scale, the logit term reaches several hundred, saturating P(harvest) at near 1.0. Adding the typical Northeast intercept of -1.78 and other terms cannot pull this back. Observed result: 83.6 percent cycle 1 harvest, exactly as the 10 sim smoke showed.

After the Layer 3 patch removes `* tpa_live` from line 108, dVAL drops to approximately:

- REV_harvest: ~$2,000 per acre for a mature stand
- delta (4 percent discount, 5 year remper): 0.822
- EV_harvest: ~$50 per acre (regen)
- EV_noharvest: ~$2,200 per acre (standing timber at year 5)
- dVAL = abs(2000 + 0.822 * (50 - 2200)) = abs(2000 - 1767) = $233 per acre

Logit term: 0.0017 * 233 = 0.40. With intercept -1.78, total = -1.38, giving P(harvest) = 0.20.

Statewide BAU average should land in the 10 to 20 percent range, consistent with observed Maine harvest of about 10 percent per cycle. The Layer 3 patch should resolve the 83 percent observation.

## What I did

1. **Verified the bug.** Pulled live `R/03_harvest_choice.R` from Cardinal, confirmed line 108 contains `* tpa_live`.
2. **Applied the patch** locally. Removed `* tpa_live`, added a clarifying comment block, retained the per acre EV magnitude.
3. **Deployed to Cardinal** with backup at `R/03_harvest_choice.R.preupdate.20260515_layer3`.
4. **Submitted a Layer 3 verification smoke** as SLURM job 9669294 (10 sims, 5 cycles, ME, `--use_maine_econ`). Expected to land in ~60 minutes. Output dir: `ME_<date>_layer3_smoke_20260515/`.

Expected outcome from job 9669294:
- Cycle 1 BAU harvest rate: 10 to 20 percent (was 83.6 percent under Layer 2)
- gr_ratio cycle 1 BAU: 0.5 to 2.0 (was 0.425 under Layer 2; should rise slightly because harvest_removals drops proportionally with the corrected `vol_removed_total` from Layer 2, but actually Layer 2 already fixed vol_removed_total, so gr_ratio should not change much from the Layer 2 baseline of 0.43)

If the Layer 3 smoke produces realistic harvest rates, the path to ME r21 econ reruns is open. If harvest rates are still well above observed Maine 10 percent, additional Wear 2025 logit investigation is needed.

## What the multistate p1 set does NOT need

The Layer 3 patch (like the Layer 2 patch) only affects the `--use_maine_econ` code path. The six p1 multistate runs use `--no_econ` and `--skip_supply`, which bypass `compute_ending_value()` entirely. The multistate p1 validation work is unchanged.

## Methodological reading

The Layer 2 and Layer 3 patches together constitute a "lb / per acre / per tree" audit of the harvest economic overlay. The original code had two parallel tpa_live inflation errors:

- Line 409: `vol_removed_total` over counted tpa_live (fixed by Layer 2)
- Line 108: `EV` over counted tpa_live (fixed by Layer 3)

The two bugs were compensating in a perverse way: line 409 inflated removed volume (and hence post harvest revenue prediction), line 108 inflated standing value, and the Wear 2025 logit's decision boundary happened to land at a roughly realistic 10 percent harvest rate by coincidence. Layer 2 alone breaks the coincidence; Layer 2 + Layer 3 should restore realistic dynamics at correct units throughout.

## Open questions

1. Are there other tpa_live bugs in the codebase I haven't audited? A grep for `* tpa_live` across R/ would catch them.
2. Are the FIA volume columns vol_sawtimber_softwood etc. (used in REV_harvest) also in per acre units? If they're per condition aggregated differently from T2_volcfnet, there could be a third inflation. Worth a quick check during the next Wear 2025 logit audit pass.
3. After Layer 3 lands, does the manuscript methods text need to reflect that the harvest economic overlay was audited and corrected? Probably yes, as a brief paragraph in methods or appendix.

## Status at handoff

- Layer 3 patch applied to `R/03_harvest_choice.R` lines 99 to 108
- Backup preserved at `~/fia_cem_projections/R/03_harvest_choice.R.preupdate.20260515_layer3`
- Layer 3 verification smoke running as SLURM 9669294
- Layer 2 10 sim smoke complete (decisive: 83.6 percent harvest rate, confirms Layer 3 is needed)
- ME r21 econ reruns continue to be blocked pending the Layer 3 smoke result
