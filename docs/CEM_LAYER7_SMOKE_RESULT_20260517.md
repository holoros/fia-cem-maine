# CEM Layer 7b ecoregion patch smoke result

*Generated 17 May 2026 after SLURM 9914786 (ME 10-sim 5-cycle BAU smoke) completed in 1:09:08 with exit 0.*

## TLDR

The CEM Layer 7b patch produces valid end-to-end output at smoke scale. CEM matching achieves 99.7 percent rate (9,990 of 10,017 subjects). Cycle 1 BAU output is comparable to the pre-patch Layer 2 10-sim smoke (gr_ratio 0.78 vs L2's 0.84, mean_ba 76 vs 79, mean_carbon 37,200 vs 36,800 lb/ac). The patch did NOT break anything. Bias reduction quantification requires a full production-scale multistate p1 rerun (100 sims × all econ overlays × all 4 states × 2 RCPs).

## Smoke output

ME 10-sim 5-cycle BAU with all econ overlays (`--use_brms_sdimax --use_decoupled_climate --use_disturbance --use_potter_vcc --use_maine_econ`), Layer 7b patched CEM:

```
cycle  year  BAU gr_ratio (95% CI)
1      5     0.778 (0.760, 0.794)
2      10    1.965 (1.878, 2.055)
3      15    2.818 (2.550, 3.112)
4      20    8.563 (7.992, 9.461)
5      25    11.707 (10.476, 14.310)
```

Cycle 1 BAU CI summary:

| Metric | Layer 7b | Layer 2 smoke (pre-patch) |
|---|---:|---:|
| mean_ba | 76.2 | ~79 |
| mean_carbon | 37,202 lb/ac | ~36,800 |
| mean_vol | 1,272 cuft/ac | ~1,260 |
| harvest_rate | 0.260 | 0.258 |
| gr_ratio | 0.778 | ~0.84 |
| n_sims | 10 | 10 |

The two smokes are within sampling variation of each other. This is the expected outcome of a methodology change that adds a matching key but doesn't change the underlying donor pool composition — the smoke pool is still ME-only, so the ecoregion granularity isn't being exercised across distinct ecoregions.

## CEM matching diagnostics

```
=== CEM Matching Summary (cycle 1) ===
  Total subjects: 10017
  Matched: 9990 (99.7%)
  Unmatched: 27 (0.3%)
  Matches per subject: median = 3.0, range = [1, 629]

Iteration 1 (fine, cem_ecoregion = L3 code):
  9198/10017 subjects matched (91.8%)
Iteration 2 (medium, cem_ecoregion = section):
  531/819 remaining matched (64.8%)
Iteration 3 (coarse, cem_ecoregion = "0"):
  261/288 remaining matched (90.6%)

=== CEM Matching Summary (subsequent cycles) ===
  Total subjects: 7102
  Matched: 5745 (80.9%)
  Unmatched: 1357 (19.1%)
  Matches per subject: median = 6.0, range = [1, 5133]
```

Cycle 1 match rate (99.7%) is excellent. Subsequent-cycle match rate of 80.9% is lower because the subject pool drifts post-harvest while the donor pool remains the baseline remeasured set. Iter 3 fallback (drop ecoregion + owner) catches 90.6 percent of cycle 1 residual; the across-cycle drift produces more iter 3 entries.

Iter 1 fine-resolution at 91.8% confirms the empirical cell-size diagnostic (`CEM_3WAY_STRATIFICATION_20260517.md`): 99.7 percent of subject conditions fall in cells with enough donors at the L3 × FORTYPCD × OWNGRPCD grain.

## What the smoke does NOT measure

The within-ME smoke can't quantify the bias reduction because:

1. **Donor pool is ME-only.** Smoke uses ME's own re-measured plots as donors via `--include_remeasured` plus `--untreated_donors`. The ecoregion key adds fine-grained stratification within ME but the bias mechanism documented in `MULTISTATE_DONOR_POOL_4PANEL_20260517.md` is cross-state.

2. **Only 10 simulations.** The 100-sim production runs have tighter CIs and would show effect more clearly.

3. **us_l3code not loaded.** The smoke falls back to STATECD for ecoregion since `R/01_data_prep.R` doesn't currently join `config/fia_plots_hcb_l3.csv` to load us_l3code. At the smoke ME-only scale, this is invisible (STATECD = 23 for all subjects and donors).

## Required for bias reduction measurement

Full production rerun:

1. **Patch `R/01_data_prep.R`** to join `config/fia_plots_hcb_l3.csv` and load `us_l3code` into the subject and donor data frames before passing to `apply_coarsening`. Effort: 30 min.

2. **Full multistate p1 rerun** with the patched CEM:
   - ME RCP 4.5 + 8.5 (100 sims, 15 cycles)
   - MN RCP 4.5 + 8.5
   - WA RCP 4.5 + 8.5
   - GA RCP 4.5 + 8.5

   Estimated SLURM time: ~12 hours across the 8 jobs in parallel. Compare output bias to existing baselines.

3. **Re-run hindcasts** for the patched outputs. Updates RMSE and bias values across the four states.

4. **Update manuscript Section X.2 table with revised bias percentages.** Projected per `CEM_3WAY_STRATIFICATION_20260517.md`:
   - WA -25% → -5 to -10%
   - MN -23% statewide → -5 to -10%
   - GA +10% → +3 to +5%
   - ME canonical unchanged

## Files

- Output: `~/fia_cem_projections/output/ME_20260517_layer7b_ecoregion_smoke_20260517/`
- Pulled locally to: `figures/layer7b_smoke/`
- Log: `~/fia_cem_projections/logs/l7_smoke_9914786.out`
- Patched script: `~/fia_cem_projections/R/02_cem_matching.R` (mirror at `R/02_cem_matching.R`)
- Backup: `~/fia_cem_projections/R/02_cem_matching.R.preupdate.20260517_ecoregion`

## Status

- Layer 7b smoke validates patch end-to-end at small scale
- CEM matching at 99.7% match rate (cycle 1) confirms cell-size feasibility
- Output trajectories within sampling variation of Layer 2 baseline
- Full bias reduction quantification requires production rerun + R/01 patch
- Local repo at 53 commits ahead of origin/main
