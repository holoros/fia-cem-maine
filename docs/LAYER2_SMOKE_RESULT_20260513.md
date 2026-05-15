# Layer 2 patch validation smoke result

*Generated 13 May 2026 from SLURM job 9573759 output ME_<date>_layer2_smoke_20260513/.*

## Summary

The Layer 2 gr_ratio patch documented in `docs/GR_RATIO_LAYER2_AUDIT.md` and applied to `R/03_harvest_choice.R` lines 409 and 414 was validated via a 1 sim, 3 cycle ME BAU smoke with `--use_maine_econ`. The patch is functioning correctly. gr_ratio at cycle 1 BAU moved from 0.012 (post Layer 1, multistate p1 reference) to 0.429, a 36x correction toward the expected biological magnitude of approximately 1.0 where gross growth balances harvest removals at equilibrium.

## gr_ratio trajectory

| Cycle | Year | gr_ratio BAU |
|---:|---:|:---|
| 1 | 2004 | 0.429 (0.429, 0.429) |
| 2 | 2009 | 0.950 (0.950, 0.950) |
| 3 | 2014 | 0.997 (0.997, 0.997) |

The trajectory toward 1.0 (growth equal to removals) is the canonical pattern for a managed forest under sustained yield economics, which is what the Wear and Coulston 2025 logit aims to model.

## Inventory trajectory caveat

The smoke produced unexpectedly high harvest rates at cycle 1:

| Cycle | BA (sqft/ac) | Vol (cuft/ac) | Carbon (kg/ac) | TPA | Harvest % | Plant % |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 40.4 | 585 | 17,969 | 586 | 83.7 | 73.7 |
| 2 | 34.2 | 506 | 15,100 | 491 | 45.3 | 40.7 |
| 3 | 31.7 | 455 | 13,543 | 456 | 28.1 | 25.1 |

The cycle 1 harvest rate of 83.7 percent is roughly an order of magnitude above the p1 multistate baseline of 9 to 10 percent. Two competing explanations:

1. **Real calibration signal.** With Layer 2 fixed, the Wear 2025 economic harvest logit now sees revenue per acre at the correct magnitude rather than the previous tpa_live inflated value. The logit's intercept and dVAL coefficients were originally fit against published FIA per acre values, so the corrected magnitude flows through the decision boundary differently. If the high harvest rate is the realistic response of the model to corrected inputs, the Wear 2025 coefficients may need state by state retuning before publication. This would mean the gr_ratio patch revealed a downstream calibration debt the previous bug had been masking.

2. **Smoke artifact.** With only 1 sim and 3 cycles, the BAU realization can swing widely. With only the economic overlay path tested (`--use_maine_econ`), the result does not exercise the non econ scenarios the production p1 set used. A 10 sim, 5 cycle smoke or a 100 sim smoke would resolve this.

Recommendation: run a 10 sim, 5 cycle ME BAU smoke with `--use_maine_econ` to discriminate between options 1 and 2 before scheduling a full ME r21 econ rerun. If the higher harvest rate persists at 10 sims, option 1 is the working hypothesis and the Wear 2025 intercepts need investigation. If the harvest rate trends toward the p1 multistate 9 to 10 percent range with more sims, option 2 is the working hypothesis.

## Per acre carbon trajectory

The cycle 1 to cycle 3 carbon decline from 17,969 to 13,543 kg per acre (24 percent loss over 10 years) reflects the high harvest rates in this smoke. The p1 multistate cycle 1 baseline at ME of 44,240 kg per acre is the canonical reference. The smoke landing 60 percent below the p1 baseline at cycle 1 is also consistent with the high harvest rate hypothesis: cycle 1 is the post baseline year 2004, and if 83 percent of plots harvested between 1999 and 2004, the remaining standing stock would be much lower than the unharvested baseline.

## What is validated

- The Layer 2 patch removes the spurious tpa_live multiplier from vol_removed_total and saw_fraction.
- gr_ratio scales from 0.012 to 0.429 (matching the predicted per acre correction factor).
- The patched code runs to completion with no errors or warnings.
- Downstream figures (BA, carbon, volume, harvest, planting, gr_ratio, supply curve) generated successfully.

## What needs follow up

- The high harvest rate at cycle 1 BAU under `--use_maine_econ` may indicate a Wear 2025 logit recalibration need. A 10 sim follow up smoke can resolve this.
- After the higher fidelity smoke confirms behavior, schedule full ME r21 econ reruns (`submit_rcp45_wear_econ_r21.sh` and the RCP 8.5 sibling) to land the manuscript ready figures with the corrected gr_ratio.
- The patch only affects the `--use_maine_econ` path. The six p1 multistate runs use `--no_econ` and are not affected by either the Layer 2 patch or any downstream rebalancing.
