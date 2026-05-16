# Layer 4 patch: price unit mismatch in compute_harvest_revenue

*Generated 15-16 May 2026 after reading R/03_harvest_choice.R lines 145-260 to locate the active dVAL site.*

## The bug, fourth and likely final layer

`predict_harvest_probability()` at R/03 line 257 sets `dVAL = REV_harvest` directly as a Wear and Coulston (2025) proxy. `REV_harvest` is computed in `compute_harvest_revenue()` (line 74, R/03) by multiplying per acre cubic foot volumes against price defaults defined in R/00_config.R lines 112-120:

```r
base_prices = list(
  sawtimber = list(softwood = 250, hardwood = 350),  # $/MBF
  pulpwood  = list(softwood = 12,  hardwood = 10)    # $/cord
)
```

The volumes (`vol_sawtimber_softwood`, etc.) are in **cuft per acre** from the aggregation at R/01 line 178 (`tree_vol = TPA_UNADJ * VOLCFNET`). The prices are documented as **$/MBF** for sawtimber and **$/cord** for pulpwood. Multiplying cuft directly by $/MBF inflates revenue by approximately 200x (1 MBF ≈ 200 cuft of merchantable volume, International 1/4 inch scale), and multiplying cuft by $/cord inflates by approximately 80x (1 cord ≈ 80 cuft of solid pulpwood volume).

For a typical mature Maine stand with 1,500 cuft/ac of softwood sawtimber:
- Pre Layer 4: 1500 × $250/MBF (treated as $/cuft) = $375,000/ac REV_harvest
- Post Layer 4: 1500 × (1 MBF / 200 cuft) × $250/MBF = $1,875/ac REV_harvest

The Wear 2025 dVAL coefficient is 0.0017 (Northeast region, otherpr). Pre Layer 4 logit term: 0.0017 × 375,000 = 638, which saturates the logistic transform to P(harvest) ≈ 1.0. Post Layer 4 logit term: 0.0017 × 1,875 = 3.2. With Northeast otherpr intercept of -1.78, total xb = 1.44, giving P(harvest) ≈ 0.81. Still high but no longer at the deterministic saturation.

## The patch

```r
# Pre Layer 4:
rev_sawtimber = vol_sawtimber_softwood * prices$sawtimber$softwood + ...

# Post Layer 4:
MBF_per_CUFT  <- 1 / 200
CORD_per_CUFT <- 1 / 80
rev_sawtimber = vol_sawtimber_softwood * MBF_per_CUFT * prices$sawtimber$softwood + ...
rev_pulpwood  = vol_pulpwood_softwood * CORD_per_CUFT * prices$pulpwood$softwood + ...
```

Applied to `R/03_harvest_choice.R` line 74-91. Deployed to Cardinal with backup at `R/03_harvest_choice.R.preupdate.20260516_layer4`. Verification smoke submitted as SLURM job 9671919.

## Predicted Layer 4 smoke outcome

- Cycle 1 BAU harvest rate: somewhere in 40 to 80 percent range (still high but not deterministic)
- This may not match observed Maine 10 percent because dVAL is still computed as REV_harvest rather than the proper Wear 2025 differential `REV + delta * (EV_h - EV_nh)`. The "simplified using revenue as proxy" comment at line 257 reveals this is a placeholder shortcut. A future Layer 5 patch could implement the proper differential.

If the Layer 4 smoke harvest rate lands in the 20-50% range, it's a meaningful improvement over the saturation, and the manuscript can report Layer 4 as the key calibration fix.

If still 70+%, the next investigation step is implementing the proper Wear 2025 dVAL differential rather than the revenue proxy.

## Hierarchy of Wear 2025 logit corrections, in summary

| Layer | Site | Status | Effect on harvest rate |
|---|---|---|---|
| 1 | R/06 line 922 (gr_ratio units) | Live, applied (prior session) | Fixes gr_ratio reporting, not harvest |
| 2 | R/03 line 409 (vol_removed_total tpa_live) | Live, applied | Cycle 2+ revenue feedback |
| 3 | R/03 line 108 (EV tpa_live) | Dead code, patch inert but correct | None observed |
| **4** | **R/03 line ~80 (REV cuft/MBF/cord mismatch)** | **Live, applied today** | **Direct on cycle 1 dVAL → P(harvest)** |
| 5 | R/03 line 257 (dVAL as REV proxy) | Pending; would replace proxy with proper Wear 2025 differential | Potentially large if 5-10x reduction in dVAL |

## Multistate p1 set still unaffected

The six p1 multistate runs use `--no_econ --skip_supply` which bypasses `predict_harvest_probability()` (and thus all four layer patches) entirely. Their validation status of PASS 8 of 8 across all six runs with -25 to +11 percent hindcast bias is unchanged.

## Status at this writing

- Layer 4 patch applied at R/03 lines 74-91
- Backup preserved at R/03_harvest_choice.R.preupdate.20260516_layer4
- Layer 4 verification smoke running as SLURM job 9671919 (10 sims, 5 cycles, ME, --use_maine_econ)
- Smoke expected to land in 30 to 60 minutes
- ME r21 econ reruns still on hold pending Layer 4 verification

## Methodological note for the manuscript

The harvest economic overlay turned out to contain four distinct unit and scaling errors discovered in sequence as the symptom of one (the gr_ratio reporting collapse) led to investigation of the next:
- Layer 1: gr_ratio reporting units (unrelated to harvest decision)
- Layer 2: vol_removed_total per acre conversion (live code, fixed)
- Layer 3: EV per acre conversion (dead code, fixed for consistency)
- Layer 4: REV unit mismatch ($/MBF vs cuft) (live code, fixed today)

The chain reveals that the economic harvest overlay required a careful unit audit at every interface. This experience is publishable as a worked example of multi component projection pipeline validation. Future implementations should adopt the units R package or similar to make unit handling explicit at every multiplication.
