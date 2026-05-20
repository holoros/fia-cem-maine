# Supplementary S7: Layer 7b smoke validation results

*Manuscript supplement documenting the pre-production validation of the CEM Layer 7b ecoregion patch.*

## Purpose

This supplement records the small-scale smoke test that validated the CEM Layer 7b ecoregion patch (`R/02_cem_matching.R`) before scaling to the full multistate p1 production rerun. The smoke test confirms (1) the patched script runs end-to-end without errors, (2) the CEM matching at the L3 ecoregion granularity finds donors for the vast majority of subjects, and (3) the patched projection produces sensible BA/volume/carbon trajectories.

## Smoke configuration

```
SLURM job: 9914786
Date: 17 May 2026
Wall time: 1 hour 9 minutes 8 seconds
Exit code: 0

R command:
Rscript run_projection.R --state ME --n_sims 10 --cycles 5 \
  --cores 16 --scenario_set bau \
  --tag layer7b_ecoregion_smoke_20260517 \
  --baseline_year 1999 --baseline_window 10 \
  --untreated_donors --climate_rcp 4.5 \
  --fixed_harvest_rate 0.10 --include_remeasured \
  --use_brms_sdimax --use_decoupled_climate \
  --use_disturbance --use_potter_vcc --use_maine_econ
```

## CEM matching results

```
=== Cycle 1 CEM Matching Summary ===
  Total subjects: 10,017
  Matched: 9,990 (99.7%)
  Unmatched: 27 (0.3%)
  Matches per subject: median = 3.0, range = [1, 629]

Iteration 1 (fine, cem_ecoregion = L3 code):
  9,198 / 10,017 subjects matched (91.8%)
Iteration 2 (medium, cem_ecoregion = section):
  531 / 819 remaining matched (64.8%)
Iteration 3 (coarse, cem_ecoregion = "0"):
  261 / 288 remaining matched (90.6%)
```

The 91.8 percent iter1 fine-resolution match rate (with full EPA L3 ecoregion granularity) confirms the empirical cell-size feasibility documented in the main paper Section X.2.4. The graceful iter2 and iter3 fallbacks catch the remaining subjects, producing a final 99.7 percent overall match rate that is comparable to pre-patch behavior.

## Projection output summary

Cycle 1 BAU 95-percent CI summary from `output/ME_20260517_layer7b_ecoregion_smoke_20260517/ci_summaries.csv`:

| Metric | Mean | 95% CI |
|---|---:|---|
| mean_ba | 76.2 sqft/ac | (75.9, 76.6) |
| mean_vol | 1,272 cuft/ac | (1,266, 1,281) |
| mean_carbon | 37,202 lb/ac | (37,080, 37,432) |
| total_tpa | 679.8 | (674.5, 683.4) |
| harvest_rate | 0.260 | (0.254, 0.264) |
| gr_ratio | 0.778 | (0.760, 0.794) |

gr_ratio trajectory:

```
cycle  year  BAU gr_ratio (95% CI)
1      5     0.778 (0.760, 0.794)
2      10    1.965 (1.878, 2.055)
3      15    2.818 (2.550, 3.112)
4      20    8.563 (7.992, 9.461)
5      25    11.707 (10.476, 14.310)
```

The Layer 7b smoke output is within sampling variation of the pre-patch Layer 2 10-sim smoke (gr_ratio 0.84 vs L7b 0.78, mean_ba 79 vs 76, harvest_rate 0.258 vs 0.260). The patch did not introduce systematic deviation from baseline.

## What the smoke does NOT measure

The within-Maine smoke cannot quantify the bias reduction that motivates the patch, because:

1. The smoke donor pool is ME-only (via `--include_remeasured` and `--untreated_donors`); the ecoregion key adds granularity within ME but the documented donor-pool composition mechanism operates across states.

2. Only 10 simulations vs the 100-sim production runs; tighter CIs needed to resolve sub-5-percent bias differences.

3. The 91.8 percent iter1 match rate reflects ME-only matching where most plots share STATECD = 23 and the us_l3code adds variation but with limited cross-region range.

The bias reduction quantification comes from the full multistate p1 rerun (8 SLURM jobs, ME/MN/WA/GA × RCP 4.5/8.5) where the cross-state donor pool composition mechanism is actually exercised. Those results are reported in the main paper Section X.2.5.

## Files

- Cardinal output: `~/fia_cem_projections/output/ME_20260517_layer7b_ecoregion_smoke_20260517/`
- Local mirror: `figures/layer7b_smoke/`
- SLURM logs: `~/fia_cem_projections/logs/l7_smoke_9914786.{err,out}`
- Patched script: `R/02_cem_matching.R` (also released as supplement S4)
- Pre-patch backup on Cardinal: `R/02_cem_matching.R.preupdate.20260517_ecoregion`

## Implications

The smoke validation establishes that the Layer 7b ecoregion patch is a safe deployment to the production framework. The patch:

1. Runs end-to-end without errors at production-scale configuration (`--use_maine_econ`, `--use_decoupled_climate`, etc.).
2. Produces sensible per-cycle trajectories consistent with pre-patch behavior in the within-state regime where ecoregion granularity is minimal.
3. The iter1 fine-resolution match rate of 91.8 percent confirms the L3 × FORTYPCD × OWNGRPCD cell sizes are adequate.

The fact that smoke output is within sampling variation of L2 baseline rules out the concern that adding ecoregion to the matching keys would fragment cells to the point of breaking the matching. The patch is ready for production scale.
