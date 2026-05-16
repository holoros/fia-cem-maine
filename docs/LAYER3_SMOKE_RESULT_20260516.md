# Layer 3 verification smoke: patch correct but does not affect harvest rate

*Generated 15 May 2026 evening. Reports the Layer 3 verification smoke result and reframes the Wear 2025 logit investigation.*

## Headline

The Layer 3 patch at `R/03_harvest_choice.R` line 108 fixes a real `tpa_live` unit error in `compute_ending_value()`, but the verification smoke shows it does NOT change the cycle 1 BAU harvest rate. Layer 3 smoke harvest rate = 0.836 with CI [0.834, 0.838]; Layer 2 only smoke harvest rate was 0.836 with CI [0.834, 0.837]. Essentially identical.

## Implication

`compute_ending_value()` at line 108 is not on the active code path that drives the harvest decision under `--use_maine_econ`. The function exists in the codebase but is dead code (or executed but its output is overwritten downstream). The Wear 2025 logit must be computing dVAL through a different path.

## Where to look next (refined after grep audit)

A grep across R/ and scripts/ confirmed that `compute_ending_value()` is defined at `R/03_harvest_choice.R` line 99 but **never called anywhere**. The Layer 3 patch fixed a real unit error in dead code. By contrast, `estimate_removals()` (Layer 2 patch site at line 411) IS called from R/06 line 394 and R/07 line 37, and `predict_harvest_probability()` (line 145) IS called from R/06 line 221 and R/07 line 31.

The active cycle 1 harvest decision must come from inside `predict_harvest_probability()`, which is the function that produces the harvest probability per plot. Its dVAL computation is presumably inline rather than via the dedicated `compute_dval()` helper (which is also never called per a quick grep). Reading line 145 forward should reveal the actual dVAL formula.

Updated reading order for next session:

1. **`R/03_harvest_choice.R` lines 145 through 400** in `predict_harvest_probability()`. Find the inline dVAL or revenue computation. This is the live code that produces the 0.836 cycle 1 BAU harvest rate.
2. If dVAL is constructed from `compute_harvest_revenue()` output plus an inline EV proxy, verify the EV proxy is per acre.
3. If the function uses `T2_volcfnet` or similar columns directly, verify they're per acre (they are per our R/01 audit).
4. After identifying the active site, decide whether a Layer 4 patch is needed or whether the Wear 2025 coefficients themselves need recalibration against Maine harvest panels.

`R/11_economic_harvest.R` is a separate module for partial clearcut splitting and county stumpage overlay; based on the grep it does not contain dVAL or the core harvest decision.

## What the Layer 3 patch is still useful for

The Layer 3 fix removes a unit error from `compute_ending_value()`. Even if the function is dead code in the multistate p1 set, the patch is still correct because:
- It will matter if `compute_ending_value()` is ever called in a future code path (manuscript replication, alternate scenarios)
- It documents the per acre convention consistently across the harvest economics module
- It removes a confusing reference point for future code review

The patch should stay in the repo. The Layer 2 patch at line 409 is presumably similarly orphaned, since the multistate p1 set passing 8/8 validation strongly suggests neither line 108 nor line 409 affects the production code path that produced those numbers.

## What this means for the manuscript

The Wear 2025 logit calibration debt is still real and still blocks ME r21 econ reruns, but the actual code site that needs investigation has moved. The methodological note in `manuscript/MULTISTATE_METHODS_DRAFT_20260515.md` Section X.3 about the two `tpa_live` errors compensating each other was likely overstated. The true mechanism appears to be: the harvest decision uses a third independent dVAL implementation, somewhere in R/06 or R/11, that we have not yet located.

The unit bug story is unchanged for the analysis tooling (my hindcast script and validation template): those were real bugs and the fix was the right one. But the bug story is now WEAKER for the projection code, since the supposed "two compensating bugs" in `R/03` don't drive the harvest rate.

## Recommended next session sequence

1. Read `R/11_economic_harvest.R` top to bottom; document its dVAL formulation
2. Grep R/06 for dVAL and economic terms
3. Identify the active dVAL site
4. Verify the active site's per acre dVAL is in correct units
5. If correct, the 83 percent harvest rate is a Wear 2025 coefficient calibration issue, not a unit error
6. If incorrect, apply a Layer 4 patch
7. After Layer 4 (or a confirmed calibration finding), schedule ME r21 econ reruns

## Hold on the manuscript methods text

Revise the `manuscript/MULTISTATE_METHODS_DRAFT_20260515.md` Section X.3 "Methodological note on unit handling" once the active dVAL site is located. The narrative about Layer 2 and Layer 3 compensating each other was speculative; rewrite once the real harvest decision pathway is identified.

## Multistate p1 outputs unchanged

The six p1 multistate runs use `--no_econ` and `--skip_supply` which bypass the entire harvest economics module. Nothing in this finding affects them. Their validation status (PASS 8 of 8) and hindcast performance (-25 to +11 percent bias across states) is unchanged.
