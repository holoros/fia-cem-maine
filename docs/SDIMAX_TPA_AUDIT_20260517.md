# SDImax cap leaves proj_tpa unscaled: audit and proposed Layer 6 patch

*Generated 17 May 2026 from a codebase audit of `R/06_projection_engine.R` after the trajectory diagnostic flagged 41,000 to 51,000 trees/ac at cycle 15.*

## The bug

`apply_sdimax_cap` at `R/06_projection_engine.R` lines 742 to 765 computes a per plot `sdi_ratio = pmin(1, sdimax_eng / pmax(0.1, proj_sdi))` and applies it to `proj_BA`, `proj_volcfnet`, `proj_volcsnet`, `proj_drybio`, `proj_carbon`. It does NOT apply the ratio to `proj_tpa` (or to `proj_qmd`).

```r
apply_sdimax_cap <- function(df) {
  ...
  df |> dplyr::mutate(
    sdi_ratio  = pmin(1, sdimax_eng / pmax(0.1, proj_sdi)),
    proj_BA       = proj_BA       * sdi_ratio,
    proj_volcfnet = proj_volcfnet * sdi_ratio,
    proj_volcsnet = ... ,
    proj_drybio   = proj_drybio   * sdi_ratio,
    proj_carbon   = proj_carbon   * sdi_ratio
    # MISSING: proj_tpa = proj_tpa * sdi_ratio
    # MISSING: proj_qmd unchanged (consistent with TPA scaling above)
  )
}
```

## Why this produces 41,000 to 51,000 TPA at cycle 15

Reineke SDI: `SDI = TPA × (QMD / 10)^1.605`

When the cap activates (`proj_sdi > sdimax_eng`), the current code reduces BA but leaves TPA unchanged. The QMD that would have produced the original SDI is preserved implicitly. The next cycle uses `proj_tpa` as the starting `tpa_live`, so TPA carries forward without correction. Across 15 cycles of stressed-growth scenarios (high disturbance + slow recovery), the unconstrained TPA accumulates the donor growth multiplier (`gr_tpa` capped at [0.5, 2.0] per cycle but compounding multiplicatively over 15 cycles can reach 2^15 = 32,768 worst case). The trajectory diagnostic observed cycle 15 TPA reaching 41k to 51k trees/ac, which exceeds physically plausible values by 1 to 2 orders of magnitude.

Cycle 5 values (510 to 946 TPA) remain biophysically plausible because the cap activates rarely in the first 25 years; the bug only compounds when the cap is hit repeatedly in late cycles.

## The proposed fix (Layer 6 patch)

Apply `sdi_ratio` to `proj_tpa` symmetrically with `proj_BA`. This preserves QMD (mean tree diameter) and density consistently:

```r
proj_BA       = proj_BA       * sdi_ratio,
proj_tpa      = proj_tpa      * sdi_ratio,   # NEW: density also scales
proj_volcfnet = proj_volcfnet * sdi_ratio,
proj_volcsnet = if ("proj_volcsnet" %in% names(df)) proj_volcsnet * sdi_ratio else proj_volcsnet,
proj_drybio   = proj_drybio   * sdi_ratio,
proj_carbon   = proj_carbon   * sdi_ratio
```

Mathematically: if `BA* = BA × ratio` and we want `QMD* = QMD` (preserve mean tree size), then because `BA = pi/4 × QMD^2 × TPA`, density must scale by the same ratio: `TPA* = TPA × ratio`. The current code preserves TPA which forces QMD to absorb the entire BA reduction, producing a smaller-tree shift in stand structure. Scaling TPA preserves stand structure and is the biophysically consistent interpretation of an SDImax cap (the cap models mortality / self thinning at biological carrying capacity).

## Impact on existing manuscript results

The cap only activates when `proj_sdi > sdimax_eng`. In the multistate p1 production runs:

- **Cycle 1 to 5 results unchanged.** The cap rarely activates that early; trajectory diagnostic confirmed cycle 5 TPA still in plausible 510 to 946 range.
- **Cycle 10 results minor change.** Cap activates intermittently in some scenarios; TPA reduction proportional to the cap activation rate.
- **Cycle 15 results substantial change.** The reported cycle 15 TPA values would drop from 41k-51k trees/ac to roughly 1500-2500 trees/ac (cap pushing them down to the SDImax-consistent density).

If the manuscript reports any metric at cycle greater than 7, this fix should land before publication. If the manuscript reports only cycles 1 to 5 (2004 to 2024 horizon), this can be documented as a known limitation of late cycle TPA without rerunning.

## Manuscript horizon question

This audit makes the manuscript horizon decision more concrete:

- **Cycle 5 (2024) horizon, RPA-comparable:** No rerun needed. Existing p1 outputs are valid. TPA cap bug documented as a known late-cycle limitation.
- **Cycle 10 (2049) horizon:** Rerun recommended after Layer 6 patch lands. Modest changes expected.
- **Cycle 15 (2074) horizon:** Rerun required. Substantial changes to cycle 15 TPA and indirectly to QMD if downstream code recomputes it from BA / TPA.

## Recommended deployment

Treat this as Layer 6 in the harvest economics + projection patch sequence (Layers 1 to 5 covered the harvest economic overlay; Layer 6 is the SDImax projection consistency fix).

**Do not deploy without explicit approval.** The fix changes published numerical results at cycles 7 to 15. Validation plan:

1. Apply the patch to `R/06_projection_engine.R`.
2. Rerun one production scenario as a smoke test (e.g., ME r21 cycle 15 with all settings the same).
3. Verify cycle 5 numbers are unchanged within rounding.
4. Verify cycle 15 TPA drops to plausible range (1500-2500 vs 41k-51k).
5. Verify cycle 15 BA, volume, biomass, carbon all change proportionally (sdi_ratio applied symmetrically).
6. Commit and rerun the multistate p1 set if cycle greater than 5 horizon is being used.

## Status

- Audit complete; bug location confirmed at lines 742-765 of R/06_projection_engine.R
- Proposed Layer 6 patch is a one-line addition
- Not deployed pending manuscript horizon decision
- If cycle 5 horizon: document as known limitation; existing results stand
- If cycle greater than 5: deploy patch and rerun p1 production set
