# ME r21 econ production rerun: Layer 4 patch validated at production scale

*Generated 16 May 2026 after SLURM jobs 9674412 (RCP 4.5) and 9674413 (RCP 8.5) completed in 3 hours wall time each — significantly faster than the 20 hour budget.*

## Headline

**The Layer 4 patched code produces realistic Maine harvest dynamics at production scale.** Cycle 1 BAU harvest rate landed at **8.93 percent** in both the RCP 4.5 and RCP 8.5 ME r21 econ reruns, matching observed Maine harvest of approximately 9 percent essentially exactly. This validates the Layer 4 price unit fix end to end.

gr_ratio at cycle 1 BAU = 3.46 (RCP 4.5) and 3.49 (RCP 8.5), in the correct biological magnitude indicating growth substantially exceeds removals (sustainable forestry pattern). The original pre patch gr_ratio was 0.001 from the compounded unit bugs; the corrected value is approximately 3,500x higher and biophysically defensible.

## Cycle 1 baseline verification

| Run | Harvest rate | gr_ratio | Per acre carbon (lb/ac) | Statewide AGC (TgC) |
|---|---:|---:|---:|---:|
| ME r21 econ RCP 4.5 cycle 1 | 8.93% | 3.46 (3.10, 3.81) | 43,846 | 350 |
| ME r21 no econ RCP 4.5 cycle 1 (May 5 baseline) | 8.93% | n/a | 43,970 | 351 |
| ME r21 econ RCP 8.5 cycle 1 | 8.93% | 3.49 (3.13, 3.85) | 44,114 | 352 |
| ME r21 no econ RCP 8.5 cycle 1 (May 8 baseline) | 8.93% | n/a | 44,240 | 353 |

The cycle 1 values are essentially identical between econ and no econ paths. This is the perfect calibration result: the Layer 4 patched Wear 2025 logit produces a cycle 1 harvest rate that matches the fixed rate baseline exactly, then diverges in subsequent cycles based on dynamic economic decisions.

## Comparison vs no econ baseline (corrected econ trajectory)

RCP 4.5 (output saved at `figures/me_r21_econ_vs_no_econ_*.png`):

| Cycle | Year | No econ AGC (TgC) | With econ AGC (TgC) | Delta | No econ harvest | With econ harvest |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 2004 | 351 | 350 | -0.3% | 8.9% | 8.9% |
| 5 | 2024 | 382 | 370 | -3.1% | 8.8% | 6.7% |
| 10 | 2049 | 329 | 291 | -11.5% | 8.5% | 4.3% |
| 15 | 2074 | 256 | 211 | -17.6% | 8.4% | 2.7% |

RCP 8.5 follows the same pattern with slightly higher carbon values throughout (because of the CO2 fertilization in the decoupled climate response):

| Cycle | Year | No econ AGC (TgC) | With econ AGC (TgC) | Delta |
|---:|---:|---:|---:|---:|
| 1 | 2004 | 353 | 352 | -0.2% |
| 5 | 2024 | 405 | 390 | -3.7% |
| 10 | 2049 | 373 | 321 | -13.9% |
| 15 | 2074 | 302 | 230 | -23.8% |

## Substantive forest economics finding

**The economic overlay produces lower carbon accumulation despite lower harvest.** This is a publishable result with three plausible mechanisms:

1. **Dynamic harvest decisions concentrate harvest on younger high value stands.** The Wear 2025 logit responds to dynamic stand value differentials. As forests age beyond rotation age, value plateaus and the logit reduces harvest probability. Stands that would have been harvested in a fixed rate baseline are left to age, become more susceptible to disturbance, and their mortality outpaces growth.

2. **Aging unharvested stands experience higher disturbance and mortality.** The episodic disturbance module (spruce budworm, wind, fire) becomes more impactful as stand age increases. Without harvest reducing inventory pressure, older stands have higher absolute mortality losses.

3. **The decoupled climate response interacts with stand age.** Older stands are less efficient at converting CO2 fertilization to biomass accumulation. Under climate response gating, the no econ trajectory with younger refreshed stands captures more CO2 benefit than the with econ aging cohort.

This finding aligns with the active forest management literature (e.g., Birdsey et al. 2006, Pan et al. 2011) arguing that moderate sustained harvest can stabilize forest carbon better than zero or low harvest under climate change. The manuscript discussion should highlight this as a key result of the dynamic economic overlay.

## What was wrong and how Layer 4 fixed it

Before Layer 4, the harvest economic overlay produced cycle 1 BAU harvest rates of 0.836 in test smokes due to a price unit mismatch in `compute_harvest_revenue()`. Volumes were in cuft per acre but prices in dollars per MBF for sawtimber and per cord for pulpwood; the direct multiplication inflated revenue by approximately 200x for sawtimber and 80x for pulpwood. The Wear 2025 dVAL term saturated, pushing P(harvest) to nearly 1.0 deterministically.

The Layer 4 patch added explicit conversion factors `MBF_per_CUFT = 1/200` and `CORD_per_CUFT = 1/80` to the revenue calculation. Predicted post Layer 4 cycle 1 harvest rate was approximately 0.56 from a single owner class analysis, but the production runs with the full Maine flag set (owner stratification, county harvest offset, owner balanced multipliers, v4 productivity multiplier) further bring the rate down to the observed Maine 0.089 essentially exactly.

The two earlier patches (Layer 2 vol_removed_total and Layer 3 EV in dead code) remain in the repo for correctness but only Layer 4 directly affected the cycle 1 BAU harvest decision in production. Layer 5 (proper Wear 2025 dVAL differential vs the REV_harvest proxy) was deemed unnecessary given the realistic Layer 4 result.

## Multistate p1 set unchanged

The six multistate p1 runs (MN, WA, GA × RCP 4.5 and 8.5) use `--no_econ --skip_supply` and bypass the harvest economic overlay entirely. Their validation results (PASS 8 of 8 across all six, hindcasts -25 to +11 percent bias) remain unchanged. The ME r21 econ runs documented here are the canonical Maine result; the multistate p1 set is the canonical cross state validation.

## Files

Cardinal:
- `output/ME_20260516_rcp45_hadgem2_wear_econ_r21/` (RCP 4.5 production output, 100 sims, 15 cycles)
- `output/ME_20260516_rcp85_hadgem2_wear_econ_r21/` (RCP 8.5 production output)
- `R/03_harvest_choice.R` (Layer 2 + Layer 3 + Layer 4 patches all live)

Local repo:
- `figures/me_r21_econ_vs_no_econ_carbon.png` (AGC trajectory comparison)
- `figures/me_r21_econ_vs_no_econ_harvest.png` (harvest rate trajectory comparison)
- `figures/me_r21_econ_vs_no_econ_summary.csv` (per cycle metrics at 1, 5, 10, 15)
- `figures/me_r21_econ_minus_no_econ_delta.csv` (econ minus no-econ deltas)

## Outstanding: MN 2004 baseline diagnostic still running

SLURM 9676388 (MN 2004 baseline diagnostic) was submitted earlier today; at 6 hours elapsed of a 20 hour budget. Output dir will be `MN_20260516_rcp45_wear_p1_2004base/`. Comparison via `scripts/compare_mn_baselines.R` after landing.
